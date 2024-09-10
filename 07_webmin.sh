#!/bin/bash

# Domain adını alın
read -p "Webmin domain adını girin (örn: webmin.veobu.com): " DOMAIN_NAME

# Webmin Kurulumu
echo "Webmin kuruluyor..."
wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
sudo sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
sudo apt update
sudo apt install webmin -y
sudo ufw allow 10000
sudo systemctl enable webmin
sudo systemctl start webmin

# Nginx Konfigürasyonu Webmin için
echo "Nginx Webmin için yapılandırılıyor..."
sudo tee /etc/nginx/sites-available/$DOMAIN_NAME.conf > /dev/null <<EOL
server {
    server_name $DOMAIN_NAME;

    access_log /var/log/nginx/$DOMAIN_NAME.access.log;
    error_log /var/log/nginx/$DOMAIN_NAME.error.log;

    location / {
        proxy_pass http://localhost:10000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Yapılandırmayı etkinleştirme (sites-enabled dizinine sembolik link oluşturma)
sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME.conf /etc/nginx/sites-enabled/

# Nginx'i yeniden başlatma
sudo systemctl reload nginx

# Certbot SSL Sertifikası Oluşturma
echo "Certbot ile SSL sertifikası alınıyor..."
sudo certbot --nginx -d $DOMAIN_NAME

echo "Webmin SSL ile https://$DOMAIN_NAME adresinde çalışacak."
