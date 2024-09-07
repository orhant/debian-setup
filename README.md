# Debian Setup Scripts

Bu repo, Debian üzerinde çeşitli yazılımları ve servisleri kurmak için gereken bash scriptlerini içerir. Her script farklı bir sunucu yapılandırma adımını otomatik hale getirir.

## Adım Adım Kurulum

### 1. Git Kurulumu
Eğer Git makinenizde kurulu değilse, önce Git'i kurun:

```bash
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
