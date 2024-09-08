# Debian Setup Scripts

Bu repo, Debian üzerinde çeşitli yazılımları ve servisleri kurmak için gereken bash scriptlerini içerir. Her script farklı bir sunucu yapılandırma adımını otomatik hale getirir.

## Adım Adım Kurulum

### 1. Git Kurulumu
Eğer Git makinenizde kurulu değilse, önce Git'i kurun:

```bash
apt install sudo -y
sudo apt update
sudo apt install git -y 
```
### 2. Repo'yu Klonlayın
Klonlama işlemini gerçekleştirmek için aşağıdaki komutu kullanın:

```bash
git clone https://github.com/orhant/debian-setup.git
```

### 3. Klonlanan dizine gidin:

```bash
cd debian-setup
```

### 4. Scriptleri çalıştırılabilir hale getirin:

```bash
chmod +x *.sh
```
### 5. Scriptleri sırayla çalıştırın ve sorulara cevap verin:

####  01_update.sh
Bu script sistem güncellemesi ve temel paketlerin kurulumu için kullanılır.

```bash
./01_update.sh
```

####  02_security.sh
Bu script UFW (güvenlik duvarı) ve Fail2Ban güvenlik yapılandırması içindir.

```bash
./02_security.sh
```

####  03_webserver.sh
Bu script Nginx, PHP ve MariaDB kurulumunu yapar.

```bash
./03_webserver.sh
```

####  04_certbot.sh
Bu script Let's Encrypt (Certbot) kullanarak SSL sertifikası kurar.

```bash
./04_certbot.sh
```

####  05_phpmyadmin.sh
Bu script phpMyAdmin kurulumu ve Nginx yapılandırmasını yapar.

```bash
./05_phpmyadmin.sh
```

####  06_code-server.sh
Bu script Code-Server kurulumunu yapar.

```bash
./06_code-server.sh
```

####  07_webmin.sh
Bu script Webmin kurulumunu ve Nginx ile SSL entegrasyonunu yapar.

```bash
./07_webmin.sh
```

####  08_cdsdk.sh
Bu script Cloud9 SDK kurulumunu yapar.

```bash
./08_cdsdk.sh
```

####  09_mail.sh
Bu script Postfix, Dovecot ve Roundcube mail sunucusunu kurar

```bash
./09_mail.sh
```