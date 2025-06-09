#!/bin/bash

GITHUB_URL="https://raw.githubusercontent.com/NimaTarlani/mc-manager/main/mcmanager.sh"
INSTALL_PATH="/usr/local/bin/mcmanager"


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

echo "Downloading mcmanager.sh from $GITHUB_URL..."
curl -o mcmanager.sh "$GITHUB_URL"
if [[ $? -ne 0 ]]; then
    echo "Failed to download the file." >&2
    exit 1
fi

echo "Setting file permissions..."
chmod +x mcmanager.sh

echo "Installing mcmanager as a Linux command..."
mv mcmanager.sh "$INSTALL_PATH"
if [[ $? -ne 0 ]]; then
    echo "Failed to move the file to $INSTALL_PATH." >&2
    exit 1
fi

echo "Installation completed successfully! You can now run 'mcmanager'."
mcmanager
exit 0
