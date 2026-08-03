#!/usr/bin/env bash
shortstat=$(git diff --shortstat 2>/dev/null)
untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

awk -v S="$shortstat" -v U="$untracked" '
BEGIN {
    files = added = deleted = 0

    if (match(S, /([0-9]+) insertion/, m))         added   = m[1] + 0
    if (match(S, /([0-9]+) deletion/, m))          deleted = m[1] + 0
    if (match(S, /([0-9]+) file[s]? changed/, m))  files   = m[1] + 0

    printf "export POSH_GIT_TRACKED=%d\n",   files
    printf "export POSH_GIT_UNTRACKED=%d\n", U + 0
    printf "export POSH_GIT_ADDED=%d\n",     added
    printf "export POSH_GIT_DELETED=%d\n",   deleted
}'

