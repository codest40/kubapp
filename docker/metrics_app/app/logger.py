import logging
import json
import sys
import os
from datetime import datetime

# -----------------------
# JSON FORMATTER
# -----------------------
class JsonFormatter(logging.Formatter):
    def format(self, record):
        log = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "service": "metrics-app",
        }

        if hasattr(record, "extra_data"):
            log.update(record.extra_data)

        return json.dumps(log)


# -----------------------
# STDOUT LOGGER (FLUENT BIT)
# -----------------------
stdout_logger = logging.getLogger("stdout_logger")
stdout_logger.setLevel(logging.INFO)

stdout_handler = logging.StreamHandler(sys.stdout)
stdout_handler.setFormatter(JsonFormatter())

stdout_logger.addHandler(stdout_handler)


# -----------------------
# FILE LOGGER (/data volume)
# -----------------------
DATA_DIR = "/data"
LOG_FILE = os.path.join(DATA_DIR, "app.log")

os.makedirs(DATA_DIR, exist_ok=True)

file_logger = logging.getLogger("file_logger")
file_logger.setLevel(logging.INFO)

file_handler = logging.FileHandler(LOG_FILE)
file_handler.setFormatter(JsonFormatter())

file_logger.addHandler(file_handler)

