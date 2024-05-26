#!/bin/bash

# Обновление и установка необходимых пакетов
sudo apt update
sudo apt install -y python3-pip nginx

# Установка Flask
pip3 install Flask

# Переход в домашний каталог пользователя и клонирование репозитория
cd /home/$USER
git clone https://github.com/ваш_пользователь/app.git app

# Установка зависимостей приложения
cd app
pip3 install -r requirements.txt

# Копирование приложения в директорию для деплоя
sudo mkdir -p /var/www/app
sudo cp -r /home/$USER/app/* /var/www/app
sudo chmod -R 755 /var/www/app

# Создание systemd юнита для приложения
sudo bash -c 'cat > /etc/systemd/system/flaskapp.service <<EOF
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User='$USER'
Group=www-data
WorkingDirectory=/var/www/app
ExecStart=/usr/bin/python3 /var/www/app/app.py

[Install]
WantedBy=multi-user.target
EOF'

# Запуск и активация сервиса
sudo systemctl start flaskapp
sudo systemctl enable flaskapp

# Настройка Nginx для реверс-прокси
sudo bash -c 'cat > /etc/nginx/sites-available/app <<EOF
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
EOF'

# Активировать конфигурацию Nginx
sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx

# Проверка статуса сервиса и вывод истории команд
sudo systemctl status flaskapp
history
