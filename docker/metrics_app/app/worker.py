import threading
import time
import random
import logger

def run():
    while True:
        time.sleep(random.randint(2, 5))

        logger.stdout_logger.info(
            "background task",
            extra={"extra_data": {"status": "ok"}}
        )

        logger.file_logger.info(
            "background task",
            extra={"extra_data": {"status": "ok"}}
        )

def start():
    t = threading.Thread(target=run, daemon=True)
    t.start()
