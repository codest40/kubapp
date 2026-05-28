#!/usr/bin/env bash
set -euo pipefail

BASE_URL="http://localhost:3000/webhook/github"
REPO="codest/kubapp"
REMOTE=${REMOTE:-true}

echo "Generating synthetic GitHub events..."

if [[ "$REMOTE" == "false" ]]; then
  IP=$(curl ifconfig.me)
fi

if [[ -z "$IP" ]]; then
  echo "IP is empty"
  exit 1
else
  echo "IP: $IP"
fi

# Push
curl -X POST http://$IP:3000/webhook/github \
  -H "X-GitHub-Event: push" \
  -H "Content-Type: application/json" \
  -d '{
    "repository": {"full_name": "kubapp"},
    "after": "commit-001"
  }'

# Pull Request
curl -X POST http://$IP:3000/webhook/github \
  -H "X-GitHub-Event: pull_request" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "opened",
    "repository": {"full_name": "kubapp"}
  }'

# Workflow Run
curl -X POST http://$IP:3000/webhook/github \
  -H "X-GitHub-Event: workflow_run" \
  -H "Content-Type: application/json" \
  -d '{
    "repository": {"full_name": "kubapp"},
    "workflow_run": {
      "name": "CI",
      "status": "completed",
      "conclusion": "success",
      "run_started_at": "2026-05-16T10:00:00Z",
      "updated_at": "2026-05-16T10:05:00Z"
    }
  }'

# Release
curl -X POST http://$IP:3000/webhook/github \
  -H "X-GitHub-Event: release" \
  -H "Content-Type: application/json" \
  -d '{
    "repository": {"full_name": "kubapp"},
    "release": {"tag_name": "v1.0.0"}
  }'

# Issue
curl -X POST http://$IP:3000/webhook/github \
  -H "X-GitHub-Event: issues" \
  -H "Content-Type": "application/json" \
  -d '{
    "action": "opened",
    "repository": {"full_name": "kubapp"},
    "issue": {"state": "open"}
  }'
