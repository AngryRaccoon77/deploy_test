#!/bin/bash

# Переменные
USER=$(whoami)
APP_DIR="/home/$USER/app"
DEPLOY_DIR="/var/www/app"
SERVICE_FILE="/etc/systemd/system/flaskapp.service"
NGINX_CONF="/etc/nginx/sites-available/app"
NGINX_LINK="/etc/nginx/sites-enabled/app"

# Обновление и установка необходимых пакетов
sudo apt update
sudo apt install -y python3-pip nginx

# Установка Flask
pip3 install Flask

# Клонирование репозитория
if [ ! -d "$APP_DIR" ]; then
  git clone https://github.com/ваш_пользователь/app.git $APP_DIR
else
  echo "Директория $APP_DIR уже существует. Пропускаем клонирование."
fi

cd $APP_DIR
pip3 install -r requirements.txt

# Копирование приложения в директорию для деплоя
sudo mkdir -p $DEPLOY_DIR
sudo cp -r $APP_DIR/* $DEPLOY_DIR
sudo chmod -R 755 $DEPLOY_DIR

# Создание файла сервиса systemd
sudo bash -c "cat > $SERVICE_FILE <<EOL
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/bin/python3 $DEPLOY_DIR/app.py

[Install]
WantedBy=multi-user.target
EOL"

# Запуск и активация сервиса
sudo systemctl daemon-reload
sudo systemctl start flaskapp
sudo systemctl enable flaskapp

# Настройка Nginx
sudo bash -c "cat > $NGINX_CONF <<EOL
server {
    listen 80;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOL"

# Активирование конфигурации Nginx
sudo ln -sf $NGINX_CONF $NGINX_LINK
sudo nginx -t
sudo systemctl restart nginx

echo "Развертывание завершено успешно!"
