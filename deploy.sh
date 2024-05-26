#!/bin/bash

# Настройки
USER_NAME="your_username"  # Замените на ваше имя пользователя


# Обновление и установка необходимых пакетов
sudo apt update
sudo apt install -y python3-pip git nginx

# Установка Flask
pip3 install Flask

# Создание директории для клонирования репозитория
mkdir -p /home/$USER_NAME/app

# Установка зависимостей
pip3 install -r requirements.txt

# Копирование проекта в директорию для деплоя
sudo mkdir -p /var/www/app
sudo cp -r /home/$USER_NAME/app/* /var/www/app
sudo chmod -R 755 /var/www/app

# Создание systemd unit файла для Flask приложения
sudo bash -c 'cat > /etc/systemd/system/flaskapp.service <<EOF
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=$USER_NAME
Group=www-data
WorkingDirectory=/var/www/app
ExecStart=/usr/bin/python3 /var/www/app/app.py

[Install]
WantedBy=multi-user.target
EOF'

# Запуск и активация systemd сервиса
sudo systemctl start flaskapp
sudo systemctl enable flaskapp

# Настройка Nginx для работы в качестве реверс-прокси
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

# Активирование конфигурации Nginx
sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx

# Проверка статуса сервиса
echo "Сервис flaskapp:"
sudo systemctl status flaskapp

echo "Сервис Nginx:"
sudo systemctl status nginx

# Вывод истории команд
history
