import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import paramiko
import subprocess
from whaaaaat import prompt, print_json, Separator

class bcolors:
    HEADER='\033[95m'
    OKBLUE='\033[94m'
    OKCYAN='\033[96m'
    OKGREEN='\033[92m'
    WARNING='\033[93m'
    FAIL='\033[91m'
    ENDC='\033[0m'
    BOLD='\033[1m'
    UNDERLINE = '\033[4m'

class arguments:
    parser = argparse.ArgumentParser(description="This Python program is designed to facilitate the backup and transfer of files from a local source to a remote destination using Secure Copy Protocol (SCP) over SSH. The program includes features for archiving, excluding Git repositories, and copying files to a remote server. It is primarily intended for use on a Linux system.",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-g", "--exclude-git", action="store_true", help="Exclude Git repositories from backup")
    parser.add_argument("--src", required=True, help="Directory of the backups")
    parser.add_argument("--ip", required=True, help="Remote IP")
    parser.add_argument("--user", required=True, help="Remote user")
    parser.add_argument("--password", required=True, help="Remote password")

    config = vars(parser.parse_args())

home_dir = os.path.expanduser('~')
dstBackupLoc="~/Backups"

def create_ssh_client(server, user, password):
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(server, username=user, password=password)
    return client

def get_remote_backup_files(client):
    stdin, stdout, stderr = client.exec_command(
        'find ' + arguments.config["src"] + '/ -name "*.tar.gz"'
    )
    files = stdout.readlines()
    files = [file.strip() for file in files]
    return files

def format_date_names(files):
    for i in range(len(files)):
        files[i] = os.path.basename(files[i])[0:-7]
        files[i] = datetime.strptime(files[i], "%Y-%m-%d_%H-%M-%S")
        files[i] = files[i].strftime("%Y-%m-%d %H:%M:%S")
    return files

def convert_back_to_date_names(file_name):
    file_name = datetime.strptime(file_name, "%Y-%m-%d %H:%M:%S")
    file_name = file_name.strftime("%Y-%m-%d_%H-%M-%S.tar.gz")
    return file_name

ssh = create_ssh_client(arguments.config["ip"], arguments.config["user"], arguments.config["password"])
files = get_remote_backup_files(ssh)
original_files = files.copy()

questions = [
    {
        "type": "list",
        "name": "backup",
        "message": "Which backup would you like to restore?",
        "choices": sorted(format_date_names(files), reverse=True)
    },
    {
        "type": "input",
        "name": "dst",
        "message": "Where would you like to restore the backup?",
        "default": home_dir
    }
]

sftp = ssh.open_sftp()
answers = prompt(questions)
backup_path = Path(files[0])
remote_file_path = os.path.dirname(original_files[0]) + "/" + convert_back_to_date_names(answers["backup"])
local_file_path = answers["dst"] + "/backup.tar.gz"

print(bcolors.OKBLUE + "Downloading backup" + bcolors.ENDC)
sftp.get(remote_file_path, local_file_path)
sftp.close()
ssh.close()

print(bcolors.OKBLUE + "Extracting backup" + bcolors.ENDC)
subprocess.run(["tar", "-xzf", local_file_path, "-C", answers["dst"]])

print(bcolors.OKBLUE + "Cloning Git repositories" + bcolors.ENDC)
os.chdir(answers["dst"])
subprocess.run(["chmod", "+x", os.path.dirname(local_file_path) + "/gitClone.sh"], cwd=answers["dst"])
subprocess.run([os.path.dirname(local_file_path) + "/gitClone.sh"], cwd=answers["dst"])