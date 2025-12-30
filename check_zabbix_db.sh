#!/bin/bash
LOGFILE="/var/log/zabbix-db-fix.log"
DB_USER="zabbix"
DB_PASS="ZabbixStrongPass123"
DB_NAME="zabbix"
echo "==== $(date) ====" >> $LOGFILE
mysql -u $DB_USER -p$DB_PASS -e "USE $DB_NAME;" &>/dev/null
if [ $? -ne 0 ]; then
    echo "[$(date)] Oprava DB a uživatele..." >> $LOGFILE
    sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
DROP USER IF EXISTS '$DB_USER'@'localhost';
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    echo "[$(date)] Oprava dokončena" >> $LOGFILE
else
    echo "[$(date)] DB OK" >> $LOGFILE
fi
