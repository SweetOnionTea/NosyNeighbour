#~~~~~~~~~~~~~~~~~~~~Common Settings~~~~~~~~~~~~~~~~~~~~

# Whisper Model Settings
WHISPER_DEVICE = "cuda"        # Use "cuda" for GPU or "cpu" for CPU
WHISPER_TASK = 'transcribe'   # 'transcribe' or 'translate'

# Ollama Prompt Mode
# "default" => Summarize bullet points
# "restrictive" => Only organizes points into a JSON array without summarizing
OLLAMA_PROMPT_MODE = "default"  # "default" or "restrictive"

#~~~~~~~~~~~~~~~~~~~~Advanced Settings~~~~~~~~~~~~~~~~~~~~

# The microphone index can be updated by `select_microphone.py`
MICROPHONE_INDEX = None  # We set it to None initially

# Audio recording settings
TRANSCRIPTION_INTERVAL = 20   # Duration (in seconds) for each recorded audio chunk
SAMPLERATE = 16000            # Audio sampling rate (Hz)
CHANNELS = 1                  # Number of audio channels (1 = mono, 2 = stereo)

# Whisper Model Settings (Advanced)
WHISPER_MODEL = "small"        # Whisper model size ("tiny", "small", "medium", "large")
WHISPER_BACKEND = "CTranslate2"
WHISPER_COMPUTE_TYPE = "float32"

# Speech detection settings
NO_SPEECH_PROB_CUTOFF = 0.15   # If min_no_speech_prob < NO_SPEECH_PROB_CUTOFF, consider it valid speech (recommended 0.11-0.15)

# Maximum speech accumulation before forcing Ollama processing
MAX_CONSECUTIVE_SPEECH_CHUNKS = 22  # 7min 20sec (22 chunks * 20s each)

# Ollama Model Settings
OLLAMA_MODEL = "llama3.2"   # Define the Ollama model to use
OLLAMA_OPTIONS = {"temperature": 0.9, "top_p": 0.9}  # Ollama tuning options

import os

# Define directories
RUNTIME_DIR = "runtime_data"
FINAL_OUTPUTS_DIR = "final_outputs"

# Ensure directories exist. Create them if they don't
os.makedirs(RUNTIME_DIR, exist_ok=True)
os.makedirs(FINAL_OUTPUTS_DIR, exist_ok=True)

# Run time file paths
LOG_FILE = os.path.join(RUNTIME_DIR, "process_log.txt")
OFFLINE_QUEUE_FILE = os.path.join(RUNTIME_DIR, "ollama_offline_queue.txt")

# Final output file paths
EXCEL_FILE = os.path.join(FINAL_OUTPUTS_DIR, "Nosy_Neighbour_log.xlsx")
FALLBACK_TEXT_FILE = os.path.join(FINAL_OUTPUTS_DIR, "fallback_Nosy_Neighbour_log.txt")

# Random Color List for Excel Rows
EXCEL_COLOR_LIST = [
    "FFF2CC", "E2EFDA", "D9E2F3", "FCE4D6", "EDEDED", "D9D9D9", "DBE5F1", "F4CCCC", "F9CB9C", "CFE2F3",
    "FFF4C1", "D4E6A5", "DDEBF7", "FBE4F6", "FDE9D9", "E8F5E9", "FFF5BA", "D6EAF8", "F8D7DA", "EBF5FB",
    "FCF3CF", "E8DAEF", "EBDEF0", "F6DDCC", "FBEEE6", "FDEDEC", "EBF5E9", "FFF9C4", "E3F2FD", "FFF0F5",
    "FFF8DC", "FAE1DD", "F0F4C3", "D1C4E9", "FFECB3", "E3FCEC", "F5EEF8", "E8EAF6", "FDFEFE", "FCFCEB",
    "FFF7E1", "E9F7EF", "E1F5FE", "F4ECF7", "FDF5E6", "F0FFF0", "F5F5DC"
]


