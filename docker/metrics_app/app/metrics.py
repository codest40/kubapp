from prometheus_client import Counter, Histogram, Gauge

REQUESTS = Counter("app_requests_total", "Total requests", ["endpoint"])
ERRORS = Counter("app_errors_total", "Total errors", ["endpoint"])
LATENCY = Histogram("app_latency_seconds", "Latency", ["endpoint"])
ACTIVE = Gauge("app_active_requests", "Active requests")
