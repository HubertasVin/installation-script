#! /bin/bash
scriptLoc="$(cd $(dirname "$0"); pwd)"

set -e

#exec 2>/tmp/error

handle_error() {
    local ERROR=$(cat /tmp/error)
    echo $ERROR
    echo "$0 at line $1 with command $ERROR" >> /home/hubertas/tools/tool-errors.log
}

trap 'handle_error $LINENO' ERR

# Backup script
currentLoc=$(pwd)
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
OKBLUE='\033[94m'
OKGREEN='\033[92m'
FAIL='\033[91m'

Backup_Success() {
	if git status | grep -q 'Your branch is up to date'; then
		echo -e "${OKGREEN}Backup successful for ${PWD}${NC}"
	else
		echo -e "${FAIL}Backup failed for ${PWD}${NC}"
	fi
}

PROMPT_COMMAND="Backing up..."

echo -e "${OKBLUE}Backing up...${NC}"
echo -e "${OKBLUE}Copying config files${NC}"
# Copy polybar, qtile, rofi configs
cp -r ~/.config/polybar/* ~/Installation_Script/user_config/polybar 2>/dev/null || :
cp -r ~/.config/qtile/* ~/Installation_Script/user_config/qtile 2>/dev/null || :
cp -r ~/.config/rofi/* ~/Installation_Script/user_config/rofi 2>/dev/null || :
# Copy Nvim configuration
cp -r ~/.config/nvim/* ~/Installation_Script/user_config/nvim 2>/dev/null || :
cp -r ~/.vim/vimrcs/* ~/Installation_Script/user_config/vimrcs 2>/dev/null || :
# Copy inputrc
cp ~/.inputrc ~/Installation_Script/user_config/
# Copy TMUX configuration
cp ~/.tmux.conf ~/Installation_Script/user_config/template.tmux.conf 2>/dev/null || :
cp ~/.tmux.conf.local ~/Installation_Script/user_config/template.tmux.conf.local 2>/dev/null || :
sed -i 's/^tmux_conf_theme_colour_6=.*/tmux_conf_theme_colour_6="%COLORCODE"    # default/' ~/Installation_Script/user_config/template.tmux.conf.local
# Copy Terminator configuration
cp -r ~/.config/terminator/* ~/Installation_Script/user_config/terminator 2>/dev/null || :
# Copy GNOME settings
cd ~/Installation_Script/user_config
dconf dump / > saved_settings.dconf

echo "Starting backup to git"

cd "$scriptLoc"
while read p || [[ -n $p ]];
do
	echo -e "${OKBLUE}Backing up ${p}${NC}"
	cd $p
	git add . 1> /dev/null
	git commit -m "Backup"
	git push
	Backup_Success
done < gitlocations.txt

echo -e "${OKGREEN}Backup complete${NC}"
PROMPT_COMMAND="Completed backup."

