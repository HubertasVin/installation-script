#! /bin/bash
# Backup script

PROMPT_COMMAND="Backing up..."
echo "Backing up BackupFolder"
cd ~/Documents/BackupFolder
git add .
git commit -m "Backup"
git push

echo "Backing up Pictures"
cd ~/Pictures
git add .
git commit -m "Backup"
git push

cp ~/.config/nvim/init.vim ~/Documents/Installation_Script/user_config/init.vim

echo "Backing up Installation_Script"
cd ~/Installation_Script
git add .
git commit -m "Backup"
git push

echo "Backing up CSGO_Config"
cd ~/Documents/CSGO_Config
git add .
git commit -m "Backup"
git push

PROMPT_COMMAND="Completed backup."
echo "Completed backup."
