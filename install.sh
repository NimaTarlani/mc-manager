#!/bin/bash

GITHUB_URL="https://raw.githubusercontent.com/NimaTarlani/mc-manager/main/mc-manager.sh"
INSTALL_PATH="/usr/local/bin/mc-manager"


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

check_command() {
    command -v "$1" &> /dev/null
}

install_package() {
    PACKAGE=$1
    echo "$PACKAGE is not installed. Installing..."
    if [ -x "$(command -v apt)" ]; then
        sudo apt update && sudo apt install -y "$PACKAGE"
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y "$PACKAGE"
    elif [ -x "$(command -v pacman)" ]; then
        sudo pacman -Sy --noconfirm "$PACKAGE"
    else
        echo "Unsupported package manager. Please install $PACKAGE manually."
        exit 1
    fi
}

if check_command wget; then
    echo "wget is already installed."
else
    install_package wget
fi

if check_command unzip; then
    echo "unzip is already installed."
else
    install_package unzip
fi

echo "All required dependencies are installed."

echo "Downloading mc-manager.sh from $GITHUB_URL..."
curl -o mc-manager.sh "$GITHUB_URL"
if [[ $? -ne 0 ]]; then
    echo "Failed to download the file." >&2
    exit 1
fi

echo "Setting file permissions..."
chmod +x mc-manager.sh

echo "Installing mc-manager as a Linux command..."
mv mc-manager.sh "$INSTALL_PATH"
if [[ $? -ne 0 ]]; then
    echo "Failed to move the file to $INSTALL_PATH." >&2
    exit 1
fi

echo "Installation completed successfully! You can now run 'mc-manager'."
mc-manager
exit 0
