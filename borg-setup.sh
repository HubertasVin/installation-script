#!/usr/bin/env bash
set -e

# 1) PROMPT FOR AND PERSIST THE VAULT PASSPHRASE
if [[ -z "${BORG_PASSPHRASE:-}" ]]; then
	if [[ -n "${BASH_VERSION-}" ]]; then
		read -s -p "Enter Borg repo passphrase: " _borg_pass
		echo
	elif [[ -n "${ZSH_VERSION-}" ]]; then
		read -s "?Enter Borg repo passphrase: " _borg_pass
		echo
	else
		printf "Enter Borg repo passphrase: " >&2
		stty -echo; read -r _borg_pass; stty echo; printf "\n" >&2
	fi
	export BORG_PASSPHRASE="$_borg_pass"
fi

if [[ ! -z "${BORG_PASSPHRASE:-}" ]]; then
	for rc in ~/.bashrc ~/.zshrc; do
		# only append once
		if ! grep -q '^export BORG_PASSPHRASE=' "$rc" 2>/dev/null; then
			printf "\n# Borg repo passphrase\nexport BORG_PASSPHRASE='%s'\n" "$BORG_PASSPHRASE" >> "$rc"
		fi
	done
fi

# 2) SET UP PASSWORDLESS SSH FOR borguser
SSH_KEY="$HOME/.ssh/id_ed25519_borg"
if [[ ! -f "$SSH_KEY" ]]; then
	echo "Generating SSH key for borguser at $SSH_KEY…"
	ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "borg backup key"
	echo "Copying public key to ${borgUser}@${sshHost}"
	ssh-copy-id -i "${SSH_KEY}.pub" ${borgUser}@${sshHost}
fi

# Export BORG_RSH so borg will use your key
export BORG_RSH="ssh -i $SSH_KEY -o IdentitiesOnly=yes"
for rc in ~/.bashrc ~/.zshrc; do
	if ! grep -q '^export BORG_RSH=' "$rc" 2>/dev/null; then
		printf "\n# Use dedicated key for borg backups\nexport BORG_RSH='ssh -i %s -o IdentitiesOnly=yes'\n" "$SSH_KEY" >> "$rc"
	fi
done
