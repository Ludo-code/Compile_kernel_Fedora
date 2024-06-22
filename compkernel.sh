#!/bin/bash

function erreur {
    echo "Erreur : $1"
    exit 1
}

if [ "$EUID" -ne 0 ]; then
    erreur "Ce script doit être exécuté avec des privilèges root. Utilisez sudo."
fi

read -p "Entrez la version du noyau à installer (ex: 5.12.9) : " KERNEL_VERSION

KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v$(echo $KERNEL_VERSION | cut -d. -f1).x/linux-$KERNEL_VERSION.tar.xz"
KERNEL_ARCHIVE="linux-$KERNEL_VERSION.tar.xz"
KERNEL_FOLDER="linux-$KERNEL_VERSION"

echo "Téléchargement du noyau $KERNEL_VERSION..."
wget $KERNEL_URL || erreur "Échec du téléchargement du noyau"

echo "Extraction de l'archive..."
tar -xf $KERNEL_ARCHIVE || erreur "Échec de l'extraction de l'archive"

cd $KERNEL_FOLDER || erreur "Échec de l'accès au répertoire du noyau"

echo "Installation des dépendances..."
dnf install -y ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel grub2 || erreur "Échec de l'installation des dépendances"

echo "Configuration du noyau..."
cp /boot/config-$(uname -r) .config || erreur "Échec de la copie de la configuration actuelle"
make olddefconfig || erreur "Échec de la configuration"

echo "Nettoyage avant compilation..."
make clean || erreur "Échec du nettoyage"
make mrproper || erreur "Échec de mrproper"

echo "Compilation du noyau..."
make -j$(nproc) || erreur "Échec de la compilation du noyau"

echo "Compilation des modules..."
make modules_install || erreur "Échec de la compilation des modules"

echo "Installation du noyau..."
make install || erreur "Échec de l'installation du noyau"

echo "Mise à jour de GRUB..."
grub2-mkconfig -o /boot/grub2/grub.cfg || erreur "Échec de la mise à jour de GRUB"

echo "Installation du noyau $KERNEL_VERSION terminée. Veuillez redémarrer votre système."

exit 0
