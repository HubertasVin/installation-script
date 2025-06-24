#!/usr/bin/env bash
set -euo pipefail

STALE_DAYS=14   # move to .trash after this many days
TRASH_DAYS=90   # delete from .trash after this many days

for home in /home/* /root; do
    download_dir="$home/Downloads"
    [[ -d $download_dir ]] || continue

    trash_dir="$download_dir/.trash"
    mkdir -p "$trash_dir"

    # stale top-level files
    find "$download_dir" -maxdepth 1 -mindepth 1 -type f \
        ! \( -path "$trash_dir" -o -path "$trash_dir/*" \) \
        -atime +"$STALE_DAYS" -mtime +"$STALE_DAYS" \
        -exec mv -n -t "$trash_dir" {} +

    # stale top-level dirs
    while IFS= read -r -d '' dir; do
        if find "$dir" -type f -atime +"$STALE_DAYS" -mtime +"$STALE_DAYS" -print -quit | grep -q .; then
            mv -n "$dir" "$trash_dir"
        fi
        done < <(find "$download_dir" -maxdepth 1 -mindepth 1 -type d \
        ! \( -path "$trash_dir" -o -path "$trash_dir/*" \) -print0)

    # purge old trash
    find "$trash_dir" -depth -mindepth 1 -mtime +"$TRASH_DAYS" -exec rm -rf {} +
done
