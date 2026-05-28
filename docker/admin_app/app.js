const express = require("express");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const promClient = require("prom-client");

const app = express();
const PORT = process.env.PORT || 4000;
const SERVICE = "admin";

//
// ----------------------------------------------------
// Logging
// ----------------------------------------------------
//

const DATA_DIR = "/data";
const LOG_FILE = path.join(DATA_DIR, "app.log");

// Create /data if possible (works with mounted volume)
try {
  fs.mkdirSync(DATA_DIR, { recursive: true });
} catch (err) {
  // ignore if read-only
}

function writeFileLog(line) {
  try {
    fs.appendFileSync(LOG_FILE, line + "\n");
  } catch (err) {
    // Ignore if volume not writable
  }
}

function log(level, message, extra = {}) {
  const entry = {
    timestamp: new Date().toISOString(),
    level,
    service: SERVICE,
    message,
    ...extra
  };

  const line = JSON.stringify(entry);

  // stdout -> Kubernetes -> Fluent Bit
  console.log(line);

  // /data/app.log -> volume
  writeFileLog(line);
}

//
// ----------------------------------------------------
// Prometheus Metrics
// ----------------------------------------------------
//

const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const requestCounter = new promClient.Counter({
  name: "app_requests_total",
  help: "Total requests",
  labelNames: ["endpoint"],
  registers: [register]
});

const errorCounter = new promClient.Counter({
  name: "app_errors_total",
  help: "Total errors",
  labelNames: ["endpoint"],
  registers: [register]
});

const latencyHistogram = new promClient.Histogram({
  name: "app_latency_seconds",
  help: "Request latency",
  labelNames: ["endpoint"],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5],
  registers: [register]
});

//
// ----------------------------------------------------
// Middleware
// ----------------------------------------------------
//

app.use((req, res, next) => {
  const start = Date.now();
  const endpoint = req.path;
  const requestId = crypto.randomUUID();

  req.requestId = requestId;

  log("INFO", "request_started", {
    request_id: requestId,
    method: req.method,
    path: req.originalUrl
  });

  res.on("finish", () => {
    const duration = (Date.now() - start) / 1000;

    requestCounter.labels(endpoint).inc();
    latencyHistogram.labels(endpoint).observe(duration);

    if (res.statusCode >= 500) {
      errorCounter.labels(endpoint).inc();
    }

    log("INFO", "request_finished", {
      request_id: requestId,
      method: req.method,
      path: req.originalUrl,
      status_code: res.statusCode,
      duration_seconds: duration
    });
  });

  next();
});

//
// ----------------------------------------------------
// Web UI
// ----------------------------------------------------
//

const html = `
<!DOCTYPE html>
<html>
<head>
  <title>Admin Observability Dashboard</title>
  <style>
    body {
      font-family: Arial;
      margin: 40px;
      background: #f8fafc;
    }
    .card {
      background: white;
      padding: 24px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
      max-width: 900px;
    }
    button {
      padding: 10px 16px;
      margin-right: 8px;
      cursor: pointer;
    }
    input {
      padding: 8px;
      margin-right: 8px;
      width: 80px;
    }
    code {
      background: #eee;
      padding: 2px 4px;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>🔐 Admin Observability Dashboard</h1>
    <p>Status: OK</p>

    <h2>Generate Logs</h2>
    <form action="/simulate" method="get">
      Load:
      <input type="number" name="load" value="20">
      Error Rate:
      <input type="text" name="error_rate" value="0.2">
      Delay:
      <input type="text" name="delay" value="0.05">
      <button type="submit">Run Simulation</button>
    </form>

    <h2>Useful Endpoints</h2>
    <ul>
      <li><a href="/metrics">/metrics</a></li>
      <li><a href="/health">/health</a></li>
      <li><a href="/live">/live</a></li>
      <li><a href="/ready">/ready</a></li>
      <li><a href="/admin">/admin</a></li>
    </ul>
  </div>
</body>
</html>
`;

app.get("/", (req, res) => res.send(html));
app.get("/admin", (req, res) => res.send(html));

//
// ----------------------------------------------------
// Health Endpoints
// ----------------------------------------------------
//

app.get("/health", (req, res) => {
  res.json({ status: "healthy", service: SERVICE, port: PORT });
});

app.get("/live", (req, res) => {
  res.json({ status: "alive", service: SERVICE, port: PORT });
});

app.get("/ready", (req, res) => {
  res.json({ status: "ready", service: SERVICE, port: PORT });
});

//
// ----------------------------------------------------
// Metrics Endpoint
// ----------------------------------------------------
//

app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

//
// ----------------------------------------------------
// Load Simulation
// ----------------------------------------------------
//

app.get("/simulate", async (req, res) => {
  const load = parseInt(req.query.load || "10", 10);
  const errorRate = parseFloat(req.query.error_rate || "0.2");
  const delay = parseFloat(req.query.delay || "0.1");

  const requestId = crypto.randomUUID();
  let errors = 0;

  for (let i = 0; i < load; i++) {
    const isError = Math.random() < errorRate;

    const payload = {
      request_id: requestId,
      iteration: i,
      error: isError
    };

    if (isError) {
      errors++;
      log("ERROR", "simulated_error", payload);
      errorCounter.labels("/simulate").inc();
    } else {
      log("INFO", "simulated_request", payload);
    }

    if (delay > 0) {
      await new Promise(resolve => setTimeout(resolve, delay * 1000));
    }
  }

  res.json({
    status: "completed",
    load,
    errors
  });
});

//
// ----------------------------------------------------
// Background Worker
// ----------------------------------------------------
//

setInterval(() => {
  log("INFO", "background_job", {
    task: "sync",
    status: ["ok", "retry", "fail"][
      Math.floor(Math.random() * 3)
    ]
  });
}, 5000);

//
// ----------------------------------------------------
// Startup
// ----------------------------------------------------
//

app.listen(PORT, "0.0.0.0", () => {
  log("INFO", "server_started", {
    port: PORT,
    service: SERVICE
  });
});
