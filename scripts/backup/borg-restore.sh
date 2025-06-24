#!/usr/bin/env bash
set -euo pipefail

export BORG_REPO="borg:~/backups"
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

# Find the latest archive
latest=$(borg list --last 1 --format '{archive}' "$BORG_REPO")
if [[ -z "$latest" ]]; then
    echo "No archives found in $BORG_REPO" >&2
    exit 1
fi
echo "Restoring backup $latest"

# Extract at root so absolute paths restore into their original locations
pushd / >/dev/null
borg extract --verbose --progress "$BORG_REPO::$latest"
popd >/dev/null
