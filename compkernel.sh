#!/bin/bash

function erreur {
    echo "Erreur : $1"
    exit 1
}

if [ "$EUID" -ne 0 ]; then
    erreur "Ce script doit être exécuté avec des privilèges root. Utilisez sudo."
fi

if [ -z "$1" ]; then
    erreur "Veuillez spécifier la version du noyau comme argument. Exemple : ./kernelcompil.sh 6.9.4"
fi

KERNEL_VERSION=$1

KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v$(echo $KERNEL_VERSION | cut -d. -f1).x/linux-$KERNEL_VERSION.tar.xz"
KERNEL_ARCHIVE="linux-$KERNEL_VERSION.tar.xz"
KERNEL_FOLDER="linux-$KERNEL_VERSION"

echo "Téléchargement du noyau $KERNEL_VERSION..."
wget $KERNEL_URL || erreur "Échec du téléchargement du noyau"

echo "Extraction de l'archive..."
tar -xf $KERNEL_ARCHIVE || erreur "Échec de l'extraction de l'archive"

cd $KERNEL_FOLDER || erreur "Échec de l'accès au répertoire du noyau"

echo "Nettoyage avant compilation..."
make -j$(nproc) mrproper || erreur "Échec de mrproper"

echo "Installation des dépendances..."
dnf install -y ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel grub2 || erreur "Échec de l'installation des dépendances"

echo "Configuration du noyau..."
cp /boot/config-$(uname -r) .config || erreur "Échec de la copie de la configuration actuelle"
make -j$(nproc) oldconfig || erreur "Échec de la configuration"

echo "Compilation du noyau..."
make -j$(nproc) -j$(nproc) || erreur "Échec de la compilation du noyau"

echo "Compilation des modules..."
make -j$(nproc) modules_install || erreur "Échec de la compilation des modules"

echo "Installation du noyau..."
make -j$(nproc) install || erreur "Échec de l'installation du noyau"

echo "Mise à jour de GRUB..."
grub2-mkconfig -o /boot/grub2/grub.cfg || erreur "Échec de la mise à jour de GRUB"

echo "Installation du noyau $KERNEL_VERSION terminée. Veuillez redémarrer votre système."

exit 0
