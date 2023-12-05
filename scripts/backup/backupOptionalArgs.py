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
    
def add_git_to_backup(input):
    with open("gitlocations.txt", "a") as f:
        for i in range(len(input)):
            f.write(input[i] + "\n")
        f.close()

class arguments:
    parser = argparse.ArgumentParser(
        description="This Python program is designed to facilitate the backup and transfer of files from a local source to a remote destination using Secure Copy Protocol (SCP) over SSH. The program includes features for archiving, excluding Git repositories, and copying files to a remote server. It is primarily intended for use on a Linux system.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--add-git", nargs= '+', help="Exclude Git repositories from backup")

    args = parser.parse_args()

    if args.add_git:
        add_git_to_backup(args.add_git)
        print(bcolors.OKGREEN + "Git repositories added to backupable git projects list" + bcolors.ENDC)