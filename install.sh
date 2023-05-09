#!/bin/bash

# +--------------------+
# GENERAL
# +--------------------+
# MAIN INSTALLATION LOGIC
# +--------------------+

export DEBIAN_FRONTEND=noninteractive

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
echo "Installation finished!"
echo "----------------------------------------------------------------"
