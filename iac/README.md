# KubApp — Infrastructure as Code (IaC Layer — Terraform)

# ------------------------------------------------------------
# OVERVIEW
# ------------------------------------------------------------
# This directory defines the complete AWS + Kubernetes
# infrastructure foundation for Kubapp using Terraform modules,
# multi-environment state management, and layered separation
# of concerns.

# The system is structured into four major domains:

# infra/       → Core AWS + EKS infrastructure
# k8s/         → Kubernetes platform bootstrap layer
# manifests/   → Kubernetes-native resource orchestration
# boot/        → Terraform backend initialization


# ------------------------------------------------------------
# DIRECTORY OVERVIEW
# ------------------------------------------------------------

# iac/
# ├── infra/        # AWS + EKS infrastructure modules
# ├── k8s/          # Kubernetes platform configuration layer
# ├── manifests/    # Kubernetes resources via Terraform
# ├── boot/         # Terraform backend bootstrap
# ├── README.md


# ------------------------------------------------------------
# ARCHITECTURE PHILOSOPHY
# ------------------------------------------------------------

# This IaC layer follows a 3-tier infrastructure model:

# 1. FOUNDATION LAYER (boot)
# 2. INFRASTRUCTURE LAYER (infra)
# 3. PLATFORM LAYER (k8s + manifests)


# ------------------------------------------------------------
# 1. FOUNDATION LAYER (boot/)
# ------------------------------------------------------------

# Purpose:
# Initializes Terraform remote state backend before any infra.

# Components:
# - S3 bucket → state storage
# - DynamoDB → state locking
# - provider configuration
# - Terraform version pinning

# Key files:

# boot/
# ├── s3.tf
# ├── dynamodb.tf
# ├── provider.tf
# ├── terraform.tfstate
# ├── terraform.tfvars


# Execution flow:

# terraform init
# terraform apply

# Guarantees:

# - Remote state storage enabled
# - State locking enabled
# - Multi-user safety
# - No local state dependency


# ------------------------------------------------------------
# 2. INFRASTRUCTURE LAYER (infra/)
# ------------------------------------------------------------

# Purpose:
# Core AWS + EKS provisioning layer.

# ------------------------------------------------------------
# MODULES OVERVIEW
# ------------------------------------------------------------

#  Network Module
# infra/modules/network
# - VPC
# - Subnets (public/private)
# - Route tables
# - Internet Gateway
# - NAT Gateway

# EKS Module
# infra/modules/eks
# - EKS cluster
# - Node groups:
#     - system nodes
#     - app nodes
# - Fargate profiles
# - Cluster access configuration

# IAM Core Module
# infra/modules/iam-core
# - cluster roles
# - node roles
# - admin roles

# IRSA Module
# infra/modules/iam-irsa
# Enables Kubernetes service accounts to assume AWS roles.

# Supports:
# - EBS CSI
# - EFS CSI
# - Load Balancer Controller
# - Fluent Bit
# - ExternalDNS
# - App-level AWS access

# Security Module
# infra/modules/security
# - security groups
# - network boundary control

#  Storage Modules
# infra/modules/efs
# Kubernetes persistent storage backend

# Logging Module
# infra/modules/logging
# CloudWatch integration + cluster logging

# ACM Module
# infra/modules/acm
# SSL certificate provisioning for ALB / HTTPS ingress


# ------------------------------------------------------------
# ENVIRONMENT SUPPORT
# ------------------------------------------------------------

# infra/envs/dev
# infra/envs/prod

# Each environment contains:

# - infra.tfvars
# - backend.hcl
# - optional encrypted secrets (.enc)

# Purpose:
#
# - environment isolation
# - independent state per environment
# - safe promotion from dev → prod


# ------------------------------------------------------------
# 3. PLATFORM LAYER (k8s/)
# ------------------------------------------------------------

# Purpose:
# Configures Kubernetes platform resources using Terraform.

# ------------------------------------------------------------
# RESPONSIBILITIES
# ------------------------------------------------------------

# 🔹 Namespaces
# k8s/namespaces.tf
# - dev
# - prod
# - monitoring
# - argocd

# 🔹 Service Accounts (IRSA bindings)
# k8s/sa.tf
# - cluster service accounts
# - AWS role attachments

# 🔹 Helm Releases
# k8s/helm.tf
# Installs core components:
# - ArgoCD
# - Prometheus stack
# - Ingress controller
# - Metrics server

# 🔹 Fargate Configuration
# k8s/fargate_log.tf
# - compute isolation rules
# - logging configuration

# 🔹 Storage Class
# k8s/storage_class.tf
# - persistent volume abstraction

# 🔹 Readiness Validation
# k8s/readiness.tf
# - cluster health validation hooks


# ------------------------------------------------------------
# 4. MANIFESTS LAYER (manifests/)
# ------------------------------------------------------------

# Purpose:
# Manages Kubernetes-native resources via Terraform.

# Structure:

# manifests/
# ├── alerts/
# ├── main.tf
# ├── variables.tf
# ├── outputs.tf


# ------------------------------------------------------------
# ALERTING SYSTEM
# ------------------------------------------------------------

# manifests/alerts/

# Includes:

# - application alerts
# - ingress alerts
# - infrastructure alerts
# - test alerts

# Integration points:

# - Prometheus
# - Alertmanager


# ------------------------------------------------------------
# STATE MANAGEMENT
# ------------------------------------------------------------

# All Terraform state is centralized via:

# boot/

# Backed by:

# - S3 → state storage
# - DynamoDB → locking
# - environment-isolated keys

# Ensures:

# - no local state drift
# - safe concurrency
# - multi-user collaboration


# ------------------------------------------------------------
# DEPLOYMENT FLOW
# ------------------------------------------------------------

# Developer change
#     ↓
# Terraform plan
#     ↓
# infra + k8s apply
#     ↓
# manifests apply
#     ↓
# ArgoCD sync
#     ↓
# Cluster state updated


# ------------------------------------------------------------
# KEY DESIGN PRINCIPLES
# ------------------------------------------------------------

# ✔ Separation of concerns
# infra      → AWS foundation
# k8s        → cluster platform
# manifests  → workloads + policies

# ✔ Multi-environment safety
# - dev / prod isolation
# - separate state files
# - controlled promotion path

# ✔ IRSA-first security model
# - no long-lived credentials in pods
# - IAM roles mapped to service accounts

# ✔ Hybrid compute support
# - EC2 node groups
# - Fargate profiles

# ✔ GitOps compatibility
# Terraform provisions platform
# ArgoCD manages workloads


# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------

# The KubApp IaC layer is a structured Terraform foundation
# that separates infrastructure, platform configuration, and
# Kubernetes runtime concerns into clear, independent layers.

# It ensures:

# - predictable infrastructure provisioning
# - secure multi-environment management
# - GitOps-ready cluster initialization
