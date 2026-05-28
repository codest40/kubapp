# ------------------------------------------------------------
# CHALLENGES ENCOUNTERED (REAL-WORLD SYSTEM COMPLEXITY)
# ------------------------------------------------------------

# 1. STATE FRAGMENTATION ACROSS SYSTEMS
# ------------------------------------------------------------
# Problem:
# - Terraform state, GitOps state, and runtime cluster state
#   were evolving independently.

# Impact:
# - Conflicts between “desired state” and “actual state”
# - Hard-to-debug drift between layers

# Resolution approach:
# - Introduced gitops/state/current.json as a single
#   coordination anchor for workflows
# - Forced all pipelines to read from a unified context


# ------------------------------------------------------------

# 2. NON-DETERMINISTIC DRIFT IN KUBERNETES
# ------------------------------------------------------------
# Problem:
# - Manual kubectl changes and auto-scaling events caused
#   unexpected divergence from Git state.

# Impact:
# - Services appeared “healthy” but were not Git-compliant
# - Ingress routes became inconsistent over time

# Resolution approach:
# - Built validate_ingress.yml as a reconciliation gate
# - Enforced strict vs repair modes for controlled healing


# ------------------------------------------------------------

# 3. TERRAFORM STATE LOCKING AND CONCURRENCY ISSUES
# ------------------------------------------------------------
# Problem:
# - Multiple CI runs attempted simultaneous terraform operations

# Impact:
# - State lock conflicts
# - Pipeline failures during high activity periods

# Resolution approach:
# - Introduced unlock.yml recovery workflow
# - Enforced single-writer execution pattern per environment


# ------------------------------------------------------------

# 4. IMAGE + REGISTRY DESYNC PROBLEMS
# ------------------------------------------------------------
# Problem:
# - Docker images were built successfully but not consistently
#   reflected in GitOps manifests.

# Impact:
# - Cluster ran outdated versions despite successful builds

# Resolution approach:
# - Separated build.yml and update.yml responsibilities
# - Introduced registry JSON as immutable artifact layer


# ------------------------------------------------------------

# 5. ARGOCD SYNC DELAYS AND EVENTUAL CONSISTENCY GAPS
# ------------------------------------------------------------
# Problem:
# - ArgoCD reconciliation lag created temporary mismatch
#   between Git state and cluster state.

# Impact:
# - Verification pipelines occasionally failed prematurely

# Resolution approach:
# - Added verify_runtime.yml as a post-sync validation layer
# - Treated ArgoCD as eventual consistency engine, not instant


# ------------------------------------------------------------

# 6. ORPHAN RESOURCES IN GITOPS REGISTRY
# ------------------------------------------------------------
# Problem:
# - Deleted services still left behind ingress or Helm entries

# Impact:
# - Ghost routing and stale deployments

# Resolution approach:
# - Built remove_app.yml + orphan cleaner logic
# - Introduced registry-vs-ingress reconciliation checks


# ------------------------------------------------------------

# 7. PIPELINE COMPLEXITY AND DEBUGGING DIFFICULTY
# ------------------------------------------------------------
# Problem:
# - Multiple interdependent workflows made failure tracing difficult

# Impact:
# - Hard to identify root cause across layers (infra vs app vs GitOps)

# Resolution approach:
# - Introduced app_artifacts.yml inspector
# - Added snapshot-based debugging via verify_runtime.yml


# ------------------------------------------------------------

# 8. SAFE ROLLBACK WITHOUT SYSTEM CORRUPTION
# ------------------------------------------------------------
# Problem:
# - Rolling back only Kubernetes state was not enough
# - Terraform + GitOps + cluster could diverge during rollback

# Impact:
# - Partial rollback left system in inconsistent state

# Resolution approach:
# - Introduced stable snapshot system (stable-* tags)
# - Designed rollback as full-system restore, not partial revert


# ------------------------------------------------------------
# FINAL OUTCOME
# ------------------------------------------------------------
# These challenges shaped KubApp into a:
#
# - deterministic system instead of reactive pipelines
# - self-healing GitOps control plane
# - closed-loop infrastructure orchestration engine
#
# The system evolved from:
#
# "CI/CD pipelines"
# → to
# "continuous state convergence system"
