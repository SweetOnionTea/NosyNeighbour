import sys
import time
import signal
from threading import Thread

from config import LOG_FILE
from logging_utils import log_and_print, shutdown_event
from select_microphone import list_mics_and_select
from audio_capture import audio_capture_worker, cleanup_temp_files
from whisper_transcribe import initialize_whisper_model, transcription_worker, _drain_accumulated_text
from ollama_worker import ollama_worker, ollama_queue
from ollama_ai_chat import OllamaAIChat
from queue import Queue

# Hold a reference to OllamaAIChat here so _handle_graceful_shutdown can see it
ai_chat_global = None

def _handle_graceful_shutdown(signum, frame):
    log_and_print("\nTermination signal received.")

    # 1) Drain leftover transcription so it goes into the ollama_queue
    _drain_accumulated_text()

    # 2) Wait for the Ollama worker to finish processing everything in ollama_queue
    log_and_print("Waiting for Ollama worker to finish any newly queued items...")
    ollama_queue.join()  # Blocks until all items have been processed

    # 3) Attempt re-processing offline blocks if needed, after checking if Ollama is online
    if ai_chat_global is not None:
        try:
            ai_chat_global._try_offline_queue()
            log_and_print("Offline queue reprocessing attempt completed.")
        except Exception as e:
            log_and_print(f"Error while trying final offline queue reprocessing: {e}")

    # 4) Signal the shutdown event so worker threads can stop
    shutdown_event.set()

    # 5) Cleanup temp files, etc.
    cleanup_temp_files()

    # 6) Exit the program gracefully
    sys.exit(0)

def main():
    # 1) Setup signal handlers
    signal.signal(signal.SIGINT, _handle_graceful_shutdown)
    signal.signal(signal.SIGTERM, _handle_graceful_shutdown)

    # 2) Initialize Whisper model (if it fails, exit program)
    try:
        initialize_whisper_model()
    except Exception as e:
        log_and_print(f"Critical error: Failed to initialize Whisper model: {e}")
        shutdown_event.set()
        sys.exit(1)

    # 3) Initialize OllamaAIChat (if it fails, exit program)
    global ai_chat_global
    try:
        ai_chat_global = OllamaAIChat()
    except Exception as e:
        log_and_print(f"Critical error: Failed to initialize OllamaAIChat: {e}")
        shutdown_event.set()
        sys.exit(1)

    list_mics_and_select()  # let the user pick the mic
   
    # 4) Create the main audio queue
    audio_queue = Queue()

    # 5) Start audio capture worker
    audio_thread = Thread(target=audio_capture_worker, args=(audio_queue,), daemon=True)
    audio_thread.start()
    log_and_print("Audio capture worker started.")

    # 6) Start transcription worker
    transcription_thread = Thread(target=transcription_worker, args=(audio_queue,), daemon=True)
    transcription_thread.start()
    log_and_print("Transcription worker started.")

    # 7) Start Ollama worker
    ollama_thread = Thread(target=ollama_worker, args=(ai_chat_global,), daemon=True)
    ollama_thread.start()
    log_and_print("Ollama worker started.")

    # Main loop
    try:
        while not shutdown_event.is_set():
            time.sleep(1)
    except Exception as e:
        log_and_print(f"Unexpected error in main loop: {e}")
        shutdown_event.set()
        sys.exit(1)

if __name__ == "__main__":
    main()
