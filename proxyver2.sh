#!/bin/bash

# === Cấu hình SSH ===
rm -f /etc/ssh/sshd_config
cat <<EOF > /etc/ssh/sshd_config
Port 22
PermitRootLogin yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Đặt mật khẩu root VPS
VPS_PASS="01062007Tu#"
echo "root:$VPS_PASS" | chpasswd
systemctl restart ssh
systemctl restart sshd

# === Cài đặt 3proxy ===
yum install -y git gcc make curl > /dev/null 2>&1
cd /root || cd ~
rm -rf 3proxy
git clone https://github.com/z3APA3A/3proxy.git
cd 3proxy
make -f Makefile.Linux PREFIX=bin

# === Cấu hình 3proxy user: anhtu pass: anhtuproxy ===
cat <<EOF > /etc/3proxy.cfg
daemon
maxconn 200
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
log /var/log/3proxy.log D
auth strong
users anhtu:CL:anhtuproxy
allow anhtu
socks -p23456
EOF

mkdir -p /var/log
touch /var/log/3proxy.log
chmod 666 /var/log/3proxy.log

# === Tạo systemd service để tự khởi động lại khi reboot ===
cat <<EOF > /etc/systemd/system/3proxy.service
[Unit]
Description=3Proxy SOCKS5 Service
After=network.target

[Service]
ExecStart=/root/3proxy/bin/3proxy /etc/3proxy.cfg
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable 3proxy
systemctl start 3proxy

# === Gửi thông tin về Telegram ===
BOT_TOKEN="7661562599:AAG5AvXpwl87M5up34-nj9AvMiJu-jYuWlA"
CHAT_ID="7051936083"
IP=$(curl -s ipv4.icanhazip.com)

curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
-d chat_id="$CHAT_ID" \
-d text="🎯 Proxy & VPS Created!

🔹 SOCKS5 Proxy
➡️ $IP:23456
👤 User: anhtu
🔑 Pass: anhtuproxy

🔹 SSH VPS
➡️ IP: $IP
👤 User: root
🔑 Pass: $VPS_PASS

✅ Thành công!"
