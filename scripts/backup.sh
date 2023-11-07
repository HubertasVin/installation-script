#! /bin/bash
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
echo "Starting backup to git"

# Backup BackupFolder
cd ~/Documents/BackupFolder
echo -e "${OKBLUE}Backing up BackupFolder${NC}"
git add . 1> /dev/null
git commit -m "Backup" 1> /dev/null
git push 1> /dev/null 2> /dev/null

Backup_Success

# Backup Pictures
echo -e "${OKBLUE}Backing up Pictures${NC}"
cd ~/Pictures
git add . 1> /dev/null
git commit -m "Backup" 1> /dev/null
git push 1> /dev/null 2> /dev/null

Backup_Success

# Backup nvim settings
cp ~/.config/nvim/init.lua ~/Installation_Script/user_config/init.lua

# backup GNOME settings
cd ~/Installation_Script/user_config
dconf dump / > saved_settings.dconf

# Backup installation script
echo -e "${OKBLUE}Backing up Installation_Script${NC}"
cd ~/Installation_Script/
sudo cp -r ~/.config/polybar/* ~/Installation_Script/user_config/polybar
sudo cp -r ~/.config/qtile/* ~/Installation_Script/user_config/qtile
sudo cp -r ~/.config/rofi/* ~/Installation_Script/user_config/rofi
cp ~/.inputrc ~/Installation_Script/user_config/
git add . 1> /dev/null
git commit -m "Backup" 1> /dev/null
git push 1> /dev/null 2> /dev/null

Backup_Success

<<CSGO_Config
# Backup CS:GO settings
cp ~/.local/share/Steam/steamapps/common/Counter-Strike\ Global\ Offensive/csgo/cfg/practice.cfg ~/Documents/CSGO_Config/
cp ~/.local/share/Steam/steamapps/common/Counter-Strike\ Global\ Offensive/csgo/cfg/setup.cfg ~/Documents/CSGO_Config/
cp ~/.local/share/Steam/userdata/289706552/730/local/cfg/autoexec.cfg ~/Documents/CSGO_Config/
cp ~/.local/share/Steam/userdata/289706552/730/local/cfg/config.cfg ~/Documents/CSGO_Config/

echo -e "${OKBLUE}BBacking up CSGO_Config${NC}"
cd ~/Documents/CSGO_Config
git add . 1> /dev/null
git commit -m "Backup" 1> /dev/null
git push 1> /dev/null 2> /dev/null

Backup_Success
CSGO_Config

PROMPT_COMMAND="Completed backup."
