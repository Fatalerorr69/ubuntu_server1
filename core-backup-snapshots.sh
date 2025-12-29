#!/usr/bin/env bash
BACKUP="/srv/backups/$(date +%F)"
mkdir -p $BACKUP

rsync -a /etc /srv /home $BACKUP

tar czf $BACKUP.tar.gz $BACKUP
rm -rf $BACKUP
