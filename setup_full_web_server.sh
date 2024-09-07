#!/bin/bash

# Kullanıcıdan sunucu yapılandırması için promptlar
read -p "Node.js versiyonu (varsayılan: 18.x): " NODE_VERSION
NODE_VERSION=${NODE_VERSION:-18.x}

read -p "Code-Server için kurmak istediğiniz kullanıcı adı: " CODE_USER

# Sistem güncelleme ve yükseltme
echo "Sistem güncelleniyor..."
sudo apt update && sudo apt upgrade -y

# Temel paketlerin kurulumu
echo "Temel paketler kuruluyor: build-essential, curl, git, wget"
sudo apt install build-essential curl git wget software-properties-common -y

# Sudo kurulumu ve kullanıcıyı sudo grubuna ekleme
if ! dpkg -l | grep -q sudo; then
    echo "Sudo paketi kuruluyor..."
    sudo apt install sudo -y
fi

echo "Kullanıcıyı sudo grubuna ekliyoruz..."
sudo usermod -aG sudo $USER

# SSH kurulum ve başlatma
echo "SSH kuruluyor ve başlatılıyor..."
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

# UFW güvenlik duvarı kurulumu ve yapılandırması
echo "UFW güvenlik duvarı kuruluyor..."
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable

# Node.js Kurulumu
echo "Node.js kuruluyor..."
curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION | sudo -E bash -
sudo apt install -y nodejs
node -v
npm -v

# Nginx Kurulumu
echo "Nginx kuruluyor..."
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

# MariaDB Kurulumu
echo "MariaDB kuruluyor..."
sudo apt install mariadb-server mariadb-client -y
sudo systemctl start mariadb
sudo systemctl enable mariadb

# MariaDB güvenli kurulum
echo "MariaDB güvenli kurulum başlatılıyor..."
sudo mysql_secure_installation

# PHP ve Gerekli Modüllerin Kurulumu
echo "PHP kuruluyor..."
sudo apt install php php-fpm php-mysql php-cli php-curl php-zip php-gd php-mbstring php-xml php-json -y
php -v

# PHP-FPM'nin Nginx ile çalışması için yapılandırılması
echo "Nginx PHP yapılandırması yapılıyor..."
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm index.nginx-debian.html;

    server_name _;

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

sudo systemctl reload nginx

# phpMyAdmin Kurulumu
echo "phpMyAdmin kuruluyor..."
sudo apt install phpmyadmin -y
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Webmin Kurulumu
echo "Webmin kuruluyor..."
wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
sudo sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
sudo apt update
sudo apt install webmin -y

# Webmin için firewall yapılandırması
sudo ufw allow 10000
sudo systemctl enable webmin
sudo systemctl start webmin

# Certbot Kurulumu
echo "Certbot kuruluyor ve yapılandırılıyor..."
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx

# Postfix ve Dovecot Kurulumu
echo "Postfix ve Dovecot kuruluyor..."
sudo apt install postfix dovecot-core dovecot-imapd -y
sudo systemctl enable postfix dovecot
sudo systemctl start postfix dovecot

# Fail2Ban Kurulumu
echo "Fail2Ban kuruluyor..."
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Code-Server Kurulumu
echo "Code-Server kuruluyor..."
curl -fsSL https://code-server.dev/install.sh | sh
sudo systemctl enable --now code-server@$CODE_USER

# Code-Server konfigürasyonu
echo "Code-Server yapılandırması..."
sudo mkdir -p /home/$CODE_USER/.config/code-server/
sudo tee /home/$CODE_USER/.config/code-server/config.yaml > /dev/null <<EOL
bind-addr: 0.0.0.0:8080
auth: password
password: $(openssl rand -base64 12)
cert: false
EOL

sudo chown -R $CODE_USER:$CODE_USER /home/$CODE_USER/.config/

# Sonlandırma mesajı
echo "Kurulum tamamlandı. Webmin'e http://<sunucu_ip>:10000 ile, phpMyAdmin'e http://<sunucu_ip>/phpmyadmin ile ve Code-Server'a http://<sunucu_ip>:8080 ile erişebilirsiniz."
echo "Sistemi yeniden başlatmanız önerilir."
