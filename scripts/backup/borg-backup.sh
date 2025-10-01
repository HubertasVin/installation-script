#!/usr/bin/env bash

set -e

touch /tmp/error

handle_error() {
    local ERROR=$(cat /tmp/error)
    echo $ERROR
    echo $ERROR >> "$TEMP_OUTPUT"
}

trap 'echo "Error at line $LINENO with command: $BASH_COMMAND" > /tmp/error && handle_error' ERR

print_console() {
    echo -e "$1"
    echo "$1" >> "$TEMP_OUTPUT"
}

print_git_status() {
    output="$(git status --short | awk '
        {
            if ($1 == "M") printf "(M) %s, ", substr($0, index($0, $2)); # Modified
            else if ($1 == "A") printf "(A) %s, ", substr($0, index($0, $2)); # Added
            else if ($1 == "D") printf "(D) %s, ", substr($0, index($0, $2)); # Deleted
            else if ($1 == "??") printf "(A) %s, ", substr($0, index($0, $2)); # Untracked
        }
    ' | sed 's/, $/\n\n/')"

    if [[ "$output" != "" ]]; then
        print_console "   ${CYAN}Here are the changes that are being commited:${NC}"
        print_console "   $output"
        print_console ""
    fi
}

backup_success() {
    if git status | grep -q 'Your branch is up to date'; then
        print_console "   ${OKGREEN}Backup successful for ${PWD}${NC}"
    else
        print_console "   ${FAIL}Backup failed for ${PWD}${NC}"
    fi
}

commit_changes_remote() {
    print_console " > ${OKBLUE}Backing up $1${NC}"
    print_git_status

    git add .
    if ! git diff-index --quiet HEAD --; then
        print_console "   ${YELLOW}Commiting updates to $1${NC}"
        git commit -am "Backup $(date +'%Y-%m-%d %H:%M:%S')" | sed 's/^/   /'
        git push origin $(git rev-parse --abbrev-ref HEAD) > /dev/null 2>&1 | sed 's/^/   /'
        backup_success "$TEMP_OUTPUT"
    else
        if git status | grep -q 'Your branch is up to date'; then
            print_console "   ${OKGREEN}The backup is up to date for ${PWD}${NC}"
        else
            print_console "   ${FAIL}Something went wrong. there is nothing to commit, but the branch is not up to date for ${PWD}${NC}"
            git status | sed 's/^/   /' >> "$TEMP_OUTPUT"
        fi
    fi
    print_console ""
}

copy_config_files() {
    currentLoc=$(pwd)
    CYAN='\033[0;96m'
    YELLOW='\033[0;93m'
    GREEN='\033[0;92m'
    RED='\033[0;91m'
    OKBLUE='\033[1;34m'
    OKGREEN='\033[1;32m'
    FAIL='\033[1;31m'
    NC='\033[0m'            # No Color

    TEMP_OUTPUT=$(mktemp)
    TEMP_ERROR=$(mktemp)

    print_console "${OKBLUE}Backing up...${NC}"
    print_console "${OKBLUE}Copying config files...${NC}"

    # Copy inputrc
    cp ~/.inputrc ~/dotfiles/
    # Copy TMUX configuration
    cp ~/.tmux.conf ~/dotfiles/.tmux.conf 2>/dev/null || :
    cp ~/.tmux.conf.local ~/dotfiles/.tmux.conf.local 2>/dev/null || :
    sed -i 's/^tmux_conf_theme_colour_0=.*/tmux_conf_theme_colour_0="%COLORCODE"    # default/' ~/dotfiles/.tmux.conf.local
    # Copy Ranger configuration
    cp ~/.config/ranger/rc.conf ~/dotfiles/ranger/ 2>/dev/null || :
    cp ~/.config/ranger/rifle.conf ~/dotfiles/ranger/ 2>/dev/null || :
    # Copy Terminator configuration
    cp ~/.config/alacritty/alacritty.toml ~/dotfiles/ 2>/dev/null || :
    # Copy GNOME settings
    dconf dump / > ~/dotfiles/saved_settings.dconf

    cd ~/dotfiles
    commit_changes_remote "~/dotfiles"
}

perform_backup() {
    export BORG_REPO="borg:~/backups"
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    SOURCES=(
        "$HOME/Documents/backup-folder"
        "$HOME/Pictures"
    )

    copy_config_files

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

    print_console "${OKGREEN}Backup complete${NC}"

    echo "Press any key to continue..."
    read -n 1 -s
}

perform_backup
