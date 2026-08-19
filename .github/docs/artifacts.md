# KubApp CI/CD Artifacts

KubApp uses GitHub Actions artifacts to transfer temporary data between
workflow jobs and lifecycle stages.

Artifacts are used when generated data needs to move between GitHub Actions
runners without becoming a temporary Git commit or being passed through
workflow outputs.

## Workflows

| Workflow | Responsibility |
|---|---|
| `build.yml` | Generates application registry artifacts |
| `app_artifacts.yml` | Inspects artifacts from a successful build |
| `verify_runtime.yml` | Generates deployment verification artifacts |
| `get_stable_deploy.yml` | Retrieves a verified deployment snapshot |

---

## Artifact Types

KubApp currently uses two important artifact types.

| Artifact | Produced By | Purpose |
|---|---|---|
| `registry-<service>` | `build.yml` | Transfers generated application metadata to the registry commit stage |
| `deployment-snapshot` | `verify_runtime.yml` | Preserves information about a verified deployment for later stable-state operations |

These artifacts serve different lifecycle stages and should not be treated as
the GitOps source of truth.

---

## Application Registry Artifacts

During the build process, each application build produces its registry
metadata.

The metadata is uploaded as a service-specific artifact using:

    registry-<service>

Examples:

    registry-user_app
    registry-chatbot
    registry-nodejsapp

The artifact allows the matrix build jobs to produce their outputs
independently.

The final commit stage downloads these artifacts and uses them to construct
the environment registry.

The registry itself is documented separately in **GitOps Registry**.

---

## Build-to-Registry Transfer

The artifact transfer provides the boundary between parallel application
builds and the single registry commit operation.

    Build Matrix
         |
         +---- application artifact
         |
         +---- application artifact
         |
         +---- application artifact
         |
         v
    Commit Job
         |
         v
    GitOps Registry

This prevents multiple matrix jobs from attempting to modify the same Git
repository simultaneously.

The artifact is therefore temporary; the resulting validated registry is the
persistent Git state.

---

## Artifact Inspection

`app_artifacts.yml` provides an operational mechanism for inspecting the
artifacts produced by a successful build.

It can:

1. Locate the latest successful build run.
2. List its available artifacts.
3. Download a selected artifact.
4. Inspect its directory structure.
5. Display the generated metadata.

This is useful when investigating problems such as:

- missing registry metadata;
- incorrect image references;
- unexpected environment values;
- missing build output;
- malformed generated metadata.

The workflow is for inspection and troubleshooting only.

---

## Deployment Snapshots

Runtime verification produces a separate `deployment-snapshot` artifact.

Unlike application registry artifacts, the deployment snapshot represents
the result of runtime verification.

Its purpose is to preserve information about a deployment that has been
verified successfully.

    Deployment
         |
         v
    Runtime Verification
         |
         v
    deployment-snapshot
         |
         v
    Stable Deployment Retrieval
         |
         v
    Rollback

The verification, stable deployment, and rollback workflows define how this
information is used. This document only describes the artifact boundary.

See **Deployment Verification**, **Stable Deployment Retrieval**, and
**Rollback** for those lifecycle processes.

---

## Artifact Validation

Artifacts must exist before downstream processing can continue.

The registry-producing stage therefore verifies that downloaded artifact
data is available before using it.

After the resulting GitOps configuration has been reconstructed, the normal
GitOps validation is performed with:

    bash scripts/validate_gitops.sh

The effective boundary is:

    Download Artifact
         |
         v
    Artifact Available?
         |
       No +----> Stop
         |
        Yes
         |
         v
    Generate Persistent GitOps State
         |
         v
    Validate
         |
       Fail +----> Stop
         |
      Success
         |
         v
    Commit

---

## Why Artifacts Are Used

Artifacts provide temporary storage and transfer between independent
workflow jobs.

They avoid:

- passing generated files through workflow outputs;
- creating temporary Git commits;
- requiring later jobs to regenerate build output;
- manually transferring files between runners.

The lifecycle is therefore:

    Generate
       |
       v
    Upload Artifact
       |
       v
    Download
       |
       v
    Consume
       |
       v
    Persist Validated Result in Git

Git remains the source of truth.

Artifacts are only the transport mechanism used to move temporary workflow
output between stages.

---

## Artifact Responsibilities

| Component | Responsibility |
|---|---|
| `build.yml` | Produces application registry artifacts |
| `app_artifacts.yml` | Provides artifact inspection |
| Commit stage | Consumes application artifacts and produces persistent registry state |
| `verify_runtime.yml` | Produces deployment snapshots |
| `get_stable_deploy.yml` | Retrieves deployment snapshots for stable-state inspection |
| Git | Stores the resulting persistent GitOps state |

The artifact system therefore connects workflow stages without becoming
another source of deployment truth.
