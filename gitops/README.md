# =========================================================
# KubApp — GitOps Layer (ArgoCD + Helm + ApplicationSets)
# =========================================================

# ------------------------------------------------------------
# OVERVIEW
# ------------------------------------------------------------
# This directory contains the GitOps control plane for KubApp,
# powered by ArgoCD, Helm, and a registry-driven service model.

# It defines how applications, infrastructure components, and
# ingress resources are deployed and reconciled automatically
# from Git.

# Core idea:
#
# Git defines desired state → ArgoCD enforces runtime state


# ------------------------------------------------------------
# ARCHITECTURE OVERVIEW
# ------------------------------------------------------------

# The GitOps system is structured into 4 main layers:

# registry/  → Source of truth (services metadata)
#     ↓
# envs/      → Environment-specific overrides
#     ↓
# charts/    → Reusable Helm templates
#     ↓
# argocd/    → ArgoCD Applications & ApplicationSets
#     ↓
# cluster    → Kubernetes runtime


# ------------------------------------------------------------
# 1. REGISTRY LAYER
# ------------------------------------------------------------
# Path: gitops/registry/

# This is the service catalog for all workloads.

# Each JSON entry defines:

# - service name
# - compute type (EC2 / Fargate / Backend)
# - container image + tag
# - ports
# - monitoring flags
# - volume usage
# - secret/variable requirements

# Example:

# {
#   "service": "weather",
#   "type": "App",
#   "computeType": "fargate",
#   "image": "paragon40/weather_app",
#   "tag": "latest",
#   "port": 8080,
#   "svc_monitor_enabled": true
# }

# Purpose:
#
# Acts as the authoritative service catalog consumed by CI/CD
# pipelines and GitOps generators.


# ------------------------------------------------------------
# 2. ENVIRONMENT LAYER
# ------------------------------------------------------------
# Path: gitops/envs/

# Defines runtime configuration per service per environment.

# Structure:

# envs/dev/apps/<service>/values.yaml

# Contains:

# - replica count
# - image overrides
# - service configuration
# - probes (readiness/liveness)
# - HPA rules
# - IAM service accounts
# - storage configuration
# - compute placement (EC2 / Fargate)

# Example:

# appName: weather
# namespace: dev
# replicaCount: 2
# image:
#   repository: paragon40/weather_app
#   tag: latest


# ------------------------------------------------------------
# 3. HELM CHARTS LAYER
# ------------------------------------------------------------
# Path: gitops/charts/

# Reusable Kubernetes templates.

# Components:

# apps/
# - Deployments
# - Services
# - HPA
# - ServiceAccounts
# - ServiceMonitors
# - Probes
# - Volumes

# ingress/
# - AWS ALB ingress controller
# - path-based routing
# - subdomain routing
# - SSL termination

# postgres/
# - Stateful PostgreSQL deployment
# - PVC-backed storage
# - Secrets management
# - ClusterIP service


# ------------------------------------------------------------
# 4. ARGOCD LAYER
# ------------------------------------------------------------
# Path: gitops/argocd/

# Defines GitOps reconciliation logic.

# ------------------------------------------------------------
# ApplicationSet: Apps
# File: appset.yaml

# Dynamically discovers:
# gitops/envs/dev/apps/*

# Generates:
# - one ArgoCD Application per service
# - uses Helm chart: charts/apps

# ------------------------------------------------------------
# ApplicationSet: Ingress
# File: ingress.yaml

# Manages:
# - dev ingress
# - monitoring ingress (Grafana, Prometheus, Alertmanager)
# - ArgoCD ingress

# ------------------------------------------------------------
# Root App
# File: root-app.yml

# Bootstraps the entire GitOps system


# ------------------------------------------------------------
# 5. SECRETS MANAGEMENT
# ------------------------------------------------------------
# Path: gitops/secrets/

# - SOPS-encrypted secrets (age-based encryption)
# - GitHub App credentials for ArgoCD
# - Grafana admin secrets

# Security rule:
#
# All secrets are encrypted at rest using SOPS


# ------------------------------------------------------------
# 6. INGRESS STRATEGY (AWS ALB)
# ------------------------------------------------------------

# Ingress is managed via AWS ALB.

# Features:

# - path-based routing (/weather, /admin)
# - subdomain routing (weather.domain.com)
# - multi-stack routing (dev, monitoring, argocd)
# - shared ALB grouping via annotations

# Example:

# alb.ingress.kubernetes.io/group.name: kubapp-shared


# ------------------------------------------------------------
# 7. OBSERVABILITY INTEGRATION
# ------------------------------------------------------------

# Integrated observability stack:

# - Prometheus (metrics collection)
# - Grafana (dashboards)
# - Alertmanager (alert routing)

# Enabled per service:

# serviceMonitor:
#   enabled: true


# ------------------------------------------------------------
# 8. DEPLOYMENT FLOW
# ------------------------------------------------------------

# 1. Code Push / Registry Update
#    CI updates registry/*.json

# 2. Manifest Generation
#    Pipeline updates:
#    envs/dev/apps/<service>/values.yaml

# 3. ArgoCD Sync
#    ApplicationSet detects changes
#    Helm renders Kubernetes manifests

# 4. Cluster Reconciliation
#    Kubernetes applies updates automatically


# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------

# The KubApp GitOps layer functions as a declarative
# deployment engine built on:

# - Registry-driven service definitions
# - Environment-specific overrides
# - Helm-based templating
# - ArgoCD continuous reconciliation

# Core principle:
# Git is the single source of truth for the entire runtime
