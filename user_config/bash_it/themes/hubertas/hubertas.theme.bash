# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
BOLD="\e[1m"

# Function to build shortened directory path
function build_formatted_dir() {
    local FORMATTED_DIR
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local GIT_TOPLEVEL=$(git rev-parse --show-toplevel)
        local GIT_REPO_NAME=$(basename "$GIT_TOPLEVEL")
        local RELATIVE_PATH=$(realpath --relative-to="$GIT_TOPLEVEL" "$(pwd)")

        # Handle case where relative path is "."
        if [ "$RELATIVE_PATH" == "." ]; then
            FORMATTED_DIR="$GIT_REPO_NAME"
        else
            FORMATTED_DIR="$GIT_REPO_NAME/$RELATIVE_PATH"
        fi
    else
        # Replace home directory with ~
        FORMATTED_DIR=$(pwd | sed -e "s|$HOME|~|")
    fi
    echo "$FORMATTED_DIR"
}

# Function to check if the directory is read-only
function build_read_only() {
    local READ_ONLY=""
    if [ ! -w "$(pwd)" ]; then
        READ_ONLY=" 𝑟𝑒𝑎𝑑 𝑜𝑛𝑙𝑦"
    fi
    echo "$READ_ONLY"
}

# Function to get Git information
function build_git_info() {
    local GIT_INFO=""
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local GIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null)

        # Get the added and removed lines
        local GIT_STATS=$(git diff --shortstat)
        local GIT_ADDED=$(echo $GIT_STATS | grep -oP '\d+(?= insertion)')
        local GIT_REMOVED=$(echo $GIT_STATS | grep -oP '\d+(?= deletion)')

        # Default to 0 if no changes are found
        GIT_ADDED=${GIT_ADDED:-0}
        GIT_REMOVED=${GIT_REMOVED:-0}

        GIT_INFO=" ⎇ $GIT_BRANCH"
        if [ "$GIT_ADDED" -gt 0 ]; then
            GIT_INFO+=" ${GREEN}+$GIT_ADDED${ENDCOLOR}"
        fi
        if [ "$GIT_REMOVED" -gt 0 ]; then
            GIT_INFO+=" ${RED}-$GIT_REMOVED${ENDCOLOR}"
        fi
    fi
    echo "$GIT_INFO"
}

# Function to calculate command duration
function build_cmd_duration() {
    local CMD_DURATION=""
    if [ -n "$TIMER" ]; then
        local DURATION=$(($(date +%s) - TIMER))
        if [ "$DURATION" -ge 2 ]; then
            CMD_DURATION=" ${GREEN}•${ENDCOLOR} took ${YELLOW}${DURATION}s${ENDCOLOR}"
        fi
        unset TIMER
    fi
    echo "$CMD_DURATION"
}

# Custom prompt function
function _custom_prompt_command() {
    local EXIT="$?" # Get the exit status of the last command

    local FORMATTED_DIR=$(build_formatted_dir)
    local READ_ONLY=$(build_read_only)
    local GIT_INFO=$(build_git_info)
    # local CMD_DURATION=$(build_cmd_duration)

    # Set the prompt character based on the exit status of the last command
    local PROMPT_CHAR=""
    if [ $EXIT -eq 0 ]; then
        PROMPT_CHAR="\[\e[38;5;32m\]❯${ENDCOLOR}"  # success
    else
        PROMPT_CHAR="\[\e[38;5;196m\]✗${ENDCOLOR}"  # error
    fi

    # Set the prompt
    PS1="${RED}$FORMATTED_DIR${BOLD}$READ_ONLY${ENDCOLOR}$GIT_INFO\n$PROMPT_CHAR "
}

# Hook the prompt command
PROMPT_COMMAND="_custom_prompt_command"

# Start the timer before each command
function preexec_invoke_cmd() {
    TIMER=$(date +%s)
}

# Trap DEBUG signal to measure command execution time
trap 'preexec_invoke_cmd' DEBUG
