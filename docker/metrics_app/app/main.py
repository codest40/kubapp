import sys
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE_DIR)

from fastapi import FastAPI
from prometheus_client import make_asgi_app

import routes
import worker

app = FastAPI(title="Kubapp Observability App")

app.include_router(routes.router)

# Prometheus metrics
app.mount("/metrics", make_asgi_app())

worker.start()
