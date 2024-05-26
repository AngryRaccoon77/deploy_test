#!/bin/bash

# Прекращаем выполнение скрипта при ошибках
set -e

# Параметры
APP_DIR="/home/$(whoami)/deploy_test"
DEPLOY_DIR="/var/www/app"
SERVICE_NAME="flaskapp"

# Установка необходимых пакетов
echo "Updating package list and installing necessary packages..."
sudo apt update
sudo apt install -y python3-pip nginx

# Установка зависимостей Python
echo "Installing Python dependencies..."
pip3 install -r "$APP_DIR/requirements.txt"

# Копирование приложения в директорию деплоя
echo "Copying application files to the deployment directory..."
sudo mkdir -p $DEPLOY_DIR
sudo cp -r $APP_DIR/* $DEPLOY_DIR
sudo chmod -R 755 $DEPLOY_DIR

# Создание systemd unit файла
echo "Creating systemd service file..."
sudo bash -c "cat > /etc/systemd/system/$SERVICE_NAME.service" <<EOF
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=$(whoami)
Group=www-data
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/bin/python3 $DEPLOY_DIR/app.py

[Install]
WantedBy=multi-user.target
EOF

# Перезапуск и включение сервиса
echo "Starting and enabling the systemd service..."
sudo systemctl daemon-reload
sudo systemctl start $SERVICE_NAME
sudo systemctl enable $SERVICE_NAME

# Настройка Nginx
echo "Configuring Nginx..."
sudo bash -c "cat > /etc/nginx/sites-available/app" <<EOF
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
EOF
# Удаление конфигурации Nginx по умолчанию
echo "Removing default Nginx configuration..."
sudo rm -f /etc/nginx/sites-enabled/default

# Активация конфигурации Nginx
echo "Activating Nginx configuration..."
sudo ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx

echo "Deployment completed successfully!"
