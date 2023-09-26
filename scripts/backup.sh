#! /bin/bash
# Backup script
currentLoc=$(pwd)
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

Backup_Success() {
	if git status | grep -q 'Your branch is up to date'; then
		echo -e "${GREEN}Backup successful for ${PWD}${NC}"
	else
		echo -e "${RED}Backup failed for ${PWD}${NC}"
	fi
}

PROMPT_COMMAND="Backing up..."

# Backup BackupFolder
cd ~/Documents/BackupFolder
echo -e "${YELLOW}Backing up BackupFolder${NC}"
git add . 1> /dev/null
git commit -m "Backup" 1> /dev/null
git push 1> /dev/null 2> /dev/null

Backup_Success

# Backup Pictures
echo -e "${YELLOW}Backing up Pictures${NC}"
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
echo -e "${YELLOW}Backing up Installation_Script${NC}"
cd ~/Installation_Script/
git add . 1> /dev/null
git commit -m "Backup" 1> /dev/null
git push 1> /dev/null 2> /dev/null

Backup_Success

# Backup CS:GO settings
cp ~/.local/share/Steam/steamapps/common/Counter-Strike\ Global\ Offensive/csgo/cfg/practice.cfg ~/Documents/CSGO_Config/
cp ~/.local/share/Steam/steamapps/common/Counter-Strike\ Global\ Offensive/csgo/cfg/setup.cfg ~/Documents/CSGO_Config/
cp ~/.local/share/Steam/userdata/289706552/730/local/cfg/autoexec.cfg ~/Documents/CSGO_Config/
cp ~/.local/share/Steam/userdata/289706552/730/local/cfg/config.cfg ~/Documents/CSGO_Config/

echo -e "${YELLOW}Backing up CSGO_Config${NC}"
cd ~/Documents/CSGO_Config
git add . 1> /dev/null
git commit -m "Backup" 1> /dev/null
git push 1> /dev/null 2> /dev/null

Backup_Success

PROMPT_COMMAND="Completed backup."
echo "Completed backup."

