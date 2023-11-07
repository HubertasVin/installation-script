from datetime import datetime
import os
from pathlib import Path
import shutil
import tarfile
import argparse
from git import Repo
import paramiko
from scp import SCPClient

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
    parser.add_argument("--src", nargs='+', required=True, help="Source directories to be backedup")
    parser.add_argument("--dst", required=True, help="Destination in remote directory for backup")
    parser.add_argument("--ip", required=True, help="Remote IP")
    parser.add_argument("--user", required=True, help="Remote user")
    parser.add_argument("--password", required=True, help="Remote password")

    config = vars(parser.parse_args())

home_dir = os.path.expanduser('~')
dstBackupLoc="~/Backups"
tmpBackupLoc=home_dir + "/.temp/.backup"

def create_ssh_client(server, user, password):
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(server, username=user, password=password)
    return client

def get_git_remote(path):
    repo=Repo(path)
    remote=repo.config_reader().get_value("remote \"origin\"", "url")
    return remote

def generate_git_clone_script(script_loc, parent_path, remote):
    script_loc=Path(script_loc)
    path_to_script=os.path.join(script_loc, "gitClone.sh")
    parent_path=parent_path.replace(home_dir + "/.temp/.backup/", "")

    if not os.path.isfile(path_to_script):
        f=open(path_to_script, "w")
        f.write("#! /bin/bash\n\n")
    else:
        f=open(path_to_script, "a")
    
    f.write("git clone " + remote + " " + parent_path + "\n")

def add_move_to_git_clone_script(script_loc, src, dst):
    script_loc=Path(script_loc)
    path_to_script=os.path.join(script_loc, "gitClone.sh")

    f=open(path_to_script, "a")
    
    f.write("mv " + src + " " + dst + "\n")

def make_tarfile(output_filename, source_dirs):
    with tarfile.open(output_filename, "w:gz") as tar:
        for source_dir in source_dirs:
            # Get the base name of the source directory to use as the arcname
            arcname = os.path.basename(source_dir)
            tar.add(source_dir, arcname=arcname)

def remove_contents(folder):
    for filename in os.listdir(folder):
        file_path = os.path.join(folder, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print("Failed to delete %s\n%s" % (file_path, e))

os.system("~/Installation_Script/scripts/backup.sh")

if not os.path.exists(tmpBackupLoc):
    os.makedirs(tmpBackupLoc.absolute())
    os.makedirs(tmpBackupLoc)

if len(os.listdir(tmpBackupLoc)) != 0:
    remove_contents(tmpBackupLoc)

print("Starting backup to remote")

# Copy all the backup files to temporary folder
print(bcolors.OKBLUE + "Copying files to temporary backup folder" + bcolors.ENDC)
for src_dir in arguments.config["src"]:
    shutil.copytree(src_dir, tmpBackupLoc + "/" + os.path.basename(src_dir), dirs_exist_ok=True)

# Delete git projects and turn them into their own scripts to clone them
print(bcolors.OKBLUE + "Deleting git projects and turning them into their own scripts to clone them" + bcolors.ENDC)
# folder=home_dir + "/Documents"
f=open(".gitignoreremote")
gitignoreremote=f.read().splitlines()

if arguments.config["exclude_git"]:
    for root, subdirs, files in os.walk(tmpBackupLoc):
        for d in subdirs:
            if d == ".git" and get_git_remote(os.path.join(root, d)) not in gitignoreremote:
                generate_git_clone_script(tmpBackupLoc, root, get_git_remote(os.path.join(root, d)))
                shutil.rmtree(root)

for src_dir in arguments.config["src"]:
    add_move_to_git_clone_script(tmpBackupLoc, os.path.basename(src_dir), src_dir)

# Make tar file
print(bcolors.OKBLUE + "Compressing files" + bcolors.ENDC)
timeNow=datetime.now()
source_dirs = [tmpBackupLoc + "/" + dir for dir in os.listdir(tmpBackupLoc)]
make_tarfile(tmpBackupLoc + "/" + timeNow.strftime('%Y-%m-%d_%H-%M-%S') + ".tar.gz", source_dirs)

# SCPCLient takes a paramiko transport as an argument
try :
    ssh = create_ssh_client(arguments.config["ip"], arguments.config["user"], arguments.config["password"])
    scp = SCPClient(ssh.get_transport())
    print(bcolors.OKBLUE + "Copying backup to remote" + bcolors.ENDC)
    scp = SCPClient(ssh.get_transport())

    scp.put(tmpBackupLoc + "/" + timeNow.strftime('%Y-%m-%d_%H-%M-%S') + ".tar.gz", remote_path=arguments.config["dst"])

    # Close SSH and SCP client
    ssh.close()
    scp.close()

    # Delete temporary backup folder contents
    print(bcolors.OKBLUE + "Deleting temporary backup folder contents" + bcolors.ENDC)
    remove_contents(tmpBackupLoc)

    print(bcolors.OKGREEN + "Backup complete" + bcolors.ENDC)

except Exception as e:
    print(bcolors.FAIL + "Failed to connect to remote" + bcolors.ENDC)
    print("  " + e)

    # Delete temporary backup folder contents
    print(bcolors.OKBLUE + "Deleting temporary backup folder contents" + bcolors.ENDC)
    remove_contents(tmpBackupLoc)

    print(bcolors.FAIL + "Backup failed" + bcolors.ENDC)