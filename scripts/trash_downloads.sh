#!/usr/bin/env bash
set -euo pipefail

# thresholds (in days)
STALE_DAYS=14
TRASH_DAYS=90

# for every home dir under /home plus /root
for HOMEDIR in /home/* /root; do
    DOWNLOAD_DIR="$HOMEDIR/Downloads"
    TRASH_DIR="$DOWNLOAD_DIR/.trash"

    # skip if no Downloads folder
    [[ -d "$DOWNLOAD_DIR" ]] || continue

    # ensure .trash exists
    mkdir -p "$TRASH_DIR"

    # move items not accessed AND not modified in the last $STALE_DAYS days
    find "$DOWNLOAD_DIR" \
        -maxdepth 1 -mindepth 1 \
        ! -path "$TRASH_DIR" \
        -atime +$STALE_DAYS -mtime +$STALE_DAYS \
        -print0 | \
    while IFS= read -r -d '' ITEM; do
        mv -n "$ITEM" "$TRASH_DIR"/
    done

    # remove items in .trash older than $TRASH_DAYS days
    find "$TRASH_DIR" \
        -mindepth 1 \
        -mtime +$TRASH_DAYS \
        -exec rm -rf {} +
done

