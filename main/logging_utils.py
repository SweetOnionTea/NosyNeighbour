import time
from threading import Event, Lock
from config import LOG_FILE  # Now we import LOG_FILE from config.py

shutdown_event = Event()
text_lock = Lock()

def log_and_print(message):
    """
    Prints the message to the console and logs it to the log file.
    """
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    formatted_message = f"[{timestamp}] {message}"

    # Print to console
    print(formatted_message)

    # Log to file
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(formatted_message + "\n")