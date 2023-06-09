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


if [ ! -d /home/root/ansible ]; then
  mkdir -p /home/root/ansible;
fi

ansible-playbook ./ansible/equinix-playbook.yaml -v