# Kubapp Scripts Documentation

## Overview

This directory contains operational scripts for managing the Kubapp platform across Kubernetes, ArgoCD, AWS infrastructure, and GitOps workflows.

The scripts are designed to support:

* GitOps-based deployments (ArgoCD)
* Kubernetes cluster lifecycle management
* AWS infrastructure provisioning and cleanup
* Security and secrets automation
* CI/CD operational workflows

---

## 1. Core Activation Pipeline

### `activate.sh`

Main orchestration entrypoint for environment activation.

**Responsibilities:**

* Runs validation (`validate.sh`)
* Encrypts secrets (`encrypt_secrets.sh`)
* Validates GitOps state (`validate_gitops.sh`)
* Commits and pushes changes to Git

**Flow:**

1. Validate environment
2. Encrypt secrets
3. Validate GitOps manifests
4. Git add/commit/push

---

## 2. GitOps & ArgoCD Operations

### `bootstrap_gitops.sh`

Bootstraps ArgoCD resources into the cluster.

**Responsibilities:**

* Applies ApplicationSet manifests
* Applies ArgoCD ingress
* Displays cluster and application state
* Performs dry-run preview before apply

### `argocd_login.sh`

Handles authentication and token generation for ArgoCD.

**Responsibilities:**

* Retrieves initial admin password from Kubernetes secret
* Logs into ArgoCD CLI
* Updates password for service account
* Generates access tokens

---

## 3. Kubernetes Cluster Management

### `clean_cluster.sh`

Hard reconciliation cleanup for Kubernetes resources.

**Responsibilities:**

* Deletes ArgoCD Applications and ApplicationSets
* Iterates through namespaces and removes resources
* Handles stuck finalizers
* Force deletes stuck resources when timeout is reached
* Deletes namespaces safely with fallback escalation

**Key safety features:**

* Skips system namespaces
* Timeout-based escalation
* Finalizer patching
* Forced deletion as last resort

---

### `check_cluster.sh`

Cluster readiness validation script.

**Checks:**

* ConfigMap `cluster-readiness`
* ArgoCD deployment rollouts

---

## 4. AWS Infrastructure Management

### `aws_cleanup.sh`

Granular AWS resource deletion tool.

**Supports:**

* EC2 instances
* Security Groups
* IAM roles and policies
* S3 buckets
* CloudWatch log groups
* ACM certificates
* Route53 hosted zones
* ECR repositories
* Load balancers and target groups
* Launch templates
* ENIs

**Behavior:**

* Interactive confirmation before deletion
* Safe checks before operations
* Graceful handling of missing resources

---

### `clean_final.sh`

Full AWS environment teardown script.

**Scope:**

* Target groups
* Load balancers (ALB/NLB/Classic)
* Auto Scaling Groups
* EC2 instances
* NAT gateways
* ENIs
* EBS volumes
* EFS file systems
* Security groups
* Subnets
* Route tables
* Internet gateways
* VPC deletion

**Note:**

* Uses cluster name + VPC relationship matching
* Designed for post-cluster destruction cleanup

---

## 5. GitOps Validation & Sync

### `validate_gitops.sh`

Validates GitOps manifests before deployment.

### `sync_route53.sh`

Synchronizes DNS records via Route53.

---

## 6. Secrets & Security

### `encrypt_secrets.sh`

Encrypts sensitive configuration for GitOps.

### `create_secrets.sh`

Generates Kubernetes secrets dynamically.

---

## 7. Utility Scripts

### `find.sh`

Search and inspection utility for scripts and configs.

### `functions/`

Shared helper functions used across scripts.

---

## 8. Operational Safety Model

The system follows a layered destruction order:

1. Kubernetes Applications (ArgoCD)
2. Namespaces and workloads
3. Cloud resources (AWS)
4. Terraform state cleanup (last)

---

## 9. Design Philosophy

* Fail-fast validation before destructive actions
* Interactive confirmation for critical AWS deletes
* Forced cleanup only as last resort
* GitOps-first infrastructure control
* Hybrid Kubernetes + AWS lifecycle management

---


