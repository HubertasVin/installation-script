import os
import paramiko
import argparse

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

home_dir = os.path.expanduser('~')

def add_git_to_backup(input):
    failed = False
    with open(home_dir + "/tools/backup/" + "gitlocations.txt", "a") as f:
        for i in range(len(input)):
            if os.path.exists(input[i]):
                f.write(input[i] + "\n")
                print(bcolors.OKGREEN + "Path " + input[i] + " added to backupable git projects list" + bcolors.ENDC)
            else:
                print(bcolors.FAIL + "Path " + input[i] + " does not exist" + bcolors.ENDC)
                failed = True
        f.close()
    return failed

class arguments:
    parser = argparse.ArgumentParser(
        description="This Python program is designed to facilitate the backup and transfer of files from a local source to a remote destination using Secure Copy Protocol (SCP) over SSH. The program includes features for archiving, excluding Git repositories, and copying files to a remote server. It is primarily intended for use on a Linux system.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--add-git", nargs= '+', help="Exclude Git repositories from backup")

    args = parser.parse_args()

    if args.add_git:
        if add_git_to_backup(args.add_git):
            print(bcolors.FAIL + "One or more paths failed to be added to the backupable git projects list" + bcolors.ENDC)
        else:
            print(bcolors.OKGREEN + "All paths added to backupable git projects list" + bcolors.ENDC)