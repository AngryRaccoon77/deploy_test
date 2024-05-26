#!/bin/bash

set -e

# Конфигурация
APP_USER=$(whoami)
APP_DIR="/home/$APP_USER/app"
DEPLOY_DIR="/var/www/app"
SERVICE_NAME="flaskapp"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
NGINX_CONF="/etc/nginx/sites-available/app"
NGINX_LINK="/etc/nginx/sites-enabled/app"

# Установка зависимостей
sudo apt update
sudo apt install -y python3-pip nginx

# Установка зависимостей Python
pip3 install -r "$APP_DIR/requirements.txt"

# Подготовка папки для деплоя
sudo mkdir -p $DEPLOY_DIR
sudo cp -r $APP_DIR/* $DEPLOY_DIR
sudo chmod -R 755 $DEPLOY_DIR

# Создание systemd сервиса
sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=$APP_USER
Group=www-data
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/bin/python3 $DEPLOY_DIR/app.py

[Install]
WantedBy=multi-user.target
EOF"

# Запуск и активация systemd сервиса
sudo systemctl daemon-reload
sudo systemctl start $SERVICE_NAME
sudo systemctl enable $SERVICE_NAME

# Настройка Nginx
sudo bash -c "cat > $NGINX_CONF <<EOF
server {
    listen 80;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF"

# Активировать конфигурацию Nginx
if [ ! -L "$NGINX_LINK" ]; then
    sudo ln -s $NGINX_CONF $NGINX_LINK
fi
sudo nginx -t
sudo systemctl restart nginx

echo "Deployment completed successfully!"
