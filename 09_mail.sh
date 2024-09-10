#!/bin/bash

# Domain adını alın
read -p "Mail domain adını girin (örn: mail.veobu.com): " DOMAIN_NAME

# Postfix ve Dovecot Kurulumu
echo "Postfix ve Dovecot kuruluyor..."
sudo apt install postfix dovecot-core dovecot-imapd opendkim opendkim-tools -y 
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
sudo tee /etc/nginx/sites-available/$DOMAIN_NAME.conf > /dev/null <<EOL
server {
    server_name $DOMAIN_NAME;

    root /usr/share/roundcube;
    index index.php index.html index.htm;

    access_log /var/log/nginx/$DOMAIN_NAME.access.log;
    error_log /var/log/nginx/$DOMAIN_NAME.error.log;

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

# Yapılandırmayı etkinleştirme (sites-enabled dizinine sembolik link oluşturma)
sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME.conf /etc/nginx/sites-enabled/

# Nginx'i yeniden başlatma
sudo systemctl reload nginx

# Certbot SSL Sertifikası Oluşturma
echo "Certbot ile SSL sertifikası alınıyor..."
sudo certbot --nginx -d $DOMAIN_NAME

echo "Roundcube Webmail SSL ile https://$DOMAIN_NAME adresinden erişilebilir."

# add_mail_domain betiğini /usr/local/bin'e kopyalayıp çalıştırılabilir hale getirme
echo "add_mail_domain betiği oluşturuluyor..."
sudo cp add_mail_domain.sh /usr/local/bin/add_mail_domain
sudo chmod +x /usr/local/bin/add_mail_domain

echo "add_mail_domain komutu başarıyla oluşturuldu. Artık terminalde 'add_mail_domain' komutunu kullanabilirsiniz."
