#!/bin/bash

# Code-Server Kurulumu
read -p "Code-Server için kurmak istediğiniz kullanıcı adı: " CODE_USER

echo "Code-Server kuruluyor..."
curl -fsSL https://code-server.dev/install.sh | sh
sudo systemctl enable --now code-server@$CODE_USER

# Code-Server yapılandırması (başka bir port kullanıyoruz, örn. 8081)
echo "Code-Server yapılandırılıyor..."
sudo mkdir -p /home/$CODE_USER/.config/code-server/
sudo tee /home/$CODE_USER/.config/code-server/config.yaml > /dev/null <<EOL
bind-addr: 127.0.0.1:8081
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
sudo ufw allow 'Nginx Full'

# Certbot SSL Sertifikası Oluşturma
echo "Certbot ile SSL sertifikası alınıyor..."
sudo certbot --nginx -d code.veobu.com

echo "Code-Server SSL ile https://code.veobu.com adresinden erişilebilir."
