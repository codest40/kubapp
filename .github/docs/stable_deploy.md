# Stable Deployment Retrieval

KubApp uses a dedicated workflow to identify the most recent known-stable deployment and retrieve the deployment snapshot associated with it.

## Workflow

`get_stable_deploy.yml`

## Purpose

The workflow answers:

> "What is the most recent deployment that was known to be stable for this environment?"

It does not perform the rollback itself. It prepares the information needed by the rollback process.

## Flow

    Environment
         |
         v
    Stable Tags
         |
         v
    Find Latest stable-<env>-*
         |
         v
    Resolve Git Commit
         |
         v
    Find Verification Run
         |
         v
    Retrieve Deployment Snapshot
         |
         v
    Stable Deployment Information

## Stable Tags

KubApp uses environment-specific Git tags to identify stable releases.

Examples:

    stable-dev-*
    stable-prod-*

The workflow filters repository tags using the selected environment and then uses version sorting to select the latest stable tag.

## Commit Resolution

After identifying the stable tag, the workflow resolves it to the exact Git commit.

    Stable Tag
         |
         v
    Git Commit SHA

This provides an immutable reference to the repository state associated with the stable deployment.

## Verification Run Lookup

The workflow then searches GitHub Actions for the runtime verification run associated with the stable commit.

This connects:

    Git Commit
         |
         v
    Verification Workflow
         |
         v
    Deployment Snapshot

The snapshot provides additional evidence about what was actually deployed and verified.

## Deployment Snapshot

The workflow downloads the `deployment-snapshot` artifact from the identified verification run.

The snapshot can contain information about the verified deployment, allowing the operator to inspect the stable runtime state before performing a rollback.

## Important Distinction

`get_stable_deploy.yml` is a **discovery and inspection workflow**.

It does not modify:

- Git history
- GitOps configuration
- Kubernetes resources
- Deployment state

The actual rollback is performed by `rollback.yml`.

## Relationship With Rollback

    verify_runtime.yml
            |
            v
    Deployment Snapshot
            |
            v
    get_stable_deploy.yml
            |
            v
    Stable Commit / Snapshot
            |
            v
    rollback.yml

This separation keeps stable-state discovery independent from the destructive rollback operation.

## Failure Conditions

The workflow stops if:

- No stable tag exists for the requested environment.
- The stable tag cannot be resolved to a commit.
- No verification run can be found.
- The deployment snapshot cannot be retrieved.

This prevents the rollback process from proceeding with an unknown or unverified stable state.
