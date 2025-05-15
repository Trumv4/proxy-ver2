#!/bin/bash

# === Cấu hình SSH cho phép root login ===
rm -f /etc/ssh/sshd_config
cat <<EOF > /etc/ssh/sshd_config
Port 22
PermitRootLogin yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

echo "root:01062007Tu#" | chpasswd
systemctl restart ssh

# === Cài đặt 3proxy ===
apt update -y
apt install -y git make curl gcc

cd /root || cd ~
git clone https://github.com/z3APA3A/3proxy.git
cd 3proxy
make -f Makefile.Linux PREFIX=bin

# === Tạo config cho 3proxy ===
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

# === Chuẩn bị log và service ===
mkdir -p /var/log
touch /var/log/3proxy.log
chmod 666 /var/log/3proxy.log

cat <<EOF > /etc/systemd/system/3proxy.service
[Unit]
Description=3proxy SOCKS5
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

# === Gửi về Telegram ===
BOT_TOKEN="7661562599:AAG5AvXpwl87M5up34-nj9AvMiJu-jYuWlA"
CHAT_ID="7051936083"
IP=$(curl -s ipv4.icanhazip.com)

MSG="🎯 Proxy Created!
➡️ $IP:23456
👤 anhtu
🔑 anhtuproxy

-> IP:PORT:USER:PASS 

🔹 SSH VPS
➡️ $IP
👤 root
🔑 01062007Tu#
-> Cách Login Vào VPS Trên Command : ssh root@$IP

✅ Sẵn sàng!"

curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d text="$MSG"
