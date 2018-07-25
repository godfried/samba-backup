#!/bin/bash

set -eu
set -o pipefail

if [ "$EUID" -ne 0 ]
  then echo "The install script must be run as root"
  exit 1
fi

echo "Enter the Backup destination:"
read -r BACKUP_DESTINATION
echo "Enter the Backup mount point:"
read -r BACKUP_MOUNT_POINT
echo "Enter the destination username:"
read -r SMB_USERNAME
echo "Enter the destination password:"
read -r SMB_PASSWORD
echo "Enter the encryption passphrase:"
read -r BACKUP_ENCRYPTION_PASSPHRASE
echo "Enter a comma-separated list of directories in your home folder to ignore:"
read -r IGNORED_FOLDERS
echo "Enter an hour at which the backup should be made. Backups are made daily."
read -r BACKUP_HOUR

cat <<EOF > ${HOME}/.backup_envrc
export BACKUP_DESTINATION="${BACKUP_DESTINATION}"
export BACKUP_MOUNT_POINT="${BACKUP_MOUNT_POINT}"
export SMB_USERNAME="${SMB_USERNAME}"
export SMB_PASSWORD="${SMB_PASSWORD}"
export BACKUP_ENCRYPTION_PASSPHRASE="${BACKUP_ENCRYPTION_PASSPHRASE}"
export IGNORED_FOLDERS="${IGNORED_FOLDERS}"
EOF

cp backup_home.sh /usr/local/bin/
chmod +x /usr/local/bin/backup_home.sh

cat <<EOF > /etc/cron.d/backup_home
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 ${BACKUP_HOUR} * * * root backup_home.sh"
EOF
