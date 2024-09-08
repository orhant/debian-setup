#!/bin/bash

# Code-Server Kullanıcı Adını Al
read -p "Code-Server için kurmak istediğiniz kullanıcı adı: " CODE_USER

# Code-Server Konfigürasyonlarını Temizle
echo "Code-Server konfigürasyon dosyaları temizleniyor..."
sudo rm -rf /home/$CODE_USER/.config/code-server

# Code-Server Servisini Durdur ve Kaldır
echo "Code-Server servisi durduruluyor ve kaldırılıyor..."
sudo systemctl stop code-server@$CODE_USER
sudo systemctl disable code-server@$CODE_USER

# Nginx Konfigürasyon Dosyalarını Temizle
echo "Nginx konfigürasyon dosyaları temizleniyor..."
sudo rm /etc/nginx/sites-available/code-server
sudo rm /etc/nginx/sites-enabled/code-server

# Code-Server Kurulumu
echo "Code-Server kuruluyor..."
curl -fsSL https://code-server.dev/install.sh | sh

# Code-Server Servisini Etkinleştir
echo "Code-Server servisi etkinleştiriliyor..."
sudo systemctl enable --now code-server@$CODE_USER

# Code-Server Yapılandırmasını Yap
echo "Code-Server yapılandırması yapılıyor..."
sudo mkdir -p /home/$CODE_USER/.config/code-server/
sudo tee /home/$CODE_USER/.config/code-server/config.yaml > /dev/null <<EOL
bind-addr: 0.0.0.0:8081
auth: password
password: $(openssl rand -base64 12)
cert: false
EOL

sudo chown -R $CODE_USER:$CODE_USER /home/$CODE_USER/.config/

# Nginx Konfigürasyonu Code-Server için
echo "Nginx Code-Server için yapılandırılıyor..."
sudo tee /etc/nginx/sites-available/code-server > /dev/null <<EOL
server {
    server_name code.veobu.com;

    location / {
        proxy_pass http://localhost:8081;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/code-server /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# UFW yapılandırması (HTTP ve HTTPS açılıyor)
echo "UFW yapılandırması yapılıyor..."
sudo ufw allow 'Nginx Full'
sudo ufw allow 8081/tcp

# Certbot SSL Sertifikası Oluşturma
echo "Certbot ile SSL sertifikası alınıyor..."
sudo certbot --nginx -d code.veobu.com

echo "Code-Server SSL ile https://code.veobu.com adresinden erişilebilir."
