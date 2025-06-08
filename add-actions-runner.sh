#!/bin/bash
set -e

# 引数チェック
if [ -z "$1" ]; then
  echo "Usage: $0 <owner/repo>"
  exit 1
fi

REPO_FULL="$1"                          # 例: yourname/repo1
RUNNER_DIR="actions-runner/$(basename "$REPO_FULL")"
RUNNER_VERSION="2.317.0"
PLATFORM="linux-x64"                   # 他に windows-x64, osx-x64 など
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-${PLATFORM}-${RUNNER_VERSION}.tar.gz"
GITHUB_PAT="${GITHUB_PAT:?Set GITHUB_PAT env var}" # export GITHUB_PAT beforehand

echo "Setting up runner for $REPO_FULL..."

# トークン取得
# GitHub CLI api
# https://cli.github.com/manual/gh_api

TOKEN=$(gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/${REPO_FULL}/actions/runners/registration-token \
  | jq -r .token
)

# ディレクトリ作成
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# ランナー取得（キャッシュあり）
if [ ! -f "actions-runner-${PLATFORM}-${RUNNER_VERSION}.tar.gz" ]; then
  echo "Downloading runner..."
  curl -O -L "$RUNNER_URL"
  tar xzf "actions-runner-${PLATFORM}-${RUNNER_VERSION}.tar.gz"
fi

# 設定
./config.sh --unattended \
  --url "https://github.com/${REPO_FULL}" \
  --token "$TOKEN" \
  --name "$(hostname)-$(basename "$REPO_FULL")" \
  --labels self-hosted,$(basename "$REPO_FULL")

echo "Runner directory prepared: $RUNNER_DIR"
echo "To start runner: cd $RUNNER_DIR && ./run.sh"

