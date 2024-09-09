#!/bin/bash

# Yeni domain eklemek için kullanıcıdan domain adını al
read -p "Yeni domain adını girin (örn: example.com): " DOMAIN_NAME

# Opendkim yapılandırma dosyasının olup olmadığını kontrol et
OPENDKIM_CONF="/etc/opendkim.conf"
if [ ! -f "$OPENDKIM_CONF" ]; then
    echo "Opendkim yapılandırma dosyası bulunamadı. Opendkim yapılandırılıyor..."

    # Opendkim yapılandırma dosyasını oluştur
    sudo tee $OPENDKIM_CONF > /dev/null <<EOL
Domain                  *
KeyTable                /etc/opendkim/KeyTable
SigningTable            /etc/opendkim/SigningTable
ExternalIgnoreList      /etc/opendkim/TrustedHosts
InternalHosts           /etc/opendkim/TrustedHosts
Socket                  inet:8891@localhost
EOL

    # Gerekli Opendkim dizinlerini oluştur
    sudo mkdir -p /etc/opendkim/{keys,KeyTable,SigningTable,TrustedHosts}

    # TrustedHosts dosyasına localhost'u ekle
    sudo tee /etc/opendkim/TrustedHosts > /dev/null <<EOL
127.0.0.1
localhost
*.${DOMAIN_NAME}
EOL

    echo "Opendkim yapılandırması tamamlandı."
fi

# Yeni domain için DKIM anahtarları oluşturma
KEY_DIR="/etc/opendkim/keys/$DOMAIN_NAME"
if [ ! -d "$KEY_DIR" ]; then
    echo "Yeni domain için DKIM anahtarları oluşturuluyor..."
    sudo mkdir -p "$KEY_DIR"
    sudo opendkim-genkey -D "$KEY_DIR" -d "$DOMAIN_NAME" -s default
    sudo chown opendkim:opendkim "$KEY_DIR/default.private"
    sudo chmod 600 "$KEY_DIR/default.private"

    # KeyTable dosyasına yeni domain ekle
    echo "KeyTable güncelleniyor..."
    sudo tee -a /etc/opendkim/KeyTable > /dev/null <<EOL
default._domainkey.${DOMAIN_NAME} ${DOMAIN_NAME}:default:/etc/opendkim/keys/${DOMAIN_NAME}/default.private
EOL

    # SigningTable dosyasına yeni domain ekle
    echo "SigningTable güncelleniyor..."
    sudo tee -a /etc/opendkim/SigningTable > /dev/null <<EOL
*@$DOMAIN_NAME default._domainkey.${DOMAIN_NAME}
EOL

    echo "Yeni domain için DKIM ayarları tamamlandı."
else
    echo "Bu domain için zaten DKIM anahtarları mevcut."
fi

# Postfix yapılandırmasını kontrol et ve gerekli ayarları ekle
POSTFIX_MAIN_CF="/etc/postfix/main.cf"
if ! grep -q "smtpd_milters" "$POSTFIX_MAIN_CF"; then
    echo "Postfix yapılandırması düzenleniyor..."
    sudo tee -a "$POSTFIX_MAIN_CF" > /dev/null <<EOL
milter_default_action = accept
milter_protocol = 2
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
EOL
    sudo systemctl restart postfix
fi

# Opendkim ve Postfix'i yeniden başlat
echo "Opendkim ve Postfix yeniden başlatılıyor..."
sudo systemctl restart opendkim
sudo systemctl restart postfix

# DKIM DNS kaydını göster
echo "DKIM DNS kaydınız:"
cat "$KEY_DIR/default.txt"
echo "Lütfen DNS sağlayıcınıza yukarıdaki TXT kaydını ekleyin."

echo "$DOMAIN_NAME domaini başarıyla eklendi!"
