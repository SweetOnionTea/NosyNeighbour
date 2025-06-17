import os
import re
from queue import Empty
from audio_capture import temp_audio_files
from config import (
    NO_SPEECH_PROB_CUTOFF,
    MAX_CONSECUTIVE_SPEECH_CHUNKS,
    WHISPER_MODEL,
    WHISPER_BACKEND,
    WHISPER_DEVICE,
    WHISPER_COMPUTE_TYPE,
    WHISPER_TASK
)
from logging_utils import log_and_print, shutdown_event, text_lock
from ollama_worker import ollama_queue

import whisper_s2t

incoming_text = ""
consecutive_speech_chunks = 0
last_transcription = ""
whisper_model = None

def initialize_whisper_model():
    global whisper_model
    try:
        whisper_model = whisper_s2t.load_model(
            model_identifier=WHISPER_MODEL,
            backend=WHISPER_BACKEND,
            device=WHISPER_DEVICE,
            compute_type=WHISPER_COMPUTE_TYPE
        )
        log_and_print("Whisper model loaded successfully.")
    except Exception as e:
        log_and_print(f"Error loading Whisper model: {e}")
        raise e

def _transcribe_audio_chunk(audio_file):
    """Transcribe the audio in the given file using WhisperS2T, returning (transcription, min_no_speech_prob)."""
    global whisper_model
    try:
        files=[audio_file]
        lang_codes=['en']
        tasks=[WHISPER_TASK]
        initial_prompts=[None]
        batch_size=16
        out = whisper_model.transcribe_with_vad(
            files,
            lang_codes=lang_codes,
            tasks=tasks,
            initial_prompts=initial_prompts,
            batch_size=batch_size
        )
        if os.path.exists(audio_file):
            os.remove(audio_file)
        if audio_file in temp_audio_files:
            temp_audio_files.remove(audio_file)

        utterances = out[0]
        # We'll use the min no_speech_prob from each utterance
        min_no_speech_prob = min(utt['no_speech_prob'] for utt in utterances if 'no_speech_prob' in utt) if utterances else 1.0
        transcription = " ".join(utt['text'] for utt in utterances)
        return transcription, min_no_speech_prob
    except Exception as e:
        log_and_print(f"Error transcribing audio: {e}")
        return None, None

def transcription_worker(audio_queue):
    """
    Worker that continuously pulls audio file paths from audio_queue,
    transcribes them, and accumulates text if valid speech is detected.
    If max consecutive speech or silence is encountered, it enqueues to ollama_queue.
    """
    global incoming_text, consecutive_speech_chunks, last_transcription

    while not shutdown_event.is_set():
        try:
            audio_file = audio_queue.get(timeout=1)
        except Empty:
            continue
        if audio_file is None:
            continue

        transcription, min_no_speech_prob = _transcribe_audio_chunk(audio_file)
        if transcription is None:
            log_and_print("No transcription obtained; skipping this chunk.")
            audio_queue.task_done()
            continue

        char_count = len(transcription)
        log_and_print(f"Transcription chunk character count: {char_count}, min prob:{min_no_speech_prob:.3f}")

        if transcription and re.search(r"[^\s]", transcription):
            if min_no_speech_prob < NO_SPEECH_PROB_CUTOFF:
                if transcription == last_transcription:
                    log_and_print("Transcription is identical to the last one; skipping accumulation.")
                else:
                    with text_lock:
                        incoming_text += " " + transcription
                    last_transcription = transcription
                    consecutive_speech_chunks += 1
                    log_and_print(f"Accumulated transcription length: {len(incoming_text)}; consecutive: {consecutive_speech_chunks}")

                if consecutive_speech_chunks >= MAX_CONSECUTIVE_SPEECH_CHUNKS:
                    log_and_print("Maximum consecutive speech chunks reached; enqueuing accumulated transcription to Ollama queue.")
                    ollama_queue.put(incoming_text)
                    with text_lock:
                        incoming_text = ""
                    consecutive_speech_chunks = 0
            else:
                log_and_print(f"no_speech_prob = {min_no_speech_prob:.3f} indicates silence or unclear audio.")
                if incoming_text:
                    ollama_queue.put(incoming_text)
                    with text_lock:
                        incoming_text = ""
                consecutive_speech_chunks = 0
        else:
            log_and_print("Transcription chunk contains only whitespace; skipping.")

        audio_queue.task_done()

def _drain_accumulated_text():
    """
    Called during graceful shutdown to enqueue leftover 'incoming_text' to Ollama queue
    so that no transcription is lost before the program exits.
    """
    global incoming_text
    if incoming_text.strip():
        log_and_print("[Transcription Worker] Draining leftover text to Ollama queue before shutdown.")
        ollama_queue.put(incoming_text)
        incoming_text = ""