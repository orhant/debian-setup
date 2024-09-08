#!/bin/bash

# phpMyAdmin kurulumu
echo "phpMyAdmin kuruluyor..."
sudo apt install phpmyadmin -y --no-install-recommends

# Domain adını alın
read -p "phpMyAdmin için domain adı girin (örn: pma.veobu.com): " DOMAIN_NAME

# Nginx Konfigürasyonu phpMyAdmin için
echo "Nginx phpMyAdmin için yapılandırılıyor..."
sudo tee /etc/nginx/sites-available/$DOMAIN_NAME > /dev/null <<EOL
server {
    server_name $DOMAIN_NAME;

    root /usr/share/phpmyadmin;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# phpMyAdmin Nginx'e ekleme ve yeniden başlatma
sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Certbot SSL Sertifikası Oluşturma
echo "Certbot ile SSL sertifikası alınıyor..."
sudo certbot --nginx -d $DOMAIN_NAME

echo "phpMyAdmin SSL ile https://$DOMAIN_NAME adresinden erişilebilir."
