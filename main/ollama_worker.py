import time
from queue import Queue, Empty
from logging_utils import log_and_print, shutdown_event

ollama_queue = Queue()

def ollama_worker(ai_chat):
    """
    Worker thread that processes text blocks from ollama_queue using OllamaAIChat.
    If an error occurs for a block, store it offline so it's not lost.
    """
    block_id_gen = int(time.time())
    while not shutdown_event.is_set() or not ollama_queue.empty():
        try:
            text_block = ollama_queue.get(timeout=1)
            if text_block is None:
                continue

            log_and_print(
                f"[Ollama Worker] Processing block ID={block_id_gen}, length={len(text_block)}, text={text_block}"
            )
            
            # Attempt to process the block
            # If it fails, an exception is raised
            ai_chat.process_block(text_block, block_id_gen)

            # If we reach this line, processing succeeded
            ollama_queue.task_done()
            block_id_gen += 1

        except Empty:
            # No block available right now
            continue
        except Exception as e:
            # Something went wrong, store this block offline
            log_and_print(f"Error in Ollama worker for block {block_id_gen}: {e}")
            try:
                # We'll assume you have a method like _store_offline_block(...) in OllamaAIChat
                ai_chat._store_offline_block(block_id_gen, text_block)
                log_and_print(f"Block {block_id_gen} stored offline for later retry.")
            except Exception as store_err:
                log_and_print(f"Failed to store block {block_id_gen} offline: {store_err}")
            
            # Mark the queue item done so we don't re-try in an infinite loop
            ollama_queue.task_done()
            # Move on to the next block
            block_id_gen += 1
