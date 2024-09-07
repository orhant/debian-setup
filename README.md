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