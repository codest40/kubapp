# KubApp CI/CD

KubApp uses GitHub Actions to automate the application lifecycle from
source changes through container image creation, GitOps registry
generation, Kubernetes provisioning, deployment, verification,
rollback, and cleanup.

## CI/CD Architecture

The architecture and end-to-end workflow are documented in:

- [CI/CD Architecture](./docs/architecture.md)
- [Execution Flow](./docs/flow.md)

## Pipeline Stages

1. **Build**
2. **Registry Generation**
3. **GitOps Provisioning**
4. **Deployment**
5. **Runtime Verification**
6. **Rollback**
7. **Cleanup**

## Workflow Categories

| Category | Workflows |
|---|---|
| Pipeline orchestration | [`activate_pipeline.yml`](./activate_pipeline.yml) |
| Application build | [`build.yml`](./build.yml) |
| GitOps provisioning | [`add_new_app.yml`](./add_new_app.yml) |
| Deployment | [`setup_argocd.yml`](./setup_argocd.yml), [`verify_runtime.yml`](./verify_runtime.yml) |
| Rollback | [`get_stable_deploy.yml`](./get_stable_deploy.yml), [`rollback.yml`](./rollback.yml) |
| Cleanup | [`clean_argocd.yml`](./clean_argocd.yml), [`remove_app.yml`](./remove_app.yml) |
| Ingress management | [`remove_svc.yml`](./remove_svc.yml) |
| Operations | [`fixer.yml`](./fixer.yml) |
| Debugging / artifacts | [`app_artifacts.yml`](./app_artifacts.yml), [`docker-push.yml`](./docker-push.yml) |

## Documentation

Detailed documentation for each part of the CI/CD system is maintained
under [`docs/`](./docs/).

### Architecture & Flow

- [CI/CD Architecture](./docs/architecture.md) — Overall CI/CD architecture, workflow relationships, and major components.
- [Execution Flow](./docs/flow.md) — End-to-end flow from source change through build, GitOps provisioning, deployment, verification, and cleanup.

### Build & Registry

- [Build Pipeline](./docs/build.md) — Container build, tagging, pushing, service matrix generation, and registry artifact creation.
- [Registry Generation](./docs/registry.md) — How build artifacts are transformed into the GitOps registry and how platform/backend services are registered.

### GitOps & Application Provisioning

- [GitOps Provisioning](./../gitops/README.md) — Application metadata, values generation, secret injection, ingress registration, validation, and GitOps commits.
- [Application Provisioning](./docs/add_new_app.md) — Detailed behavior of the application provisioning workflow.
- [Ingress Management](./docs/ingress.md) — Shared ingress registration and service removal.

### Deployment & Verification

- [Deployment](./docs/deployment.md) — Argo CD setup, application deployment, and environment-specific deployment behavior.
- [Runtime Verification](./docs/verification.md) — Post-deployment health checks and runtime validation.

### Rollback

- [Rollback](./docs/rollback.md) — Stable deployment identification, deployment snapshots, target rollback, and full rollback.
- [Stable Deployment](./docs/stable_deploy.md) — How KubApp identifies and retrieves the last known stable deployment.

### Cleanup & Reconciliation

- [Cleanup](./docs/cleanup.md) — Cluster cleanup and removal of Kubernetes resources.
- [Application Reconciliation](./docs/reconciliation.md) — Detection and removal of orphaned application resources.
- [Service Removal](./docs/remove_service.md) — Removing services from the shared ingress and triggering downstream reconciliation.

### Operations & Debugging

- [Operational Workflows](./docs/operations.md) — Manual operational actions and the KubApp fixer workflow.
- [Artifact Inspection](./docs/artifacts.md) — Inspecting build artifacts and deployment snapshots.

## Workflow Reference

For the complete list of GitHub Actions workflows, see the
[`.github/workflows`](./workflows/) directory.

| Workflow | Purpose |
|---|---|
| [`activate_pipeline.yml`](./workflows/activate_pipeline.yml) | Manually orchestrates the major pipeline stages |
| [`build.yml`](./workflows/build.yml) | Builds and pushes application images and generates registry metadata |
| [`add_new_app.yml`](./workflows/add_new_app.yml) | Provisions applications into the GitOps structure |
| [`setup_argocd.yml`](./workflows/setup_argocd.yml) | Configures Argo CD and deployment resources |
| [`verify_runtime.yml`](./workflows/verify_runtime.yml) | Verifies deployed application runtime state |
| [`get_stable_deploy.yml`](./workflows/get_stable_deploy.yml) | Retrieves the stable deployment information used for rollback |
| [`rollback.yml`](./workflows/rollback.yml) | Performs target or full rollback |
| [`clean_argocd.yml`](./workflows/clean_argocd.yml) | Cleans Kubernetes / Argo CD resources |
| [`remove_app.yml`](./workflows/remove_app.yml) | Reconciles and removes orphaned applications |
| [`remove_svc.yml`](./workflows/remove_svc.yml) | Removes services from shared ingress |
| [`fixer.yml`](./workflows/fixer.yml) | Provides controlled operational troubleshooting |
| [`app_artifacts.yml`](./workflows/app_artifacts.yml) | Inspects build artifacts |
| [`docker-push.yml`](./workflows/docker-push.yml) | Manually builds and pushes a Docker image |

## Design Principles

KubApp CI/CD is designed around:

- **Git-driven automation** — GitHub is the source of workflow and GitOps changes.
- **Immutable container images** — Builds produce uniquely tagged images while maintaining a `latest` tag.
- **GitOps-based deployment** — Kubernetes deployment state is generated and managed through Git.
- **Environment isolation** — Development and production workflows explicitly identify their target environment.
- **Automated reconciliation** — Orphaned applications and stale resources can be detected and removed.
- **Controlled rollback** — Stable deployments are identified and can be restored without rebuilding application images.
- **Operational safety** — Destructive operations include explicit safety checks and production protections.
- **Centralized ingress** — Applications are registered into the shared ingress configuration rather than creating independent ingress infrastructure for every application.
- **Secret management with SOPS** — Secrets are handled through SOPS/AGE encryption; plaintext values that may appear in local development files are local-only and are not committed or used outside the local environment.

## Directory Structure

```text
.github/
├── README.md
└── workflows/
    ├── activate_pipeline.yml
    ├── add_new_app.yml
    ├── app_artifacts.yml
    ├── build.yml
    ├── clean_argocd.yml
    ├── docker-push.yml
    ├── fixer.yml
    ├── get_stable_deploy.yml
    ├── remove_app.yml
    ├── remove_svc.yml
    ├── rollback.yml
    ├── setup_argocd.yml
    └── verify_runtime.yml

    docs/
    ├── README.md
    ├── architecture.md
    ├── flow.md
    ├── build.md
    ├── registry.md
    ├── gitops.md
    ├── add_new_app.md
    ├── ingress.md
    ├── deployment.md
    ├── verification.md
    ├── rollback.md
    ├── stable_deploy.md
    ├── cleanup.md
    ├── reconciliation.md
    ├── remove_service.md
    ├── operations.md
    ├── artifacts.md
    └── 

