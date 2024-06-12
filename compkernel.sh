#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
OFF_COLOR='\033[0m'

Fedora_version=$(cat /etc/fedora-release)

if [ "$Fedora_version" = "Fedora release 40 (Forty)" ]; then
    echo -e "${GREEN}Installation des dépendances de dev sur Fedora${OFF_COLOR}"
    sleep 5

    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Veuillez entrer le mot de passe root pour continuer l'installation...${OFF_COLOR}"
        sudo dnf groupinstall "Development Tools"
    else
        dnf groupinstall "Development Tools"
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Installation réussie.${OFF_COLOR}"
    else
        echo -e "${RED}Erreur lors de l'installation.${OFF_COLOR}"
    fi

    echo -e "${YELLOW}Veuillez entrer le numéro de la dernière version du noyau disponible sur kernel.org (ex: 6.6.33):${OFF_COLOR}"
    read kernel_version
    kernel_url="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$kernel_version.tar.xz"
    echo -e "${BLUE}Téléchargement du noyau version $kernel_version...${OFF_COLOR}"
    wget $kernel_url -O linux-$kernel_version.tar.xz

    if [ $? -eq 0 ]; then
    echo -e "${GREEN}Téléchargement réussi.${OFF_COLOR}"
        
    echo -e "${BLUE}Extraction de l'archive...${OFF_COLOR}"
    tar -xf linux-$kernel_version.tar.xz
        
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Extraction réussie.${OFF_COLOR}"
        echo -e "${YELLOW}Entrer dans le répertoire...${OFF_COLOR}"
        cd linux-$kernel_version
        echo -e "${YELLOW}Préparation de la compilation${OFF_COLOR}"
        make mrproper
        make olddefconfig
        echo -e "${YELLOW}Lancement de la compilation du noyau${OFF_COLOR}"
        make
        echo -e "${YELLOW}Installation des modules${OFF_COLOR}"
        make module_install
        echo -e "${YELLOW}Installation du noyau${OFF_COLOR}"
        make install
        echo -e "${YELLOW}Génération du initramfs${OFF_COLOR}"
        mkinitrd /boot/initramfs-$version.img $version
        echo -e "${YELLOW}Changement de la config de grub2${OFF_COLOR}"
        grub-mkconfig -o /boot/grub2/grub.cfg 
    else
        echo -e "${RED}Erreur lors de l'extraction.${OFF_COLOR}"
    fi
    else
        echo -e "${RED}Erreur lors du téléchargement.${OFF_COLOR}"
    fi
else
    echo -e "${RED}Ce script est destiné à Fedora release 40 (Forty) uniquement.${OFF_COLOR}"
fi
