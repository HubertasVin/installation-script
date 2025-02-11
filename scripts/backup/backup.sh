#! /bin/bash
SCRIPT_LOC="$(pwd)"

set -e

touch /tmp/error

handle_error() {
    local ERROR=$(cat /tmp/error)
    echo $ERROR
    echo $ERROR >> "$TEMP_OUTPUT"
}

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

backup_commands() {
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

    trap 'echo "Error at line $LINENO with command: $BASH_COMMAND" > /tmp/error && handle_error' ERR

    print_console "${OKBLUE}Backing up...${NC}"
    print_console "${OKBLUE}Copying config files...${NC}"

    # Copy polybar, qtile, rofi configs
    cp -r ~/.config/polybar/* ~/dotfiles/polybar 2>/dev/null || :
    cp -r ~/.config/qtile/* ~/dotfiles/qtile 2>/dev/null || :
    cp ~/.local/share/rofi/themes/rounded-nord-dark.rasi ~/dotfiles/rofi/themes 2>/dev/null || :
    cp ~/.local/bin/rofi-power-menu ~/dotfiles/rofi/ 2>/dev/null || :
    # Copy i3 and i3blocks configs
    cp -r ~/.config/i3/ ~/dotfiles/ 2>/dev/null || :
    cp -r ~/.config/i3blocks/ ~/dotfiles/ 2>/dev/null || :
    # Copy Sway config
    cp -r ~/.config/sway/ ~/dotfiles/ 2>/dev/null || :
    # Copy Nvim config
    cp -rf ~/.config/nvim/lua/* ~/dotfiles/nvim/lua 2>/dev/null || :
    cp -rf ~/.config/nvim/init.lua ~/dotfiles/nvim/init.lua 2>/dev/null || :
    # Copy inputrc
    cp ~/.inputrc ~/dotfiles/
    # Copy TMUX configuration
    cp ~/.tmux.conf ~/dotfiles/.tmux.conf 2>/dev/null || :
    cp ~/.tmux.conf.local ~/dotfiles/.tmux.conf.local 2>/dev/null || :
    sed -i 's/^tmux_conf_theme_colour_0=.*/tmux_conf_theme_colour_0="%COLORCODE"    # default/' ~/dotfiles/.tmux.conf.local
    # Copy fish config
    cp ~/.config/fish/config.fish ~/dotfiles/config.fish 2>/dev/null || :
    # Copy Ranger configuration
    cp ~/.config/ranger/rc.conf ~/dotfiles/ranger/ 2>/dev/null || :
    cp ~/.config/ranger/rifle.conf ~/dotfiles/ranger/ 2>/dev/null || :
    # Copy Terminator configuration
    cp -r ~/.config/terminator/* ~/dotfiles/terminator 2>/dev/null || :
    cp ~/.config/alacritty/alacritty.toml ~/dotfiles/ 2>/dev/null || :
    # Copy GNOME settings
    dconf dump / > ~/dotfiles/saved_settings.dconf

    print_console "${OKBLUE}Starting backup to git...${NC}"

    while read p || [[ -n $p ]];
    do
        cd $p
        print_console " > ${OKBLUE}Backing up ${p}${NC}"
        print_git_status

        git add .
        if ! git diff-index --quiet HEAD --; then
            print_console "   ${YELLOW}Commiting updates to remote${NC}"
            git commit -am "Backup" | sed 's/^/   /'
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
        # tput clear
        # echo -e "$(cat "$TEMP_OUTPUT")"
    done < gitlocations.txt

    print_console "${OKGREEN}Backup complete${NC}"

    echo "Press any key to continue..."
    read -n 1 -s
}

PRINT_GIT_STATUS_SERIALIZED=$(declare -f print_git_status)
HANDLE_ERROR_SERIALIZED=$(declare -f handle_error)
BACKUP_SUCCESS_SERIALIZED=$(declare -f backup_success)
BACKUP_COMMANDS_SERIALIZED=$(declare -f backup_commands)
PRINT_CONSOLE_SERIALIZED=$(declare -f print_console)

tmux new-session -d -s backup-session bash -c "$PRINT_GIT_STATUS_SERIALIZED; $HANDLE_ERROR_SERIALIZED; $BACKUP_SUCCESS_SERIALIZED; $BACKUP_COMMANDS_SERIALIZED; $PRINT_CONSOLE_SERIALIZED; cd /home/hubertas/tools/backup; backup_commands"
tmux set-option -t backup-session status off
TMUX='' tmux attach -t backup-session > /dev/null

