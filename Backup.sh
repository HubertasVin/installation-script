#! /bin/bash
# Backup script

PROMPT_COMMAND="Backing up..."
cd ~/Documents/BackupFolder
git add .
git commit -m "Backup"
git push

cd ~/Pictures
git add .
git commit -m "Backup"
git push

cp ~/.config/nvim/init.vim ~/Documents/Installation_Script/user_config/init.vim

cd ~/Install_Script
git add .
git commit -m "Backup"
git push

PROMPT_COMMAND="Completed backup."
