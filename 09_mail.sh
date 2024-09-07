#!/bin/bash

# Postfix ve Dovecot Kurulumu
echo "Postfix ve Dovecot kuruluyor..."
sudo apt install postfix dovecot-core dovecot-imapd -y
sudo systemctl enable postfix dovecot
sudo systemctl start postfix dovecot

# Postfix ve Dovecot UFW ayarları
sudo ufw allow 25/tcp   # SMTP
sudo ufw allow 587/tcp  # SMTPS
sudo ufw allow 465/tcp  # SMTP SSL
sudo ufw allow 143/tcp  # IMAP
sudo ufw allow 993/tcp  # IMAP SSL
sudo ufw allow 110/tcp  # POP3
sudo ufw allow 995/tcp  # POP3 SSL

# Roundcube Webmail Kurulumu
echo "Roundcube Webmail kuruluyor..."
sudo apt install roundcube roundcube-core roundcube-mysql roundcube-plugins -y

# Nginx Konfigürasyonu Roundcube için
echo "Nginx Roundcube için yapılandırılıyor..."
sudo tee /etc/nginx/sites-available/roundcube > /dev/null <<EOL
server {
    server_name mail.veobu.com;

    root /usr/share/roundcube;
    index index.php index.html index.htm;

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

sudo ln -s /etc/nginx/sites-available/roundcube /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Certbot SSL Sertifikası Oluşturma
echo "Certbot ile SSL sertifikası alınıyor..."
sudo certbot --nginx -d mail.veobu.com

echo "Roundcube Webmail SSL ile https://mail.veobu.com adresinden erişilebilir."
