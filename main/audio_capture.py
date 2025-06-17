import os
import tempfile
import sounddevice as sd
import soundfile as sf
from queue import Queue

from config import (
    TRANSCRIPTION_INTERVAL,
    SAMPLERATE,
    CHANNELS,
)
import config
from logging_utils import log_and_print, shutdown_event

temp_audio_files = []

def capture_audio_chunk(duration=TRANSCRIPTION_INTERVAL, samplerate=SAMPLERATE, channels=CHANNELS, device=None):
    """
    Capture audio from the microphone for a fixed duration.
    Returns the path to a temporary WAV file containing the recorded audio.
    """
    if device is None:
        device = config.MICROPHONE_INDEX  # Get the current value from config
        
    log_and_print(f"Recording audio chunk...")
    audio_data = sd.rec(
        int(duration * samplerate),
        samplerate=samplerate,
        channels=channels,
        device=device
    )
    sd.wait()

    tmp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
    tmp_filename = tmp_file.name
    tmp_file.close()

    sf.write(tmp_filename, audio_data, samplerate)
    temp_audio_files.append(tmp_filename)
    log_and_print(f"Audio chunk saved to {tmp_filename}")
    return tmp_filename

def audio_capture_worker(audio_queue: Queue):
    """
    Continuously record audio chunks and enqueue their file paths.
    Runs in its own thread until shutdown_event is set.
    """
    while not shutdown_event.is_set():
        audio_file = capture_audio_chunk()
        audio_queue.put(audio_file)

def cleanup_temp_files():
    """Delete all temporary audio files created during the session."""
    log_and_print("\nCleaning up temporary audio files before shutdown...")
    for file in temp_audio_files:
        try:
            if os.path.exists(file):
                os.remove(file)
                log_and_print(f"Deleted temp file: {file}")
            else:
                log_and_print(f"Temp file not found: {file}")
        except Exception as e:
            log_and_print(f"Error deleting temp file {file}: {e}")
    temp_audio_files.clear()
