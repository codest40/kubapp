# Docker

This `docker/` directory contains the application layer of kubapp.

Instead of treating applications as completely separate projects, kubapp standardizes how services are built, configured, and deployed. Each application follows a similar structure:
- application source code
- Dockerfile
- deployment metadata
- runtime configuration

The goal is to make onboarding and deployment predictable across services without introducing heavy platform abstractions.

---

## Design Approach

Kubapp keeps application deployment intentionally simple.

Each service defines its own lightweight `kubapp.yml` file which acts as deployment metadata for the platform. This allows the automation layer to understand:
- compute type (EC2 or Fargate)
- application ports
- health endpoints
- storage requirements
- runtime features
- deployment environment settings

This approach avoids hardcoding deployment logic inside CI/CD pipelines or Kubernetes manifests.

---

## Standardized Service Structure

Most applications follow a similar structure:

```text
service/
├── Dockerfile
├── kubapp.yml
├── application source code
└── runtime dependencies
```

This makes services easier to:
- build
- validate
- deploy
- monitor
- scale
- troubleshoot

without creating separate deployment patterns for every application.

---

## Runtime Configuration

Applications are designed to be Kubernetes-ready from the start.

The deployment metadata supports:
- health and liveness endpoints
- ephemeral storage
- container security settings
- optional ServiceMonitor integration
- environment-aware deployments

The platform also supports mixed compute models, allowing services to run on either:
- EC2-backed nodes
- AWS Fargate

depending on workload requirements. for e.g workloads that require stricter, fine-grained control over security, compliance, and runtime configuration such as transaction apps can run on ec2, else on fargate, if apps is primarily user-facing or stateless services.

---

## Secrets Management

Sensitive application configuration is encrypted using SOPS.

Instead of storing plaintext credentials in the repository, secrets are managed as encrypted manifests and decrypted only during authorized deployment workflows.

This keeps the repository safer while still allowing secrets to remain version-controlled and reproducible.

---

## Local Development

The directory also includes a local Docker Compose setup for development and testing.

This allows services to be validated locally before entering the Kubernetes deployment workflow.
