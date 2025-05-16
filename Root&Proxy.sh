#!/bin/bash
# === 1. Cập nhật và cài đặt công cụ cần thiết ===
apt-get update -y
apt-get install -y wget curl sudo

# === 2. Đặt lại mật khẩu root và cho phép đăng nhập SSH bằng mật khẩu ===
echo 'root:01062007Tu#' | chpasswd
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# === 3. Cài đặt 3proxy ===
wget -q -O /tmp/3proxy.deb "https://github.com/z3APA3A/3proxy/releases/download/0.9.4/3proxy-0.9.4.x86_64.deb"
if [ $? -ne 0 ]; then
    wget -q -O /tmp/3proxy.deb "https://github.com/z3APA3A/3proxy/releases/download/0.9.3/3proxy-0.9.3.x86_64.deb"
fi
dpkg -i /tmp/3proxy.deb || (apt-get -f install -y && dpkg -i /tmp/3proxy.deb)
rm -f /tmp/3proxy.deb

# === 4. Tạo cấu hình proxy SOCKS5 (user/pass) ===
mkdir -p /etc/3proxy/conf
cat > /etc/3proxy/conf/3proxy.cfg <<EOF
nserver 1.1.1.1
nserver 8.8.8.8
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
auth strong
users anhtu:CL:anhtuproxy
allow anhtu
socks -p23456
EOF

# === 5. Tạo service tự khởi động lại 3proxy sau reboot ===
cat > /etc/systemd/system/3proxy.service <<EOF
[Unit]
Description=3proxy Socks5 Service
After=network.target

[Service]
ExecStart=/usr/bin/3proxy /etc/3proxy/conf/3proxy.cfg
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === 6. Bật và chạy 3proxy ===
systemctl daemon-reload
systemctl enable 3proxy
systemctl restart 3proxy

# === 7. Gửi thông tin về Telegram ===
BOT_TOKEN="7661562599:AAG5AvXpwl87M5up34-nj9AvMiJu-jYuWlA"
CHAT_ID="7051936083"
IP=$(curl -s ifconfig.me || curl -s ipv4.icanhazip.com)

MESSAGE="🎯 Proxy Created!
➡️ $IP:23456
👤 anhtu
🔑 anhtuproxy

-> $IP:23456:anhtu:anhtuproxy

🔹 SSH VPS
➡️ $IP
👤 root
🔑 01062007Tu#
-> Cách Login Vào VPS Trên Command : ssh root@$IP

✅ Sẵn sàng!"

curl -s --data-urlencode "text=$MESSAGE" "https://api.telegram.org/bot$BOT_TOKEN/sendMessage?chat_id=$CHAT_ID"
