#!/usr/bin/env bash
# Safe source preparation only: no installs, no root commands, no daemon changes.
set -Eeuo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${ROOT}/vendor"
mkdir -p "$DEST"
: > "$DEST/UPSTREAM-COMMITS.txt"

clone_once() {
  local name="$1"
  local url="$2"
  if [[ -d "$DEST/$name/.git" ]]; then
    echo "EXISTS: $name (no update performed)"
  elif [[ -e "$DEST/$name" ]]; then
    echo "Error: $DEST/$name exists but is not a git checkout" >&2
    exit 2
  else
    git clone --depth 1 "$url" "$DEST/$name"
  fi
  local sha
  sha="$(git -C "$DEST/$name" rev-parse HEAD)"
  printf "%s %s %s\n" "$name" "$sha" "$url" >> "$DEST/UPSTREAM-COMMITS.txt"
  echo "$name @ $sha"
}

clone_once "remnawave-backend" "https://github.com/remnawave/backend.git"
clone_once "remnawave-node" "https://github.com/remnawave/node.git"
clone_once "bedolaga-bot" "https://github.com/BEDOLAGA-DEV/remnawave-bedolaga-telegram-bot.git"
clone_once "remnasetup" "https://github.com/Capybara-z/RemnaSetup.git"

echo
echo "Sources ready in: $DEST"
echo "No services have been installed or started."
echo "Review licenses, pinned commits, Docker Compose, scripts and secrets before deploying."
