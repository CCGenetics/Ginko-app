#!/usr/bin/env bash
set -euo pipefail

# Sync vendor repository into the app folder.
# This script is intentionally simple: clone if missing, otherwise hard reset to remote.

REPO_URL="https://github.com/CCGenetics/Ginko-Rfun.git"
DEST_DIR="app/scripts/Ginko-Rfun"
BRANCH="main"

if [[ ! -d "$DEST_DIR/.git" ]]; then
  # Fresh clone (or re-clone if the directory exists but is not a git repo).
  rm -rf "$DEST_DIR"
  mkdir -p "$(dirname "$DEST_DIR")"
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$DEST_DIR"
else
  # Update existing clone to match the remote branch exactly.
  git -C "$DEST_DIR" fetch origin "$BRANCH"
  git -C "$DEST_DIR" reset --hard "origin/$BRANCH"
fi
