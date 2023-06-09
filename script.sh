#!/bin/bash

# Update package lists
sudo apt-get update -y

# Full upgrade
sudo apt-get dist-upgrade -y

# Install install pip3
sudo apt install python3-pip 

#We install ansible
python3 -m pip install ansible

#We set the path in bashrc and source it in case it's incorrect
if ! grep -q 'export PATH="/root/.local/bin:$PATH"' ~/.bashrc ; then
    echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc
fi

# Source bashrc to load new PATH
source ~/.bashrc

#create ansible directory in the home directory if it doesn't exist
if [ ! -d ~/ansible ]; then
  mkdir -p ~/ansible;
fi

#put the equinix playbook in the ansible folder
curl https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/equinix-playbook.yaml > ~/ansible/equinix-playbook.yaml

#put the extra vars file in the ansible directory temporarily
curl https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/equinix-playbook.yaml > ~/ansible/equinix-playbook.yaml

ansible-playbook ~/ansible/equinix-playbook.yaml -v