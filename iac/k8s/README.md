## KubApp — Kubernetes Platform Layer (Terraform + Helm Bootstrap)

## 1. Overview

This KubApp Kubernetes layer is the platform bootstrap layer built on top of an existing EKS infrastructure provisioned by Terraform.

It is responsible for transforming a raw Kubernetes cluster into a production-ready platform runtime, by installing and orchestrating foundational services such as:

* GitOps control plane (ArgoCD)
* Networking controllers (AWS Load Balancer Controller)
* DNS automation (ExternalDNS)
* Storage integration (EFS CSI Driver)
* Logging pipeline (Fluent Bit)
* Namespace and identity structure (IRSA-based service accounts)

This layer is intentionally designed as a controlled, staged bootstrap system prioritizing safety, determinism, and operational clarity over parallel execution speed.

---

## 2. Design Philosophy

The Kubernetes layer follows three core principles:

### 2.1 Staged and Safe Deployment

Resources are provisioned in a controlled sequence, typically one or two components at a time.

This reduces:

* Blast radius of failures
* Terraform apply noise
* Dependency race conditions

It improves:

* Debuggability
* Predictability
* Operational safety in cluster bootstrapping

---

### 2.2 GitOps-First Runtime Model

ArgoCD is treated as the central control plane for workloads, but only after it is fully operational.

Key principle:

> GitOps must never start before the GitOps engine (ArgoCD) is fully ready.

This ensures:

* No partial reconciliation loops
* No dual ownership conflicts between Terraform and ArgoCD
* Stable handover from bootstrap to steady-state operations

---

### 2.3 Event-Driven Infrastructure Behavior

Core controllers such as:

* AWS Load Balancer Controller
* ExternalDNS

are installed early, but remain **idle until triggered by Kubernetes resources (e.g., Ingress)**.

This enables:

* Zero premature AWS resource creation
* Clean separation between control plane and workload events
* Natural scaling based on demand

---

## 3. Architecture Layers

The system is structured as a **bootstrap DAG (Directed Acyclic Graph)** of infrastructure components:

```
EKS Cluster (Infra Layer)
        ↓
Kubernetes Bootstrap Layer (this module)
        ↓
Core Platform Services
        ↓
GitOps Control Plane (ArgoCD)
        ↓
Application Workloads (via GitOps)
```

---

## 4. Core Components

### 4.1 Namespace Layer

Namespaces are defined as logical isolation boundaries for workloads:

* `argocd` → GitOps control plane
* (future) `monitoring`, `logging`, `user`, `admin`

Each namespace includes standardized labels for:

* environment tracking
* workload classification
* observability grouping

---

### 4.2 Identity & Service Accounts (IRSA)

All critical system components use IAM Roles for Service Accounts:

* AWS Load Balancer Controller
* ExternalDNS
* Fluent Bit
* EFS CSI Driver

This ensures:

* No static AWS credentials in cluster
* Fine-grained AWS permissions per workload
* Secure cloud-native identity integration

---

### 4.3 Networking Layer

#### AWS Load Balancer Controller

Responsible for:

* Provisioning ALB/NLB from Kubernetes Ingress resources

Behavior:

* Active immediately after installation
* Reacts only when Ingress resources exist

---

#### ExternalDNS

Responsible for:

* Creating Route53 DNS records from Ingress definitions

Configuration highlights:

* Upsert-only policy (prevents destructive changes)
* Ingress-driven DNS automation

---

### 4.4 GitOps Layer (ArgoCD)

ArgoCD is the central orchestration engine for application deployment.

Design constraints:

* Must be fully installed and healthy before GitOps workloads begin
* Deployed early but not used until readiness is confirmed
* Acts as the sole controller for application state after bootstrap

This ensures a clean transition from:

> Terraform-managed bootstrap → ArgoCD-managed steady-state

---

### 4.5 Storage Layer (EFS CSI Driver)

Provides:

* Persistent volume support via AWS EFS

Characteristics:

* Installed during bootstrap phase
* Used by workloads requiring shared storage

---

### 4.6 Observability Layer (Fluent Bit)

Handles log collection and forwarding:

* Collects container logs
* Sends logs to CloudWatch
* Applies standardized metadata labels for traceability

---

## 5. Readiness & Bootstrapping Control

The system enforces explicit readiness gates:

### 5.1 Cluster Readiness Flow

1. Wait for EKS cluster activation
2. Install core platform components
3. Verify controller rollouts
4. Mark cluster as "ready" via ConfigMap

---

### 5.2 Readiness Artifact

A ConfigMap is used as a runtime state indicator:

* `initializing` → during bootstrap
* `ready` → after successful platform initialization

This provides:

* External observability of cluster state
* Safe handover to GitOps layer

---

## 6. Dependency Strategy

Dependencies are explicitly defined using Terraform `depends_on` to enforce:

* Ordered installation of platform components
* Prevention of race conditions
* Controlled bootstrap execution flow

However, dependencies are intentionally minimized to essential safety constraints only, avoiding over-coupling.

---

## 7. Operational Behavior Model

### 7.1 Controller Activation Model

| Component     | Installed | Active Behavior             |
| ------------- | --------- | --------------------------- |
| LB Controller | Early     | Idle until Ingress exists   |
| ExternalDNS   | Early     | Idle until DNS events occur |
| ArgoCD        | Early     | Active after readiness gate |
| Fluent Bit    | Early     | Continuous log streaming    |

---

### 7.2 Key Behavioral Principle

> Controllers are installed early for readiness, but only become active when triggered by Kubernetes state changes.

---

## 8. Separation of Concerns

This layer enforces strict separation between:

### Terraform responsibilities

* Bootstrap infrastructure
* Install platform controllers
* Establish system readiness

### ArgoCD responsibilities

* Application deployment
* Continuous reconciliation
* Git-driven desired state management

---

## 9. Evolution Roadmap

Planned extensions to this layer include:

### 9.1 Observability Expansion

* Prometheus / Grafana stack
* Metrics aggregation layer

### 9.2 Policy Layer

* Admission control (OPA / Kyverno)
* Governance rules for workloads

### 9.3 GitOps Expansion

* Full migration of workloads into ArgoCD Applications
* Reduction of Terraform-managed runtime resources

---

## 10. Summary

The KubApp Kubernetes layer is a controlled platform bootstrap system designed to:

* Safely initialize production-grade Kubernetes environments
* Establish GitOps as the primary deployment mechanism
* Reduce operational risk through staged provisioning
* Maintain clear ownership boundaries between Terraform and Kubernetes controllers

It intentionally favors:

> determinism, safety, and clarity over parallelism and speed

---

