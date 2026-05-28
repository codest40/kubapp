from fastapi import APIRouter
from fastapi.responses import HTMLResponse, JSONResponse
import logger
import metrics

import time
import random
import uuid

router = APIRouter()

# -----------------------------
# UI (NO JINJA - PURE HTML)
# -----------------------------
@router.get("/", response_class=HTMLResponse)
def home():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Kubapp Observability</title>
        <script src="https://unpkg.com/htmx.org@1.9.10"></script>
    </head>

    <body>
        <h1>Kubapp Observability Dashboard</h1>

        <h2>System Status</h2>
        <button hx-get="/ui/status" hx-target="#status">
            Refresh Status
        </button>

        <div id="status">Click to load status</div>

        <hr>

        <h2>Load Test</h2>

        <form hx-get="/simulate" hx-target="#result">
            Load:
            <input type="number" name="load" value="10"><br><br>

            Error Rate:
            <input type="text" name="error_rate" value="0.2"><br><br>

            Delay:
            <input type="text" name="delay" value="0.1"><br><br>

            <button type="submit">Run Simulation</button>
        </form>

        <div id="result"></div>

        <hr>

        <h2>Endpoints</h2>
        <ul>
            <li>/metrics</li>
            <li>/health</li>
            <li>/live</li>
            <li>/ready</li>
        </ul>
    </body>
    </html>
    """


# -----------------------------
# UI FRAGMENT ENDPOINT
# -----------------------------
@router.get("/ui/status", response_class=HTMLResponse)
def status():
    return """
    <ul>
        <li>App: OK</li>
        <li>Metrics: Active</li>
        <li>Logs: Streaming</li>
    </ul>
    """


# -----------------------------
# CORE ENDPOINTS
# -----------------------------
@router.get("/health")
def health():
    return {"status": "ok"}


@router.get("/live")
def live():
    return {"status": "alive"}


@router.get("/ready")
def ready():
    return {"status": "ready"}

@router.get("/favicon.ico")
def fav():
    return {"status": "ok"}

# -----------------------------
# SIMULATION (HTML OUTPUT)
# -----------------------------
@router.get("/simulate")
def simulate(load: int = 10, error_rate: float = 0.2, delay: float = 0.1):
    endpoint = "/simulate"
    metrics.ACTIVE.inc()
    start = time.time()

    request_id = str(uuid.uuid4())

    try:
        for i in range(load):
            time.sleep(delay)

            is_error = random.random() < error_rate

            data = {
                "request_id": request_id,
                "iteration": i,
                "error": is_error
            }

            # -------------------------
            # STDOUT (FLUENT BIT)
            # -------------------------
            if is_error:
                logger.stdout_logger.error("error event", extra={"extra_data": data})
            else:
                logger.stdout_logger.info("processed event", extra={"extra_data": data})

            # -------------------------
            # FILE LOG (/data mount)
            # -------------------------
            logger.file_logger.info("file log event", extra={"extra_data": data})

        return {"status": "done", "load": load}

    finally:
        duration = time.time() - start
        metrics.REQUESTS.labels(endpoint=endpoint).inc()
        metrics.LATENCY.labels(endpoint=endpoint).observe(duration)
        metrics.ACTIVE.dec()
