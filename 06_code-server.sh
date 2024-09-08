#!/bin/bash

# Kullanıcı adı sabit olarak root olacak
CODE_USER="root"

# Domain adını alın
read -p "Domain adı girin (örn: code.veobu.com): " DOMAIN_NAME

# Code-Server ve Nginx yapılandırmalarını kaldırma kontrolü
echo "Code-Server daha önce kuruldu mu kontrol ediliyor..."

if systemctl is-active --quiet code-server@$CODE_USER; then
    echo "Code-Server daha önce kurulu, ayarlar kaldırılıyor..."
    
    # Code-Server durduruluyor
    sudo systemctl stop code-server@$CODE_USER
    
    # Code-Server servisinden otomatik başlatma kaldırılıyor
    sudo systemctl disable code-server@$CODE_USER
    
    # Code-Server yapılandırma dosyaları kaldırılıyor
    sudo rm -rf /root/.config/code-server/
    
    # Nginx Code-Server yapılandırması kaldırılıyor
    if [ -f /etc/nginx/sites-available/$DOMAIN_NAME.conf ]; then
        sudo rm /etc/nginx/sites-available/$DOMAIN_NAME.conf
        sudo rm /etc/nginx/sites-enabled/$DOMAIN_NAME.conf
        sudo systemctl reload nginx
        echo "Nginx Code-Server yapılandırması kaldırıldı."
    else
        echo "Nginx Code-Server yapılandırması zaten yok."
    fi

    echo "Eski Code-Server yapılandırmaları kaldırıldı."
else
    echo "Code-Server kurulumu bulunamadı, temizlemeye gerek yok."
fi

# Code-Server şifresini belirleyin
read -sp "Code-Server için bir şifre belirleyin: " CODE_PASSWORD
echo

echo "Code-Server kuruluyor..."
curl -fsSL https://code-server.dev/install.sh | sh
sudo systemctl enable --now code-server@$CODE_USER

# Code-Server yapılandırması (sadece içeriden erişilebilir)
echo "Code-Server yapılandırılıyor..."
sudo mkdir -p /root/.config/code-server/
sudo tee /root/.config/code-server/config.yaml > /dev/null <<EOL
bind-addr: 0.0.0.0:8081
auth: password
password: $CODE_PASSWORD
cert: false
EOL

sudo chown -R $CODE_USER:$CODE_USER /root/.config/

# Nginx Konfigürasyonu Code-Server için (WebSocket ile)
echo "Nginx Code-Server için yapılandırılıyor..."
sudo tee /etc/nginx/sites-available/$DOMAIN_NAME.conf > /dev/null <<EOL
server {
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket başlıkları
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME.conf /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# UFW yapılandırması (HTTP ve HTTPS açılıyor, 8081 kapanıyor)
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 8081/tcp

# Certbot SSL Sertifikası Oluşturma
echo "Certbot ile SSL sertifikası alınıyor..."
sudo certbot --nginx -d $DOMAIN_NAME

# Code-Server çalıştırma
echo "Code-Server başlatılıyor..."
sudo systemctl start code-server@$CODE_USER

echo "Code-Server SSL ile https://$DOMAIN_NAME adresinden erişilebilir."
