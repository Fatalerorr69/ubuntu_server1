#!/usr/bin/env bash
apt install -y libpam-google-authenticator

for u in coreadmin operator auditor; do
  adduser --disabled-password --gecos "" $u
done

echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd
systemctl restart ssh
