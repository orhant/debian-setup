#!/bin/bash

# Nginx Kurulumu
echo "Nginx kuruluyor..."
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

# UFW Nginx profilleri ile yapılandırma (UFW zaten kurulu, sadece Nginx yapılandırması)
echo "UFW Nginx profilleri ile yapılandırma yapılıyor..."
sudo ufw app list

# Eğer 'Nginx Full' profili yoksa HTTP ve HTTPS portlarını aç
if ! sudo ufw app info 'Nginx Full' &>/dev/null; then
    sudo ufw allow 'Nginx HTTP'
    sudo ufw allow 'Nginx HTTPS'
else
    sudo ufw allow 'Nginx Full'
fi

# PHP ve Gerekli Modüllerin Kurulumu
echo "PHP kuruluyor..."
sudo apt install php php-fpm php-mysql php-cli php-curl php-zip php-gd php-mbstring php-xml php-json -y
php -v

# MariaDB Kurulumu
echo "MariaDB kuruluyor..."
sudo apt install mariadb-server mariadb-client -y
sudo systemctl start mariadb
sudo systemctl enable mariadb

# MariaDB Güvenlik Yapılandırması
echo "MariaDB güvenlik yapılandırması yapılıyor..."
sudo mysql_secure_installation

# MariaDB'ye Kök Kullanıcısı Olarak Giriş Yapma
echo "MariaDB'ye kök kullanıcısı olarak giriş yapılacak..."
sudo mysql -u root -p -e "SELECT USER();"

# Root kullanıcısı için yeni şifre belirleme
read -sp "MariaDB root kullanıcısı için yeni bir şifre girin: " NEW_ROOT_PASSWORD
echo
read -sp "Şifreyi tekrar girin: " NEW_ROOT_PASSWORD_CONFIRM
echo

if [ "$NEW_ROOT_PASSWORD" != "$NEW_ROOT_PASSWORD_CONFIRM" ]; then
    echo "Şifreler uyuşmuyor. Lütfen tekrar deneyin."
    exit 1
fi

echo "MariaDB root kullanıcısı şifresi ayarlanıyor..."
sudo mysql -u root -p -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$NEW_ROOT_PASSWORD'; FLUSH PRIVILEGES;"
sudo mysql -u root -p -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$NEW_ROOT_PASSWORD'; FLUSH PRIVILEGES;"


# Nginx yapılandırmasının yedeğini alma
echo "Nginx yapılandırması yedekleniyor..."
TIMESTAMP=$(date +%F_%H-%M-%S)
mkdir ~/nginx-backup-$TIMESTAMP
sudo cp -a /etc/nginx ~/nginx-backup-$TIMESTAMP

# WordPress Nginx yapılandırmasını GitHub'dan indirme
echo "WordPress Nginx yapılandırması indiriliyor..."
sudo apt install git -y
git clone https://github.com/orhant/wordpress-nginx ~/git/wordpress-nginx

# WordPress Nginx yapılandırmasını uygulama
echo "WordPress Nginx yapılandırması uygulanıyor..."
sudo cp -a ~/git/wordpress-nginx/* /etc/nginx/
sudo mkdir -p /etc/nginx/sites-enabled &> /dev/null
sudo cp /etc/nginx/nginx.conf /etc/nginx/

# /etc/nginx/sites-enabled altındaki dosyaları temizleme
echo "/etc/nginx/sites-enabled altındaki dosyalar temizleniyor..."
sudo rm -rf /etc/nginx/sites-enabled/*

# /etc/nginx/sites-available/default.conf dosyasını etkinleştirme
echo "/etc/nginx/sites-available/default.conf dosyası etkinleştiriliyor..."
sudo ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

# /etc/nginx/nginx.conf dosyasını güncelleme
 


# Nginx servisini yeniden başlatma
sudo systemctl reload nginx

# Certbot kurulumu ve SSL yapılandırması (Eğer Certbot yüklü değilse)
if ! command -v certbot &>/dev/null; then
    echo "Certbot kuruluyor..."
    sudo apt install certbot python3-certbot-nginx -y
fi

# wp_create betiğini /usr/local/bin'e kopyalayıp çalıştırılabilir hale getirme
echo "wp_create betiği oluşturuluyor..."
sudo cp wp_create.sh /usr/local/bin/wp_create
sudo chmod +x /usr/local/bin/wp_create

echo "wp_create komutu başarıyla oluşturuldu. Artık terminalde 'wp_create' komutunu kullanabilirsiniz."
