# ============================================================
# KUBAPP — SECURITY ARCHITECTURE & GOVERNANCE MODEL
# ============================================================

KubApp is designed as a GitOps-driven platform engineering system.

Security is not treated as an afterthought or external layer.
Instead, security is embedded into every stage of the platform lifecycle:

- Infrastructure provisioning (Terraform)
- Build & packaging (Docker / CI)
- GitOps state management (Git)
- Reconciliation layer (ArgoCD)
- Runtime enforcement (Kubernetes)
- Verification & drift detection
- Snapshot & recovery layer

The core principle:

> Security is continuously enforced through reconciliation, not manually applied.


# ============================================================
# 1. SECURITY MODEL OVERVIEW
# ============================================================

KubApp follows a layered security model:

1. Identity & Access Security (IAM / OIDC)
2. Infrastructure Security (Terraform)
3. Supply Chain Security (CI/CD + Build)
4. GitOps Security (Git as source of truth)
5. Cluster Security (Kubernetes RBAC & Policies)
6. Runtime Security (Workload isolation & validation)
7. Drift & Compliance Security (continuous enforcement)

Each layer assumes:
- lower layers may fail
- higher layers enforce correction and validation


# ============================================================
# 2. IDENTITY & ACCESS SECURITY (IAM + OIDC)
# ============================================================

KubApp uses IAM-based identity control for all cloud interactions.

Security principles:
- Least privilege access
- Role-based access control (RBAC)
- Temporary credentials via OIDC (no static keys in CI)

Enforced rules:
- CI pipelines use OIDC roles only
- No long-lived AWS access keys in repositories
- Terraform execution uses scoped IAM roles per environment
- Cross-account access is explicitly denied unless required

Threats mitigated:
- credential leakage
- unauthorized infrastructure changes
- privilege escalation in CI/CD


# ============================================================
# 3. INFRASTRUCTURE SECURITY (TERRAFORM LAYER)
# ============================================================

Terraform is treated as a controlled mutation layer.

Security controls:
- state locking enabled
- remote backend storage
- environment isolation (dev/staging/prod separation)
- no direct manual cloud changes (drift is detected, not allowed)

Validation rules:
- terraform plan is mandatory before apply
- destructive changes require explicit workflow triggers
- sensitive variables are encrypted (SOPS where applicable)

Threats mitigated:
- infrastructure drift
- accidental resource deletion
- unauthorized cloud changes


# ============================================================
# 4. SUPPLY CHAIN SECURITY (CI/CD LAYER)
# ============================================================

GitHub Actions pipelines are hardened:

Security rules:
- pinned action versions (no floating tags)
- no untrusted third-party actions without review
- secrets injected only via secure store
- build isolation per job
- artifact immutability after build

Pipeline protections:
- required status checks
- protected branches for main environments
- no direct push to production workflows

Threats mitigated:
- CI injection attacks
- compromised dependencies
- unauthorized deployments


# ============================================================
# 5. GITOPS SECURITY (GIT AS SOURCE OF TRUTH)
# ============================================================

Git is the single authoritative state store.

Security properties:
- all desired state changes must pass through Git
- no direct cluster mutations allowed
- pull-based deployment model via ArgoCD

Controls:
- protected branches
- signed commits (optional enhancement)
- PR-based changes for production environments
- audit trail for all state changes

Threats mitigated:
- unauthorized deployments
- configuration drift
- hidden runtime changes


# ============================================================
# 6. KUBERNETES CLUSTER SECURITY
# ============================================================

Cluster security is enforced via:

RBAC:
- service accounts scoped per application
- minimal privilege roles per namespace

Namespace isolation:
- environment separation (dev/staging/prod)
- per-service namespaces where needed

Admission control (recommended extensions):
- resource quotas
- network policies
- pod security standards

Runtime restrictions:
- no privileged containers by default
- restricted hostPath usage
- controlled ingress exposure

Threats mitigated:
- lateral movement
- privilege escalation inside cluster
- namespace collision attacks


# ============================================================
# 7. RUNTIME SECURITY & VALIDATION
# ============================================================

KubApp continuously validates runtime state:

Checks include:
- pod health and readiness
- deployment replica consistency
- ingress reachability validation
- service endpoint integrity
- ArgoCD sync status

Security behavior:
- unhealthy deployments are flagged, not ignored
- drift triggers reconciliation loops
- failed states prevent snapshot creation

Threats mitigated:
- partial deployments
- hidden failures
- inconsistent runtime state


# ============================================================
# 8. SECRETS MANAGEMENT
# ============================================================

Secrets are never stored in plain text in Git.

Approach:
- SOPS encrypted files in Git
- environment-specific encryption keys
- decryption only during runtime deployment

Rules:
- no secrets in logs
- no secrets in build artifacts
- no plaintext secrets in registry

Threats mitigated:
- secret leakage in repository
- accidental exposure in CI logs
- compromised artifacts


# ============================================================
# 9. DRIFT & COMPLIANCE SECURITY
# ============================================================

KubApp continuously detects and corrects drift:

Monitored layers:
- Terraform state drift
- Kubernetes resource drift
- Git vs cluster mismatch
- ingress inconsistencies

Behavior:
- drift detection does NOT immediately mutate production
- drift triggers validation + controlled reconciliation
- all corrections are logged and versioned

Threats mitigated:
- silent infrastructure divergence
- unauthorized runtime modification
- configuration decay over time


# ============================================================
# 10. SECURITY PRINCIPLE (CORE PHILOSOPHY)
# ============================================================

KubApp follows a strict principle:

> “No change is trusted until it is validated, reconciled, and observable.”

Security is als a continuous reconciliation loop embedded into the platform.

This ensures:
- reproducibility
- auditability
- controlled mutation
- predictable recovery
