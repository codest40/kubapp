#!/bin/bash
set -euo pipefail

BASE_DIR="$(pwd)"

echo "🚀 Bootstrapping GitOps Observability structure in: $BASE_DIR/sys_monitor"

cd "$BASE_DIR/sys_monitor"

# ---------------------------
# CORE DIRECTORIES
# ---------------------------
mkdir -p base/prometheus
mkdir -p base/grafana
mkdir -p base/loki
mkdir -p base/tempo
mkdir -p base/otel-collector

mkdir -p exporters/argocd-metrics
mkdir -p exporters/github-webhook-collector
mkdir -p exporters/terraform-exporter
mkdir -p exporters/cluster-state-exporter

mkdir -p dashboards
mkdir -p alerts
mkdir -p rules
mkdir -p values

# ---------------------------
# BASE PLACEHOLDERS
# ---------------------------

cat > base/prometheus/prometheus.yaml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "argocd"
    static_configs:
      - targets: ["argocd-server.argocd.svc.cluster.local:8082"]
EOF

cat > base/grafana/datasources.yaml <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
EOF

cat > base/loki/loki.yaml <<EOF
auth_enabled: false
server:
  http_listen_port: 3100
EOF

cat > base/tempo/tempo.yaml <<EOF
server:
  http_listen_port: 3200
EOF

cat > base/otel-collector/otel-collector.yaml <<EOF
receivers:
  otlp:
    protocols:
      grpc:
      http:

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"

service:
  pipelines:
    metrics:
      receivers: [otlp]
      exporters: [prometheus]
EOF

# ---------------------------
# EXPORTERS (stubs)
# ---------------------------

cat > exporters/argocd-metrics/README.md <<EOF
ArgoCD metrics exporter placeholder.
Connect to /metrics endpoint and expose to Prometheus.
EOF

cat > exporters/github-webhook-collector/README.md <<EOF
GitHub webhook collector.
Receives events: push, PR, merge.
Converts to observability events.
EOF

cat > exporters/terraform-exporter/README.md <<EOF
Terraform state/export metrics collector.
Tracks apply success, drift, failures.
EOF

cat > exporters/cluster-state-exporter/README.md <<EOF
Kubernetes state observer.
Detects drift + resource health signals.
EOF

# ---------------------------
# DASHBOARDS
# ---------------------------

cat > dashboards/gitops-overview.json <<EOF
{}
EOF

cat > dashboards/deployment-health.json <<EOF
{}
EOF

cat > dashboards/drift-detection.json <<EOF
{}
EOF

cat > dashboards/pipeline-performance.json <<EOF
{}
EOF

# ---------------------------
# ALERTS
# ---------------------------

cat > alerts/argocd-alerts.yaml <<EOF
groups:
  - name: argocd-alerts
    rules:
      - alert: ArgoCDOutOfSync
        expr: argocd_app_sync_status != 1
        for: 5m
EOF

cat > alerts/deployment-failure.yaml <<EOF
groups:
  - name: deployment-failures
    rules:
      - alert: DeploymentFailureSpike
        expr: rate(argocd_app_sync_total{status="Failed"}[5m]) > 0.2
EOF

cat > alerts/drift-alerts.yaml <<EOF
groups:
  - name: drift-alerts
    rules:
      - alert: ClusterDriftDetected
        expr: cluster_drift_total > 0
EOF

# ---------------------------
# RULES
# ---------------------------

cat > rules/prometheus-rules.yaml <<EOF
groups:
  - name: recording-rules
    rules:
      - record: gitops:deployment_success_rate
        expr: sum(rate(argocd_app_sync_total{status="Synced"}[5m]))
EOF

cat > rules/recording-rules.yaml <<EOF
groups:
  - name: gitops-recordings
    rules:
      - record: gitops:sync_latency
        expr: histogram_quantile(0.95, rate(argocd_app_reconcile_duration_seconds_bucket[5m]))
EOF

# ---------------------------
# VALUES (Helm placeholders)
# ---------------------------

cat > values/prometheus-values.yaml <<EOF
server:
  retention: 15d
EOF

cat > values/grafana-values.yaml <<EOF
adminPassword: admin
EOF

echo "✅ Observability structure created successfully!"
echo "👉 Next step: wire exporters + install Prometheus/Grafana via Helm or ArgoCD"
