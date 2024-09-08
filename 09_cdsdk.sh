#!/bin/bash

# Cloud9 SDK Kurulumu
echo "Cloud9 SDK kuruluyor..."
git clone git://github.com/c9/core.git c9sdk
cd c9sdk
scripts/install-sdk.sh

# Forever paketinin kurulumu
echo "Forever paketi kuruluyor..."
sudo npm install -g forever

# Cloud9 Kullanıcı Dizini
read -p "Cloud9 için bir kullanıcı adı girin: " CLOUD9_USER

# Kullanıcı oluşturma
if id "$CLOUD9_USER" &>/dev/null; then
    echo "Kullanıcı zaten mevcut: $CLOUD9_USER"
else
    echo "Kullanıcı oluşturuluyor: $CLOUD9_USER"
    sudo adduser --disabled-password --gecos "" $CLOUD9_USER
fi

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
echo "Cloud9 çalışma dizini oluşturuluyor..."
sudo mkdir -p /home/$CLOUD9_USER/cloud9_workspace
sudo chown -R $CLOUD9_USER:$CLOUD9_USER /home/$CLOUD9_USER/cloud9_workspace

# Cloud9 yapılandırması
echo "Cloud9 yapılandırması yapılıyor..."
sudo tee /home/$CLOUD9_USER/.config/code-server/config.yaml > /dev/null <<EOL
bind-addr: 127.0.0.1:8181
auth: password
password: $PASSWORD
cert: false
EOL

sudo chown -R $CLOUD9_USER:$CLOUD9_USER /home/$CLOUD9_USER/.config/

# Cloud9'ı başlat
echo "Cloud9 başlatılıyor..."
sudo -u $CLOUD9_USER forever start /path/to/c9sdk/server.js --listen 127.0.0.1 --port 8181 --user $CLOUD9_USER --password $PASSWORD --workspaces /home/$CLOUD9_USER/cloud9_workspace

# Nginx Konfigürasyonu Cloud9 için (c9.veobu.com)
echo "Nginx yapılandırması yapılıyor..."
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

echo "Cloud9 kurulumu ve yapılandırması tamamlandı."
