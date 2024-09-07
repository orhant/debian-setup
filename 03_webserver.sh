#!/bin/bash

# Nginx Kurulumu
echo "Nginx kuruluyor..."
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

# UFW Nginx profilleri ile yapılandırma (UFW zaten kurulu, sadece Nginx yapılandırması)
echo "UFW Nginx profilleri ile yapılandırma yapılıyor..."
sudo ufw app list

# Eğer 'Nginx Full' profili yoksa HTTP ve HTTPS portlarını aç
if ! sudo ufw app info 'Nginx Full'; then
    sudo ufw allow 'Nginx HTTP'
    sudo ufw allow 'Nginx HTTPS'
else
    sudo ufw allow 'Nginx Full'
fi

# PHP ve Gerekli Modüllerin Kurulumu
echo "PHP kuruluyor..."
sudo apt install php php-fpm php-mysql php-cli php-curl php-zip php-gd php-mbstring php-xml php-json -y
php -v

# MariaDB Kurulumu
echo "MariaDB kuruluyor..."
sudo apt install mariadb-server mariadb-client -y
sudo systemctl start mariadb
sudo systemctl enable mariadb
