#!/bin/bash

# Sudo kurulumu kontrol et ve kur
if ! dpkg -l | grep -q sudo; then
    echo "Sudo paketi kuruluyor..."
    apt install sudo -y
fi
sudo apt update
sudo apt install locales
sudo dpkg-reconfigure locales
cat /etc/default/locale
locale

# Locale ayarları
echo "Locale ayarları yapılıyor..."
sudo locale-gen en_US.UTF-8
sudo locale-gen en_GB.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_GB.UTF-8
sudo dpkg-reconfigure -f noninteractive locales

# Sistem güncelleme ve yükseltme
echo "Sistem güncelleniyor..."
sudo apt update && sudo apt upgrade -y

# Temel paketlerin kurulumu
echo "Temel paketler kuruluyor: build-essential, curl, git, wget, python3, pip"
sudo apt install build-essential curl git wget python3 python3-pip software-properties-common -y

# Node.js ve Yarn Kurulumu
echo "Node.js ve Yarn kuruluyor..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install --global yarn

# Docker Kurulumu
echo "Docker kuruluyor..."
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce -y
sudo systemctl enable docker
sudo systemctl start docker

# Python ve Docker sürümlerini kontrol et
python3 --version
pip3 --version
node -v
yarn -v
docker --version
