```bash
                ┌──────────────────────────────┐
                │  GitHub Actions Workflows    │
                │  (CI/CD Control Plane)       │
                └────────────┬─────────────────┘
                             │
     ┌───────────────────────┼────────────────────────┐
     │                       │                        │
 build.yml           activate_pipeline.yml     cleanup workflows
     │                       │                        │
     ▼                       ▼                        ▼
Docker Images        Orchestration Layer     Cluster Cleanup
     │
     ▼
GitOps Registry (JSON Source of Truth)
     │
     ▼
add_new_app.yml (Reconciliation Engine)
     │
     ▼
Kubernetes Cluster (AWS EKS)
     │
     ▼
ArgoCD (Declarative Sync Engine)

```
