#!/bin/bash

set -e

LOG_FILE="/var/log/ai-bildgenerator-install.log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "======================================"
echo "AI Bildgenerator - installation start"
echo "======================================"

echo "Uppdaterar Amazon Linux..."
dnf -y update

echo "Installerar grundpaket..."
dnf -y install \
    git \
    python3 \
    python3-pip \
    nginx

APP_DIR="/home/ec2-user/ai-bildgenerator"

echo "Tar bort eventuell gammal installation..."
rm -rf "$APP_DIR"

echo "Klonar GitHub-repot..."
git clone https://github.com/kevham89/ai-bildgenerator.git "$APP_DIR"

echo "Sätter ägare..."
chown -R ec2-user:ec2-user "$APP_DIR"

echo "Skapar Python virtual environment..."
sudo -u ec2-user python3 -m venv "$APP_DIR/venv"

echo "Installerar Python-paket..."
sudo -u ec2-user "$APP_DIR/venv/bin/pip" install --upgrade pip
sudo -u ec2-user "$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"

echo "Skapar .env..."

cat > "$APP_DIR/.env" <<EOF_ENV
HUGGINGFACE_TOKEN='${huggingface_token}'
EOF_ENV

chown ec2-user:ec2-user "$APP_DIR/.env"
chmod 600 "$APP_DIR/.env"

echo "Python-installationen är klar."
echo "======================================"
echo "Grundinstallation färdig"
echo "======================================"

echo "Skapar Gunicorn systemd-service..."

cat > /etc/systemd/system/ai-bildgenerator.service <<EOF_SERVICE
[Unit]
Description=AI Bildgenerator Flask App
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/home/ec2-user/ai-bildgenerator
EnvironmentFile=/home/ec2-user/ai-bildgenerator/.env
ExecStart=/home/ec2-user/ai-bildgenerator/venv/bin/gunicorn --workers 1 --timeout 300 --bind 127.0.0.1:8000 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF_SERVICE

systemctl daemon-reload
systemctl enable ai-bildgenerator
systemctl start ai-bildgenerator

echo "Gunicorn-service skapad och startad."

echo "Konfigurerar Nginx..."

rm -f /etc/nginx/conf.d/default.conf

cat > /etc/nginx/conf.d/ai-bildgenerator.conf <<'EOF_NGINX'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }
}
EOF_NGINX

nginx -t

systemctl enable nginx
systemctl restart nginx

echo "Nginx är konfigurerad och startad."

echo "Kontrollerar att applikationen svarar..."

for i in {1..30}; do
    if curl -fsS http://127.0.0.1:8000/health; then
        echo
        echo "AI Bildgenerator svarar korrekt!"
        break
    fi

    echo "Applikationen är inte redo ännu. Försöker igen..."
    sleep 2
done

echo "======================================"
echo "AI Bildgenerator - installation klar"
echo "======================================"
