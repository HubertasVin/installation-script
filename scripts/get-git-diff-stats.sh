#!/usr/bin/env bash

stats=$(git diff --shortstat 2>/dev/null)

awk -v B="$(tput bold)" \
	-v TF="$(tput setaf 142)" \
	-v AF="$(tput setaf 70)"  \
	-v DF="$(tput setaf 124)" \
	-v UF="$(tput setaf 205)" \
	-v R="$(tput sgr0)" \
	-v U="$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')" \
	'BEGIN {
    split("'"$stats"'", a)
    files    = (a[1] + 0) + (U + 0)
    tracked  = (a[1] + 0)
    add      = (a[4] + 0)
    del      = (a[6] + 0)

    if (files > 0) {
        if (tracked > 0)  printf " %s%s✓%d%s", B, TF, tracked, R
        if (U > 0)        printf " %s%s?%d%s", B, UF, U, R
        if (add > 0)      printf " %s%s↑%d%s", B, AF, add, R
        if (del > 0)      printf " %s%s↓%d%s", B, DF, del, R
    }
}'
