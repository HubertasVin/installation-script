#! /bin/bash
# Backup script
currentLoc=$(pwd)

PROMPT_COMMAND="Backing up..."

# Backup BackupFolder
echo "Backing up BackupFolder"
cd ~/Documents/BackupFolder
git add .
git commit -m "Backup"
git push

# Backup Pictures
echo "Backing up Pictures"
cd ~/Pictures
git add .
git commit -m "Backup"
git push

# Backup nvim settings
cp ~/.config/nvim/init.vim ~/Documents/Installation_Script/user_config/init.vim

# Backup GNOME settings
cd $currentLoc/user_config
dconf dump / > saved_settings.conf

# Backup installation script
echo "Backing up Installation_Script"
cd $currentLoc
git add .
git commit -m "Backup"
git push

# Backup CS:GO settings
cp ~/.local/share/Steam/steamapps/common/Counter-Strike\ Global\ Offensive/csgo/cfg/practice.cfg ~/Documents/CSGO_Config/
cp ~/.local/share/Steam/steamapps/common/Counter-Strike\ Global\ Offensive/csgo/cfg/setup.cfg ~/Documents/CSGO_Config/
cp ~/.local/share/Steam/userdata/289706552/730/local/cfg/autoexec.cfg ~/Documents/CSGO_Config/
cp ~/.local/share/Steam/userdata/289706552/730/local/cfg/config.cfg ~/Documents/CSGO_Config/

echo "Backing up CSGO_Config"
cd ~/Documents/CSGO_Config
git add .
git commit -m "Backup"
git push

PROMPT_COMMAND="Completed backup."
echo "Completed backup."

