#!/bin/bash

# Cloud9 SDK Kurulumu
echo "Cloud9 SDK kuruluyor..."
sudo npm install -g c9

# Forever paketinin kurulumu
sudo npm install -g forever

# Cloud9 Kullanıcı Dizini
read -p "Cloud9 için bir kullanıcı adı girin: " CLOUD9_USER

# Şifreyi iki kez sor ve doğrula
while true; do
    read -s -p "Cloud9 için bir şifre girin: " PASSWORD
    echo
    read -s -p "Şifreyi tekrar girin: " PASSWORD2
    echo
    [ "$PASSWORD" = "$PASSWORD2" ] && break
    echo "Şifreler uyuşmuyor. Lütfen tekrar deneyin."
done

echo "Şifre başarıyla ayarlandı."

# Cloud9 çalışma dizini ayarlanıyor
sudo mkdir -p /home/$CLOUD9_USER/cloud9_workspace
sudo chown -R $CLOUD9_USER:$CLOUD9_USER /home/$CLOUD9_USER/cloud9_workspace

# Cloud9 yapılandırması (şifreli erişim)
sudo tee /home/$CLOUD9_USER/.config/code-server/config.yaml > /dev/null <<EOL
bind-addr: 127.0.0.1:8181
auth: password
password: $PASSWORD
cert: false
EOL

sudo chown -R $CLOUD9_USER:$CLOUD9_USER /home/$CLOUD9_USER/.config/

# Nginx Konfigürasyonu Cloud9 için (c9.veobu.com)
sudo tee /etc/nginx/sites-available/cloud9 > /dev/null <<EOL
server {
    server_name c9.veobu.com;

    location / {
        proxy_pass http://localhost:8181;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/cloud9 /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Cloud9'u forever ile arka planda başlatma
echo "Cloud9 SDK arka planda başlatılıyor..."
forever start /usr/local/bin/c9 start --listen 0.0.0.0 --port 8181 -w /home/$CLOUD9_USER/cloud9_workspace

# Cron ile yeniden başlatıldığında otomatik başlatma
(crontab -l 2>/dev/null; echo "@reboot /usr/local/bin/forever start /usr/local/bin/c9 start --listen 0.0.0.0 --port 8181 -w /home/$CLOUD9_USER/cloud9_workspace") | crontab -

# Certbot ile SSL Sertifikası Oluşturma
echo "Certbot ile SSL sertifikası alınıyor..."
sudo certbot --nginx -d c9.veobu.com

echo "Cloud9 SSL ile https://c9.veobu.com adresinden erişilebilir."
