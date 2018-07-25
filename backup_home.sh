#!/bin/bash

set -eu
set -o pipefail

export USER="pieter"
export HOME="/home/${USER}"
export NOBACKUP=".nobackup"

source ${HOME}/.backup_envrc

[ -z "${SMB_USERNAME}" ] && exit 1
[ -z "${SMB_PASSWORD}" ] && exit 1
[ -z "${BACKUP_ENCRYPTION_PASSPHRASE}" ] && exit 1
[ -z "${BACKUP_DESTINATION}" ] && exit 1
[ -z "${BACKUP_MOUNT_POINT}" ] && exit 1
[ -z "${IGNORED_FOLDERS}" ] && exit 1

if [[ ! $(findmnt -rno SOURCE,TARGET "${BACKUP_DESTINATION}") ]]; then
    if [ ! -d "${BACKUP_MOUNT_POINT}" ]; then
	echo "creating ${BACKUP_MOUNT_POINT}"
	mkdir -p "${BACKUP_MOUNT_POINT}"
    fi
    echo "mounting ${BACKUP_DESTINATION}"
    mount -t cifs "${BACKUP_DESTINATION}" "${BACKUP_MOUNT_POINT}" -o username="${SMB_USERNAME}",password="${SMB_PASSWORD}",mapchars
fi

IFS=',' read -r -a ignored <<< "${IGNORED_FOLDERS}"

for ignore in ${ignored[@]}; do
    directory="${HOME}/${ignore}"
    echo "ignoring ${directory}"
    if [ -d "${directory}" ]; then
        touch "${directory}/${NOBACKUP}"
    fi
done
		       
export PASSPHRASE="${BACKUP_ENCRYPTION_PASSPHRASE}"
echo "backing up ${HOME}"
duplicity --exclude-if-present "${NOBACKUP}" "${HOME}" "file://${BACKUP_MOUNT_POINT}"

umount "${BACKUP_MOUNT_POINT}"

unset SMB_PASSWORD
unset SMB_USERNAME
unset BACKUP_ENCRYPTION_PASSPHRASE
unset BACKUP_DESTINATION
unset BACKUP_MOUNT_POINT
unset PASSPHRASE
