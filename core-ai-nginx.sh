#!/usr/bin/env bash

cat <<EOF > /etc/nginx/sites-available/ai-chat
server {
  listen 8444;

  location / {
    auth_basic "AI Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://127.0.0.1:3001;
  }
}
EOF

ln -s /etc/nginx/sites-available/ai-chat /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
