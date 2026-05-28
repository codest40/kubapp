# KUBAPP — INFRASTRUCTURE LAYER (BASE TERRAFORM)

# ------------------------------------------------------------
# OVERVIEW
# ------------------------------------------------------------
# KubApp infrastructure is built on AWS using Terraform.
#
# It is designed as a production-style platform foundation
# for running Kubernetes workloads with:
#
# - clear separation of concerns
# - multi-environment support (dev, prod, etc.)
# - secure networking
# - workload identity (IRSA)
# - built-in observability
#
# The system follows a layered architecture:
#
# Network → Security → IAM → Compute (EKS) → Storage → Observability → Edge


# ------------------------------------------------------------
# HIGH-LEVEL ARCHITECTURE
# ------------------------------------------------------------
# The infrastructure is split into modular Terraform components:
#
# network   → VPC, subnets, routing, NAT
# security  → security groups for workloads
# iam-core  → base IAM roles for EKS
# iam-irsa  → workload-level AWS permissions (IRSA)
# eks       → Kubernetes cluster, nodes, fargate
# efs       → shared persistent storage
# ecr       → container registry (images)
# acm       → TLS certificates for HTTPS
# logging   → CloudWatch logs
#
# Each module is independent but connected through main.tf


# ------------------------------------------------------------
# DESIGN PRINCIPLES
# ------------------------------------------------------------

# 3.1 Modular Design
# Each infrastructure domain is isolated in its own module.
#
# This makes the system:
# - easier to maintain
# - easier to extend
# - safer to change


# 3.2 Multi-Environment Support
# Environments are separated using:
#
# envs/dev
# envs/prod
#
# Each environment has:
# - its own Terraform variables
# - its own backend state (S3)
#
# This prevents cross-environment risk.


# 3.3 Secure State Management
# Terraform state is stored in S3:
#
# - encrypted state
# - remote backend
# - environment-based keys
#
# This ensures:
# - state is not local
# - safe team collaboration
# - no accidental overwrites


# ------------------------------------------------------------
# CORE INFRASTRUCTURE LAYERS
# ------------------------------------------------------------

# ------------------------------------------------------------
# 4.1 NETWORK LAYER
# ------------------------------------------------------------
# The network module builds the base AWS VPC:
#
# VPC: 10.0.0.0/16
# Public subnets  → internet-facing resources
# Private subnets  → workloads (EKS, services)
# NAT Gateway      → controlled outbound internet
# Internet Gateway → public access
#
# Also includes:
# - Route tables
# - Subnet tagging for Kubernetes discovery
# - VPC Flow Logs → CloudWatch
#
# Purpose:
# Provides isolated and controlled network for the platform.


# ------------------------------------------------------------
# 4.2 SECURITY LAYER
# ------------------------------------------------------------
# Security groups are not manually defined per service.
#
# Instead:
# - sg-prep module defines workload rules
# - security module generates AWS security groups
#
# This allows:
# - reusable network rules
# - consistent port control
# - service-to-service communication rules
#
# Purpose:
# Controls all traffic between workloads in a structured way.


# ------------------------------------------------------------
# 4.3 IAM LAYER
# ------------------------------------------------------------

# iam-core
# - EKS cluster role
# - EC2 node group role
# - Fargate role
#
# Enables Kubernetes to run on AWS securely.


# iam-irsa (Workload Identity)
# Provides IAM roles for Kubernetes workloads using OIDC.
#
# Used by:
# - AWS Load Balancer Controller
# - ExternalDNS
# - EFS CSI driver
# - Fluent Bit logging
#
# Key idea:
# Pods get AWS permissions without storing AWS keys.


# ------------------------------------------------------------
# 4.4 COMPUTE LAYER (EKS)
# ------------------------------------------------------------
# Core runtime layer:
#
# - EKS managed Kubernetes cluster
# - EC2 node group (worker nodes)
# - Fargate profiles (serverless pods)
#
# Features:
# - private subnet deployment
# - API + config map authentication
# - cluster logging enabled
# - OIDC provider enabled for IRSA
#
# Purpose:
# Runs all container workloads in Kubernetes.


# ------------------------------------------------------------
# 4.5 STORAGE LAYER (EFS)
# ------------------------------------------------------------
# EFS provides shared storage for Kubernetes workloads.
#
# Features:
# - encrypted file system
# - mount targets in private subnets
# - access points per workload:
#   - user app
#   - admin app
#   - monitoring
#
# Purpose:
# Persistent shared storage for pods.


# ------------------------------------------------------------
# 4.6 ARTIFACT LAYER (ECR)
# ------------------------------------------------------------
# ECR stores container images:
#
# - user service
# - admin service
# - monitoring service
#
# Features:
# - image scanning on push
# - lifecycle policy (keep last 10 images)
#
# Purpose:
# Central container image registry.


# ------------------------------------------------------------
# 4.7 OBSERVABILITY LAYER
# ------------------------------------------------------------
# CloudWatch logging is centralized.
#
# Log groups:
# - application logs
# - audit logs
# - EKS cluster logs
# - VPC flow logs
#
# Purpose:
# Provides full visibility into system behavior.


# ------------------------------------------------------------
# 4.8 EDGE LAYER (ACM + DNS)
# ------------------------------------------------------------
# ACM handles TLS certificates.
# Route53 handles DNS validation.
#
# Supports:
# - root domain
# - wildcard certificates
#
# Purpose:
# Secure HTTPS and domain routing.


# ------------------------------------------------------------
# SECURITY MODEL
# ------------------------------------------------------------
# Security is built on:
#
# - private subnets for workloads
# - IRSA for AWS permissions
# - security groups for traffic control
# - encrypted state and storage
#
# No hardcoded credentials are used.


# ------------------------------------------------------------
# HOW EVERYTHING CONNECTS (FLOW)
# ------------------------------------------------------------
# Network creates VPC + subnets
#        ↓
# Security defines traffic rules
#        ↓
# IAM creates roles
#        ↓
# EKS cluster is created
#        ↓
# IRSA connects Kubernetes → AWS permissions
#        ↓
# EFS + ECR provide storage and images
#        ↓
# Logging + ACM complete observability + security


# ------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------
# the infrastructure is built for:
#
# - Kubernetes workloads
# - secure identity management
# - scalable networking
# - production-grade observability
# - GitOps integration readiness
#
