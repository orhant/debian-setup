#!/bin/bash

# Certbot ve Nginx entegrasyonu
echo "Certbot kuruluyor..."
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx
