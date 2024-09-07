#!/bin/bash

# UFW Kurulumu ve yapılandırma
echo "UFW güvenlik duvarı kuruluyor..."
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw enable

# Fail2Ban Kurulumu
echo "Fail2Ban kuruluyor..."
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
