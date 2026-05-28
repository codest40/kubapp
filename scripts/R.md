# Kubapp Scripts Toolkit — Operational Documentation

## 1. Overview

This document describes the operational shell and Python tooling used inside the Kubapp platform repository. The scripts form a unified automation layer covering GitOps lifecycle, Kubernetes management, secret handling, drift detection, cleanup, and development workflows.

The system is designed as a **safe-by-default automation toolkit** with strict validation, idempotency, and environment awareness (dev vs prod safeguards).

---

## 2. Design Philosophy

The scripting layer follows these principles:

* **Safety first**: destructive actions are guarded against production contexts
* **Deterministic execution**: scripts are repeatable and idempotent where possible
* **GitOps alignment**: changes flow through declarative files
* **Fail-fast validation**: invalid state is caught early
* **Separation of concerns**: each script handles a single operational domain

---

## 3. Core Utility: `find.sh`

### Purpose

The `find.sh` utility provides a lightweight file explorer across the repository based on file extensions and output mode.

It is primarily used for:

* quick inspection of script layers
* debugging GitOps and Terraform files
* auditing configuration changes

---

### Behavior

The tool accepts:

* one or more file extensions
* an action mode (`list` or `cat`)

Example execution:

```bash
./find.sh sh py cat
```

---

### Execution Modes

#### 1. List Mode

Displays matching files only:

```
./find.sh tf yml list
```

Output:

* file paths sorted alphabetically

---

#### 2. Cat Mode

Prints file contents with separators:

```
==================== ./file.sh ====================
<file content>
```

---

### Interactive Mode

When no arguments are provided, an interactive prompt is triggered:

* extensions input
* action selection

This allows ad-hoc exploration without memorizing CLI syntax.

---

### Internal Flow

1. Parse CLI arguments
2. Extract extensions and action
3. Build `find` expression dynamically
4. Collect sorted results
5. Render based on selected mode

---

### Safety Notes

* Only file reads are performed
* No modification or execution of files occurs
* Designed for read-only inspection

---

## 4. GitOps Activation Pipeline (`activate.sh`)

### Purpose

Runs full system activation workflow including validation, secret encryption, GitOps validation, and optional git push.

---

### Pipeline Steps

1. Validation phase (`validate.sh`)
2. Secret encryption (`encrypt_secrets.sh`)
3. GitOps validation (`validate_gitops.sh`)
4. Git commit + push (interactive confirmation)

---

### Safety Controls

* Explicit user confirmation before push
* Automatic rebase on remote divergence
* Graceful handling of empty commits

---

## 5. Secret Management (`encrypt_secrets.sh`)

### Purpose

Encrypts Terraform and GitOps secrets using SOPS with AGE keys.

---

### Features

* Multi-environment support (dev, prod, all)
* Terraform `.tfvars` encryption
* GitOps YAML encryption in-place
* Backup restoration on failure

---

### Safety Design

* Prevents accidental production encryption failures
* Skips already encrypted files
* Requires valid AGE key generation

---

## 6. Cluster Cleanup (`clean_cluster.sh`)

### Purpose

Safely removes Kubernetes resources while protecting system-critical components.

---

### Cleanup Order

1. ArgoCD ApplicationsSets
2. ArgoCD Applications
3. Namespace cleanup (non-system)
4. Ingress validation
5. Finalizer cleanup (stuck namespaces)

---

### Safety Rules

* Blocks execution in production context
* Preserves system namespaces:

  * kube-system
  * argocd
  * default
* Avoids deleting Terraform-managed namespaces

---

## 7. Drift Detection

### GitOps Drift (`drift_gitops.sh`)

Detects mismatch between desired state (YAML) and computed fingerprint.

Checks:

* structural drift (fingerprint mismatch)
* runtime drift (env mutation detection)

---

### Infrastructure Drift (`drift_state.sh`)

Uses Terraform plan to compare:

* local state
* real AWS infrastructure

Returns:

* OK (0)
* Drift detected (2)
* failure (1)

---

## 8. Cloud Cleanup (`delete_leftovers.sh`)

### Purpose

Removes orphan AWS resources such as:

* ENIs
* Load Balancers

---

### Decision Engine

Each ENI is classified by:

* NAT Gateway → skip
* EFS → skip
* VPC core → skip
* ELB → validate orphan status

Only orphaned resources are deleted.

---

## 9. GitOps Registry Tools

### `create_values.sh`

Generates Helm values.yaml dynamically from artifact JSON.

Features:

* deterministic static fingerprinting
* safe merge with existing values
* optional volume injection
* runtime probe configuration

---

### `register_new_svc.sh`

Manages ingress services declaratively:

* add service
* remove service
* validate schema integrity
* enforce HTTPS requirements

---

## 10. Commit System (`commit.sh`)

### Purpose

Provides a safe Git commit wrapper with CI awareness.

---

### Features

* auto-detects CI vs local execution
* staged path-based commits
* structured commit messages
* retry + rebase conflict resolution
* recovery fallback strategy

