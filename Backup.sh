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

PROMPT_COMMAND="Completed backup."