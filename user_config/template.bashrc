# Changing bash history size
export HISTSIZE=10000
export HISTFILESIZE=10000

# Changing default editor to nvim
export VISUAL=nvim
export EDITOR=nvim

# Disable Starship warnings
export STARSHIP_LOG=error

# Configure bash auto-completion
bind 'set show-all-if-ambiguous on'
bind 'TAB:menu-complete'

# Adding short path names
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
alias time="env time"

# Create new directory and change the current directory to it
mkcd() {
    if [ -d "$1" ]; then
        echo "Error: Directory '$1' already exists."
    else
        mkdir "$1" && cd "$1"
    fi
}

# Start Starship
function set_win_title() {
    local cmd=" ($@)"
    if [[ "$cmd" == " (starship_precmd)" || "$cmd" == " ()" ]]
    then
        cmd=""
    fi
    if [[ $PWD == $HOME ]]
    then
        if [[ $SSH_TTY ]]
        then
        echo -ne "\033]0;@ $HOSTNAME ~$cmd\a" < /dev/null
        else
        echo -ne "\033]0;~$cmd\a" < /dev/null
        fi
    else
        BASEPWD=$(basename "$PWD")
        if [[ $SSH_TTY ]]
        then
        echo -ne "\033]0;$BASEPWD @ $HOSTNAME $cmd\a" < /dev/null
        else
        echo -ne "\033]0;$BASEPWD $cmd\a" < /dev/null
        fi
    fi
}
starship_precmd_user_func="set_win_title"
eval "$(starship init bash)"
# trap "$(trap -p DEBUG |  awk -F"'" '{print $2}');set_win_title \${BASH_COMMAND}" DEBUG

# Set Ghcup environment variables
 [ -f "/home/hubertas/.ghcup/env" ] && source "/home/hubertas/.ghcup/env"


# Set Rust environment variables
. "$HOME/.cargo/env"

# This must be at the end to start Sdkman
 export SDKMAN_DIR="$HOME/.sdkman"
 [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
