#!/bin/bash
# Enterprise Zabbix + NAS + VirtualBox + automatizace
set -e

echo "[+] Aktualizace balíků"
sudo apt update && sudo apt upgrade -y

echo "[+] Instalace základních nástrojů"
sudo apt install -y mariadb-server mariadb-client apache2 php php-mysql php-gd php-mbstring php-bcmath php-xml curl wget unzip virtualbox

echo "[+] Nastavení Zabbix repozitáře"
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_7.0-2+ubuntu24.04_all.deb
sudo apt update
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent zabbix-agent2 zabbix-sql-scripts

echo "[+] Konfigurace MariaDB a Zabbix uživatele"
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
DROP USER IF EXISTS 'zabbix'@'localhost';
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'ZabbixStrongPass123';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "[+] Inicializace Zabbix DB"
sudo zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -pZabbixStrongPass123 zabbix

echo "[+] Povolení a restart služeb Zabbix"
sudo systemctl enable zabbix-server zabbix-agent apache2
sudo systemctl start zabbix-server zabbix-agent apache2

echo "[+] Kopírování skriptů"
sudo mkdir -p /usr/local/bin
sudo cp scripts/*.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/*.sh

echo "[+] Nastavení cron jobů"
(crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/check_zabbix_db.sh") | crontab -
(crontab -l 2>/dev/null; echo "30 2 * * * /usr/local/bin/optimize_zabbix_db.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/check_zabbix_service.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/check_virtualbox.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/check_nas.sh") | crontab -

echo "[+] Instalace a konfigurace web GUI"
sudo mkdir -p /var/www/html/enterprise
sudo cp -r web/* /var/www/html/enterprise/
sudo chown -R www-data:www-data /var/www/html/enterprise

echo "[+] Instalace dokončena. Přístup k web GUI: http://<IP_SERVERU>/enterprise"
