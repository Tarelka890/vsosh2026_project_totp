#!/usr/bin/env bash
set -e
apt update && apt upgrade

cp ./Binaries/secure-passwd   /usr/local/sbin/secure-passwd
cp ./Binaries/secure-sshkeys  /usr/local/sbin/secure-sshkeys
cp ./Binaries/secure-usermod  /usr/local/sbin/secure-usermod
cp ./Binaries/secure-useradd  /usr/local/sbin/secure-useradd

chown root:root /usr/local/sbin/secure-passwd /usr/local/sbin/secure-sshkeys
chmod 0755      /usr/local/sbin/secure-passwd /usr/local/sbin/secure-sshkeys

chown root:root /usr/local/sbin/secure-usermod /usr/local/sbin/secure-useradd
chmod 0755      /usr/local/sbin/secure-usermod /usr/local/sbin/secure-useradd

echo "binaries setup complete."

getent group operators >/dev/null || groupadd operators

cat > /etc/sudoers.d/operators <<'EOF'
%operators ALL=(root) NOPASSWD: /usr/local/sbin/secure-passwd *
%operators ALL=(root) NOPASSWD: /usr/local/sbin/secure-sshkeys *
%operators ALL=(root) NOPASSWD: /usr/local/sbin/secure-usermod *
%operators ALL=(root) NOPASSWD: /usr/local/sbin/secure-useradd *
EOF

chmod 0440 /etc/sudoers.d/operators

visudo -cf /etc/sudoers.d/operators

echo "sudoers setup complete."

apt update
apt install apparmor apparmor-utils apparmor-profiles
systemctl start apparmor
systemctl enable apparmor

echo "AppArmor installation complete."

cp ./AppArmor/passwd_aa  /etc/apparmor.d/usr.local.sbin.secure-passwd
cp ./AppArmor/sshkeys_aa /etc/apparmor.d/usr.local.sbin.secure-sshkeys
apparmor_parser -r /etc/apparmor.d/usr.local.sbin.secure-passwd -W
apparmor_parser -r /etc/apparmor.d/usr.local.sbin.secure-sshkeys -W
aa-enforce /usr/local/sbin/secure-passwd
aa-enforce /usr/local/sbin/secure-sshkeys

echo "AppArmor setup complete."

mkdir /var/log/risktotp
mkdir /var/lib/risktotp

chmod 0640 /var/log/risktotp /var/lib/risktotp
chown root:root /var/log/risktotp /var/lib/risktotp

echo "folder setup complete."