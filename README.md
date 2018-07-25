# Introduction

Automated backups for remote samba location using duplicity.

# Installation

Run `install.sh` as root and follow the prompts. This will install `backup_home.sh` in `/usr/local/bin` and add a cron job at `/etc/cron.d/backup_home`. The cron job runs daily at a user specified time. 