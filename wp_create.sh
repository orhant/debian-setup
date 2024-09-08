#!/bin/bash

# MySQL root şifresinin mevcut olup olmadığını kontrol etme
MYSQL_CONF="/root/.my.cnf"

if [ -f "$MYSQL_CONF" ]; then
    echo "MySQL root şifresi bulundu. Kullanılıyor..."
else
    echo "MySQL root şifresi bulunamadı. Lütfen şifre girin."
    read -sp "MariaDB root şifresini girin: " MYSQL_ROOT_PASSWORD
    echo

    # Şifreyi kontrol etme
    if mysql -u root -p$MYSQL_ROOT_PASSWORD -e "exit" >/dev/null 2>&1; then
        echo "Şifre doğru, şifre kaydediliyor."
        
        # MySQL root yapılandırma dosyası oluşturma ve şifreyi kaydetme
        sudo tee /root/.my.cnf > /dev/null <<EOL
[client]
user=root
password=$MYSQL_ROOT_PASSWORD
EOL
        sudo chmod 600 /root/.my.cnf
    else
        echo "Hatalı şifre. Lütfen tekrar deneyin."
        exit 1
    fi
fi

# Kullanıcıdan domain adı alma
read -p "Domain adını girin (örn: example.com): " WP_DOMAIN

# WordPress kök dizini ve Nginx yapılandırma dosyasını belirleme
WP_ROOT="/var/www/html/$WP_DOMAIN"
NGINX_CONF_TEMPLATE="/etc/nginx/sites-available/example.com.conf"

# WordPress dizinini oluşturma ve dosya indirme
echo "WordPress dizini oluşturuluyor ve WordPress indiriliyor..."
sudo mkdir -p $WP_ROOT
sudo chown -R $USER:$USER $WP_ROOT
cd $WP_ROOT
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz --strip-components=1
rm latest.tar.gz

# Veritabanı ayarları
WP_DB_NAME=$(echo $WP_DOMAIN | tr . _)_db
WP_DB_USER=$(echo $WP_DOMAIN | tr . _)_user
WP_DB_PASSWORD=$(openssl rand -base64 12) # Veritabanı şifresi otomatik oluşturulur

# MariaDB'de veritabanı ve kullanıcı oluşturma
echo "Veritabanı oluşturuluyor..."
sudo mysql -e "CREATE DATABASE $WP_DB_NAME; \
CREATE USER '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASSWORD'; \
GRANT ALL PRIVILEGES ON $WP_DB_NAME.* TO '$WP_DB_USER'@'localhost'; \
FLUSH PRIVILEGES;"

# WordPress wp-config.php dosyasını yapılandırma
echo "wp-config.php ayarları yapılıyor..."
cp $WP_ROOT/wp-config-sample.php $WP_ROOT/wp-config.php
sed -i "s/database_name_here/$WP_DB_NAME/" $WP_ROOT/wp-config.php
sed -i "s/username_here/$WP_DB_USER/" $WP_ROOT/wp-config.php
sed -i "s/password_here/$WP_DB_PASSWORD/" $WP_ROOT/wp-config.php

# WordPress için gerekli dosya izinleri ayarlama
sudo chown -R www-data:www-data $WP_ROOT
sudo find $WP_ROOT -type d -exec chmod 750 {} \;
sudo find $WP_ROOT -type f -exec chmod 640 {} \;

# Nginx yapılandırması için örnek dosyayı kopyalama
echo "Nginx yapılandırma dosyası kopyalanıyor ve ayarlanıyor..."
sudo cp $NGINX_CONF_TEMPLATE /etc/nginx/sites-available/$WP_DOMAIN.conf
sudo sed -i 's:/home/username/sites/example.com/public:'$WP_ROOT':g' /etc/nginx/sites-available/$WP_DOMAIN.conf
sudo sed -i 's/example.com/'$WP_DOMAIN'/g' /etc/nginx/sites-available/$WP_DOMAIN.conf

# Nginx sites-enabled dizininde sembolik link oluşturma
cd /etc/nginx/sites-enabled/
sudo ln -s ../sites-available/$WP_DOMAIN.conf

# Nginx yapılandırmasını test etme ve yeniden başlatma
sudo nginx -t && sudo systemctl restart nginx

# Certbot ile SSL yapılandırması
echo "Certbot ile SSL yapılandırması yapılıyor..."
sudo certbot --nginx -d $WP_DOMAIN

echo "WordPress kurulumu tamamlandı. https://$WP_DOMAIN adresinden erişebilirsiniz."
echo "Veritabanı adı: $WP_DB_NAME"
echo "Veritabanı kullanıcı adı: $WP_DB_USER"
echo "Veritabanı şifresi: $WP_DB_PASSWORD"
