#!/usr/bin/env bash
apt install -y nginx apache2-utils libpam-google-authenticator

htpasswd -bc /etc/nginx/.htpasswd admin StrongPassword

cat <<EOF > /etc/nginx/sites-available/secure-panel
server {
  listen 8443 ssl;
  ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
  ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

  location / {
    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://127.0.0.1:9000;
  }
}
EOF

ln -s /etc/nginx/sites-available/secure-panel /etc/nginx/sites-enabled/
systemctl reload nginx
