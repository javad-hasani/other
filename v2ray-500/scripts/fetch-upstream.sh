#!/usr/bin/env bash
# Safe source preparation only. NEVER installs software or runs vendor scripts.
# Provenance is pinned in ../config/upstream.lock (exact source commit SHA).
set -Eeuo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCKFILE="$ROOT/config/upstream.lock"
DEST="$ROOT/vendor"
[[ -f "$LOCKFILE" ]] || { echo "Missing upstream lockfile" >&2; exit 1; }
mkdir -p "$DEST"
: > "$DEST/UPSTREAM-COMMITS.txt"

while IFS=$'\t' read -r name url expected || [[ -n "${name:-}" ]]; do
  [[ -z "${name:-}" || "$name" == \#* ]] && continue
  [[ "$name" =~ ^[a-z0-9-]+$ ]] || { echo "Invalid component: $name" >&2; exit 1; }
  [[ "$url" =~ ^https://github.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+\.git$ ]] ||
    { echo "Invalid GitHub URL: $url" >&2; exit 1; }
  [[ "$expected" =~ ^[0-9a-f]{40}$ ]] ||
    { echo "Invalid commit SHA for $name" >&2; exit 1; }

  if [[ -d "$DEST/$name/.git" ]]; then
    actual="$(git -C "$DEST/$name" rev-parse HEAD)"
    if [[ "$actual" != "$expected" ]]; then
      echo "STOP: $name exists at $actual, but lock expects $expected" >&2
      echo "Review manually; this script never overwrites an existing checkout." >&2
      exit 2
    fi
  elif [[ -e "$DEST/$name" ]]; then
    echo "STOP: path exists but is not a Git repository: $DEST/$name" >&2
    exit 2
  else
    git clone --quiet "$url" "$DEST/$name"
    git -C "$DEST/$name" checkout --quiet --detach "$expected"
  fi
  actual="$(git -C "$DEST/$name" rev-parse HEAD)"
  printf "%s\t%s\t%s\n" "$name" "$actual" "$url" >> "$DEST/UPSTREAM-COMMITS.txt"
  echo "PINNED: $name @ $actual"
done < "$LOCKFILE"

echo "Pinned sources ready in: $DEST"
echo "NO servers or containers have been started."
echo "Snapshot is NOT a security audit; review before installing."
