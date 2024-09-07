#!/bin/bash

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
sudo tee /etc/nginx/sites-available/webmin > /dev/null <<EOL
server {
    server_name webmin.veobu.com;

    location / {
        proxy_pass http://localhost:10000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/webmin /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Certbot SSL Sertifikası Oluşturma
echo "Certbot ile SSL sertifikası alınıyor..."
sudo certbot --nginx -d webmin.veobu.com

echo "Webmin SSL ile https://webmin.veobu.com adresinde çalışacak."
