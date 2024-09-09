#!/bin/bash

# phpMyAdmin kurulumu
echo "phpMyAdmin kuruluyor..."
sudo apt install phpmyadmin -y --no-install-recommends

# Domain adını alın
read -p "phpMyAdmin için domain adı girin (örn: db.veobu.com): " DOMAIN_NAME

# config.inc.php dosyasını config.sample.inc.php'den oluştur
echo "phpMyAdmin config.inc.php dosyası oluşturuluyor..."
sudo cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php

# Blowfish Secret için rastgele bir anahtar oluştur
BLOWFISH_SECRET=$(openssl rand -base64 32)

# Blowfish Secret'ı config.inc.php'ye ekleyin
sudo sed -i "s|\$cfg\['blowfish_secret'\] = ''|\$cfg\['blowfish_secret'\] = '$BLOWFISH_SECRET'|" /usr/share/phpmyadmin/config.inc.php

# Nginx Konfigürasyonu phpMyAdmin için
echo "Nginx phpMyAdmin için yapılandırılıyor..."
sudo tee /etc/nginx/sites-available/$DOMAIN_NAME.conf > /dev/null <<EOL
server {
    server_name $DOMAIN_NAME;

    root /usr/share/phpmyadmin;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~* \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.*)\$;
        if (!-f \$document_root\$fastcgi_script_name) { return 404; }

        # Mitigate https://httpoxy.org/ vulnerabilities
        fastcgi_param HTTP_PROXY "";

        include "fastcgi_params";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_index index.php;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;

        add_header "X-Cache" "MISS";
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# phpMyAdmin Nginx'e ekleme ve yeniden başlatma
sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME.conf /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Certbot SSL Sertifikası Oluşturma
echo "Certbot ile SSL sertifikası alınıyor..."
sudo certbot --nginx -d $DOMAIN_NAME

echo "phpMyAdmin SSL ile https://$DOMAIN_NAME adresinden erişilebilir."
