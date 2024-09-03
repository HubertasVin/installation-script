#! /bin/bash
SCRIPT_LOC="$(pwd)"

set -e

touch /tmp/error

handle_error() {
    local ERROR=$(cat /tmp/error)
    echo $ERROR
    echo "$0 at line $1 with command $ERROR" >> /home/hubertas/tools/tool-errors.log
    echo "$0 at line $1 with command $ERROR" >> "$TEMP_OUTPUT"
}

backup_success() {
	  if git status | grep -q 'Your branch is up to date'; then
        echo -e "${OKGREEN}Backup successful for ${PWD}${NC}"
        echo "${OKGREEN}Backup successful for ${PWD}${NC}" >> "$1"
	  else
	      echo -e "${FAIL}Backup failed for ${PWD}${NC}"
        echo "${FAIL}Backup failed for ${PWD}${NC}" >> "$1"
	  fi
}

backup_commands() {
    currentLoc=$(pwd)
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m'            # No Color
    OKBLUE='\033[94m'
    OKGREEN='\033[92m'
    FAIL='\033[91m'

    TEMP_OUTPUT=$(mktemp)
    TEMP_ERROR=$(mktemp)

    trap 'handle_error $LINENO $TEMP_ERROR' ERR

    echo -e "${OKBLUE}Backing up...${NC}"
    echo "${OKBLUE}Backing up...${NC}" >> "$TEMP_OUTPUT"
    echo -e "${OKBLUE}Copying config files${NC}"
    echo "${OKBLUE}Copying config files${NC}" >> "$TEMP_OUTPUT"
    PROMPT_COMMAND="Backing up..."

    # Copy polybar, qtile, rofi configs
    cp -r ~/.config/polybar/* ~/dotfiles/polybar 2>/dev/null || :
    cp -r ~/.config/qtile/* ~/dotfiles/qtile 2>/dev/null || :
    cp ~/.local/share/rofi/themes/rounded-nord-dark.rasi ~/dotfiles/rofi/themes 2>/dev/null || :
    cp ~/.local/bin/rofi-power-menu ~/dotfiles/rofi/ 2>/dev/null || :
    # Copy i3 and i3blocks configs
    cp -r ~/.config/i3/ ~/dotfiles/ 2>/dev/null || :
    cp -r ~/.config/i3blocks/ ~/dotfiles/ 2>/dev/null || :
    # Copy Nvim config
    cp -rf ~/.config/nvim/lua/* ~/dotfiles/nvim 2>/dev/null || :
    # Copy inputrc
    cp ~/.inputrc ~/dotfiles/
    # Copy TMUX configuration
    cp ~/.tmux.conf ~/dotfiles/template.tmux.conf 2>/dev/null || :
    cp ~/.tmux.conf.local ~/dotfiles/template.tmux.conf.local 2>/dev/null || :
    sed -i 's/^tmux_conf_theme_colour_0=.*/tmux_conf_theme_colour_0="%COLORCODE"    # default/' ~/dotfiles/template.tmux.conf.local
    # Copy Terminator configuration
    cp -r ~/.config/terminator/* ~/dotfiles/terminator 2>/dev/null || :
    # Copy GNOME settings
    dconf dump / > ~/dotfiles/saved_settings.dconf

    echo "Starting backup to git"
    echo "Starting backup to git" >> "$TEMP_OUTPUT"

    while read p || [[ -n $p ]];
    do
        cd $p
        pwd
        echo -e "${OKBLUE}Backing up ${p}${NC}"
        echo "${OKBLUE}Backing up ${p}${NC}" >> "$TEMP_OUTPUT"
        git add . 1> /dev/null
        if ! git diff-index --quiet HEAD --; then
            git commit -m "Backup"
            git push
            backup_success "$TEMP_OUTPUT"
        else
            if git status | grep -q 'Your branch is up to date'; then
                echo -e "${OKGREEN}The backup is up to date for ${PWD}${NC}"
                echo "${OKGREEN}The backup is up to date for ${PWD}${NC}" >> "$1"
            else
                echo -e "${FAIL}Something went wrong. there is nothing to commit, but the branch is not up to date for ${PWD}${NC}"
                echo "${FAIL}Something went wrong. there is nothing to commit, but the branch is not up to date for ${PWD}${NC}" >> "$1"
                git status >> "$1"
            fi
        fi
        tput clear
        echo -e "$(cat "$TEMP_OUTPUT")"
    done < gitlocations.txt

    echo -e "${OKGREEN}Backup complete${NC}"
    echo "${OKGREEN}Backup complete${NC}" >> "$TEMP_OUTPUT"
    PROMPT_COMMAND="Completed backup."

    echo "Press any key to continue..."
    read -n 1 -s
}

HANDLE_ERROR_SERIALIZED=$(declare -f handle_error)
BACKUP_SUCCESS_SERIALIZED=$(declare -f backup_success)
BACKUP_COMMANDS_SERIALIZED=$(declare -f backup_commands)

tmux new-session -d -s backup-session bash -c "$BACKUP_COMMANDS_SERIALIZED; $HANDLE_ERROR_SERIALIZED; $BACKUP_SUCCESS_SERIALIZED; cd /home/hubertas/tools/backup; backup_commands"
tmux set-option -t backup-session status off
TMUX='' tmux attach -t backup-session > /dev/null

