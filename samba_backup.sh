#!/bin/bash

set -eu
set -o pipefail

if [ "$#" -ne 1 ]; then
    echo "This script must be executed with exactly one parameter: the path to .backup_envrc."
    exit 1
fi
BACKUP_ENVRC=${1}
if [ "${BACKUP_ENVRC}" != *.backup_envrc ]; then
    echo "Invalid .backup_envrc file ${BACKUP_ENVRC}."
    exit 1
fi

export NOBACKUP=".nobackup"
source "${BACKUP_ENVRC}"

[ -z "${SMB_USERNAME}" ] && exit 1
[ -z "${SMB_PASSWORD}" ] && exit 1
[ -z "${BACKUP_ENCRYPTION_PASSPHRASE}" ] && exit 1
[ -z "${BACKUP_DESTINATION}" ] && exit 1
[ -z "${BACKUP_MOUNT_POINT}" ] && exit 1
[ -z "${BACKUP_FOLDER}" ] && exit 1
[ -z "${IGNORED_FOLDERS}" ] && exit 1

if [[ ! "$(findmnt -rno SOURCE,TARGET ${BACKUP_DESTINATION})" ]]; then
  if [ ! -d "${BACKUP_MOUNT_POINT}" ]; then
    echo "creating ${BACKUP_MOUNT_POINT}"
    mkdir -p "${BACKUP_MOUNT_POINT}"
  fi
  echo "mounting ${BACKUP_DESTINATION}"
  mount -t cifs "${BACKUP_DESTINATION}" "${BACKUP_MOUNT_POINT}" -o username="${SMB_USERNAME}",password="${SMB_PASSWORD}",mapchars
fi

IFS=',' read -r -a ignored <<< "${IGNORED_FOLDERS}"

for ignore in "${ignored[@]}"; do
  directory="${BACKUP_FOLDER}/${ignore}"
  echo "ignoring ${directory}"
  if [ -d "${directory}" ]; then
    touch "${directory}/${NOBACKUP}"
  fi
done
		       
export PASSPHRASE="${BACKUP_ENCRYPTION_PASSPHRASE}"
echo "backing up ${BACKUP_FOLDER}"
duplicity --exclude-if-present "${NOBACKUP}" "${BACKUP_FOLDER}" "file://${BACKUP_MOUNT_POINT}"

umount "${BACKUP_MOUNT_POINT}"

unset SMB_PASSWORD
unset SMB_USERNAME
unset BACKUP_ENCRYPTION_PASSPHRASE
unset BACKUP_DESTINATION
unset BACKUP_MOUNT_POINT
unset PASSPHRASE
