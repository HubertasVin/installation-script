#!/usr/bin/env bash

export BORG_REPO="borg:~/backups"
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

SOURCES=(
    "$HOME/Documents/backup-folder"
    "$HOME/Pictures"
)

# Build a temporary exclude‐file from all .gitignore rules
EXCLUDE_FILE=$(mktemp)
trap 'rm -f "$EXCLUDE_FILE"' EXIT

for src in "${SOURCES[@]}"; do
    # find every .gitignore under each source
    find "$src" -type f -name .gitignore | while read -r gi; do
        dir=$(dirname "$gi")
        # strip blank lines & comments, then prefix each pattern with its gitignore's path
        grep -Ev '^\s*(#|$)' "$gi" | while read -r pattern; do
            # if pattern is absolute (starts with /), drop the leading slash:
            if [[ $pattern == /* ]]; then
                pattern=${pattern#/}
            fi
            echo "$dir/$pattern"
        done
    done
done | sort -u > "$EXCLUDE_FILE"

borg init --encryption=repokey "$BORG_REPO" 2>/dev/null || true

borg create --verbose --stats --progress \
    --exclude-from "$EXCLUDE_FILE" \
    "$BORG_REPO::backup-{now:%Y-%m-%d_%H:%M:%S}" \
    "${SOURCES[@]}"

borg prune --verbose --list \
    "$BORG_REPO" \
    --glob-archives 'backup-*' \
    --keep-last 3
