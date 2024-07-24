# Changing bash history size
export HISTSIZE=10000
export HISTFILESIZE=10000
# Changing default editor to nvim
export VISUAL=nvim
export EDITOR=nvim

# Configure bash auto-completion
bind 'set show-all-if-ambiguous on'
bind 'TAB:menu-complete'

# Add variables
INSTSCRIPT=/home/hubertas/Installation_Script

# Set the aliases
alias rm='rm -i'
alias clr='clear'
alias qtile_conf="cd ~/.config/qtile"
alias qtile_log="cd ~/.local/share/qtile"
alias sound_reload="systemctl --user restart pipewire.service"
alias sound_reset="systemctl --user unmask pulseaudio; systemctl --user --now disable pipewire.socket; systemctl --user --now enable pulseaudio.service pulseaudio.socket"
alias backupDevice="python ~/Installation_Script/scripts/backup/backupRemote.py"
alias xr144="xrandr --output DP-1 --mode 1920x1080 --rate 144"
alias prime-run="__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia"
alias ..="cd .."
alias sshopi="ssh orangepi@10.15.5.176"
alias ranger='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"'

# Create new directory and change the current directory to it
mkcd() {
    if [ -d "$1" ]; then
        echo "Error: Directory '$1' already exists."
    else
        mkdir "$1" && cd "$1"
    fi
}

# Set Ghcup environment variables
 [ -f "/home/hubertas/.ghcup/env" ] && source "/home/hubertas/.ghcup/env"
# Set Rust environment variables
. "$HOME/.cargo/env"
# Start Sdkman (this must be at the end)
 export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Start ble.sh
source ~/.local/share/blesh/ble.sh

# Path to the bash it configuration
export BASH_IT="/home/hubertas/.bash_it"

# Lock and Load a custom theme file.
export BASH_IT_THEME='hubertas'

# Don't check mail when opening terminal.
unset MAILCHECK

# Change this to your console based IRC client of choice.
export IRC_CLIENT='irssi'

# Set this to the command you use for todo.txt-cli
export TODO="t"

# Set this to false to turn off version control status checking within the prompt for all themes
export SCM_CHECK=true

# Load Bash It
source "$BASH_IT"/bash_it.sh