---

## 11. Validation Layer

### Common Validators

* `validate_vars.sh` → ensures required variables exist
* `check_data.sh` → JSON manifest integrity checks
* `prechecks.sh` → cluster readiness validation

---

## 12. Logging System (`logger.sh`)

### Purpose

Centralized structured logging system for script actions.

Logs include:

* timestamp
* action
* service
* environment
* message

Output stored in `/logs` directory.

---

## 13. Operational Flow Model

Typical lifecycle:

1. Prechecks
2. Activation pipeline
3. Secret encryption
4. GitOps sync
5. Drift validation
6. Runtime verification
7. Cleanup (if needed)

---

## 14. Summary

The scripts form a **full platform automation layer** that bridges:

* Kubernetes operations
* GitOps deployment flow
* Terraform infrastructure control
* AWS resource lifecycle management

The system is designed for controlled automation with strong safety boundaries and reproducible state transitions.

---

## 15. GitOps + Platform Workflows (End-to-End)

This section describes how all scripts combine into real operational workflows across the Kubapp platform.

---

### 15.1 Service Deployment Workflow (Golden Path)

This is the standard path for introducing or updating an application.

#### Flow

1. Developer prepares artifact JSON
2. `create_values.sh` generates Helm values
3. `register_new_svc.sh` updates ingress routing
4. `commit.sh` stages and commits GitOps changes
5. `activate.sh` triggers full pipeline
6. ArgoCD syncs desired state
7. `postchecks.sh` validates runtime health

#### Outcome

* Kubernetes manifests are updated declaratively
* Ingress routes are automatically configured
* Deployment is validated at runtime

---

### 15.2 Change Promotion Workflow

Used when only image or version changes occur.

#### Flow

1. Update image tag in GitOps app
2. Run `promote.sh`
3. Commit changes via `commit.sh`
4. ArgoCD sync applies new version
5. `postchecks.sh` validates rollout stability

#### Outcome

* No infrastructure change
* Zero-downtime update expected

---

### 15.3 Secrets Management Workflow

#### Flow

1. Secret values defined in Terraform or GitOps
2. `encrypt_secrets.sh` encrypts using SOPS + AGE
3. Encrypted secrets committed to Git
4. ArgoCD applies encrypted manifests

#### Outcome

* Secrets never stored in plaintext in Git
* Environment separation enforced (dev/prod/all)

---

### 15.4 Full Activation Workflow (System Boot / Reconciliation)

Triggered via `activate.sh`.

#### Flow

1. Validate cluster and configuration
2. Encrypt secrets
3. Validate GitOps structure
4. Stage and commit changes
5. Push to GitHub
6. Trigger ArgoCD reconciliation

#### Outcome

* Entire platform is synchronized
* Drift is corrected automatically through GitOps

---

### 15.5 Drift Recovery Workflow

Triggered when drift is detected.

#### Flow

1. `drift_gitops.sh` or `drift_state.sh` runs
2. Drift classification:

   * structural (Helm/YAML mismatch)
   * runtime (env mutation)
   * infra (Terraform mismatch)
3. Apply remediation:

   * regenerate values (`create_values.sh`)
   * reapply secrets (`set_app_secret.sh`)
   * terraform refresh/apply if needed
4. Commit corrected state
5. ArgoCD reconciles cluster

#### Outcome

* System self-heals toward declared state

---

### 15.6 Cluster Reset / Cleanup Workflow

Triggered via `clean_cluster.sh` or `delete_leftovers.sh`.

#### Flow

1. Delete ArgoCD Applications + ApplicationSets
2. Remove Kubernetes workloads (non-system namespaces)
3. Clean PVCs, ingress, services
4. Detect and remove orphan AWS resources (ENIs, ELBs)
5. Patch stuck namespaces (finalizers)

#### Outcome

* Clean cluster state
* No orphan cloud resources

---

### 15.7 Observability & Validation Workflow

Triggered continuously or post-deployment.

#### Flow

1. `check_cluster.sh` verifies readiness
2. `postchecks.sh` runs:

   * ArgoCD sync status
   * Kubernetes rollout health
   * Canary HTTP validation
   * synthetic health tests
3. Optional SLO check via Prometheus

#### Outcome

* Confirms system stability before marking deployment complete

---

### 15.8 CI/CD Commit Safety Workflow

Handled by `commit.sh`.

#### Flow

1. Detect CI vs local execution
2. Stage only provided paths
3. Validate changes exist
4. Commit with structured metadata
5. Attempt safe push
6. Rebase or recover if conflicts occur

#### Outcome

* Safe multi-environment Git operations
* Prevents broken pushes

---

## 16. Workflow Model Summary

All workflows converge into a single loop:

**Define → Generate → Commit → Deploy → Validate → Drift Check → Heal**

This ensures:

* Git remains the source of truth
* Kubernetes is always reconciled
* Infrastructure drift is continuously corrected
* Failures are self-contained and recoverable
