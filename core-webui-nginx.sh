#!/usr/bin/env bash

cat <<EOF > /etc/nginx/sites-available/core-ui
server {
  listen 3000;

  location / {
    auth_basic "Core Admin";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://127.0.0.1:9000;
  }
}
EOF

ln -s /etc/nginx/sites-available/core-ui /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
