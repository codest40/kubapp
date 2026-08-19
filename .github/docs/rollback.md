# Rollback

KubApp supports controlled rollback to a previously verified stable deployment.

Rollback is based on Git history, stable deployment tags, and deployment snapshots generated during runtime verification.

## Workflows

- `get_stable_deploy.yml` — identifies and retrieves a stable deployment.
- `rollback.yml` — applies the rollback.

## Rollback Flow

    Verified Deployment
            |
            v
    Deployment Snapshot
            |
            v
        Stable Tag
            |
            v
    get_stable_deploy.yml
            |
            v
    Identify Stable Commit
            |
            v
        rollback.yml
            |
            +----------------------+
            |                      |
            v                      v
         TARGET                  FULL
            |                      |
            v                      v
    Restore GitOps            Restore Entire
    State Only                Repository State
            |                      |
            +----------+-----------+
                       |
                       v
                  Git Push
                       |
                       v
              Deployment Reconciles

## Stable Deployment

KubApp identifies stable deployments using environment-specific tags:

    stable-dev-*
    stable-prod-*

The latest matching stable tag is selected and resolved to its Git commit.

This provides a deterministic reference point for rollback.

## Retrieve Stable Deployment

`get_stable_deploy.yml` performs the discovery phase.

It:

1. Receives the target environment.
2. Fetches repository tags.
3. Finds the latest stable tag for that environment.
4. Resolves the tag to its Git commit.
5. Locates the corresponding runtime verification run.
6. Retrieves the deployment snapshot.
7. Displays the snapshot for inspection.

This workflow does not modify the repository.

It identifies the known stable state that can be used for rollback.

## Rollback Modes

`rollback.yml` supports two rollback modes.

### Target Rollback

Target rollback restores only the Kubernetes application GitOps state:

    gitops/envs/

The workflow:

1. Fetches repository tags.
2. Validates the requested tag.
3. Restores `gitops/envs` from the selected tag.
4. Creates a rollback commit.
5. Pushes the commit.

This allows the repository's application deployment state to move back without rewriting the rest of the repository history.

### Full Rollback

Full rollback restores the entire repository to the selected stable commit.

The workflow:

1. Fetches the stable tag.
2. Checks out `main`.
3. Resets `main` to the selected commit.
4. Pushes the rewritten branch using `--force-with-lease`.

This is a much more destructive operation because it changes the branch history.

## Target vs Full Rollback

| Mode | Scope | Git History | Typical Use |
|---|---|---|---|
| `target` | `gitops/envs` | Preserved | Application deployment rollback |
| `full` | Entire repository | Rewritten | Complete repository rollback |

Target rollback should normally be preferred because it limits the rollback to the application deployment state.

## Relationship With Verification

Rollback depends on having a known stable deployment.

    Build
      |
      v
    Deploy
      |
      v
    Verify Runtime
      |
      v
    Deployment Snapshot
      |
      v
    Stable Deployment
      |
      v
    Rollback

This prevents rollback from being based solely on an arbitrary Git commit. The selected version is associated with a deployment that was previously verified.
