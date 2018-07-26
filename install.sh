#!/bin/bash

set -eu
set -o pipefail

if [ "$EUID" -ne 0 ]
  then echo "The install script must be run as root"
  exit 1
fi

BACKUP_ENVRC="${HOME}/.backup_envrc"
BACKUP_CRON="/etc/cron.d/backup_home"
BACKUP_SCRIPT="/usr/local/bin/backup_home.sh"

create_envrc () {
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

    cat <<EOF > ${BACKUP_ENVRC}
export BACKUP_DESTINATION="${BACKUP_DESTINATION}"
export BACKUP_MOUNT_POINT="${BACKUP_MOUNT_POINT}"
export SMB_USERNAME="${SMB_USERNAME}"
export SMB_PASSWORD="${SMB_PASSWORD}"
export BACKUP_ENCRYPTION_PASSPHRASE="${BACKUP_ENCRYPTION_PASSPHRASE}"
export IGNORED_FOLDERS="${IGNORED_FOLDERS}"
EOF
}

create_cron () {
    echo "Enter an hour at which the backup should be made. Backups are made daily."
    read -r BACKUP_HOUR
    cat <<EOF > ${BACKUP_CRON}
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 ${BACKUP_HOUR} * * * root ${BACKUP_SCRIPT} 2>&1 | /usr/bin/logger -t backup_home
EOF
}

install_script () {
    cp backup_home.sh ${BACKUP_SCRIPT}
    chmod +x ${BACKUP_SCRIPT}
}

should_install () {
    if [ ! -f ${1} ]; then
	return 0
    fi
    echo "${1} already exists, do you wish to overwrite it?"
    select yn in "yes" "no"; do
	case ${yn} in
            yes ) return 0;;
            no ) return 1;;
	    *) echo "Invalid input"
	esac
    done
}

if should_install ${BACKUP_ENVRC}; then
    create_envrc
fi

if should_install ${BACKUP_CRON}; then
    create_cron
fi

if should_install ${BACKUP_SCRIPT}; then
    install_script
fi
