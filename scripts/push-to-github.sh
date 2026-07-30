#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .git/config ]]; then
  cp .git/remote-config .git/config
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin https://github.com/harpreetsingh309/AussieStart.git
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI not logged in. Starting login..."
  gh auth login
fi

if ! gh repo view harpreetsingh309/AussieStart >/dev/null 2>&1; then
  gh repo create AussieStart --public \
    --description "Offline SwiftUI settlement guide for newcomers to Australia" \
    --source=. --remote=origin || true
fi

git push -u origin feature/mvp-foundation
git push -u origin main

echo
echo "Done."
echo "Feature branch: feature/mvp-foundation"
echo "Repo: https://github.com/harpreetsingh309/AussieStart"
