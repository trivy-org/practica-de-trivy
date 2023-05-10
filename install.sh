#!/bin/bash

# +--------------------+
# GENERAL
# +--------------------+

## Installs dependencies for Trivy course

## Tested on (3/2021):
## Kali Linux 2021.1.0
## Ubuntu 20.04 (we'll use this script on an Ubuntu build server later in the course)

# NOTE: This script is NOT guaranteed to work into the future
# (packages can be removed from package repositories, etc.)

# +--------------------+
# MAIN INSTALLATION LOGIC
# +--------------------+

export DEBIAN_FRONTEND=noninteractive

#distro="bullseye"

distro="$(lsb_release -sc)"

sudo apt-get -y update &&\
    sudo apt-get -y install wget \
        apt-transport-https \
        gnupg  &&\
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key |
        sudo apt-key add - &&\
    echo deb https://aquasecurity.github.io/trivy-repo/deb $distro main |
        sudo tee -a /etc/apt/sources.list.d/trivy.list &&\
    sudo apt-get update && sudo apt-get install -y trivy

sudo wget -O /usr/local/bin/container-diff \
    https://storage.googleapis.com/container-diff/v0.16.0/container-diff-linux-amd64 &&\
    sudo chmod +x /usr/local/bin/container-diff

if [[ "$GITHUB_ACTIONS" == "true" ]]; then
    echo "Running within Github Actions.  Docker is already installed"
else
    sudo apt-get install -y docker.io &&\
        sudo usermod -aG docker $USER
fi

echo "----------------------------------------------------------------"
echo "Instalación finalizada!"
echo "----------------------------------------------------------------"
