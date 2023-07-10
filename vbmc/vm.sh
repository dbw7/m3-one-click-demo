#!/bin/bash

set -e

set -o pipefail

echo "This script assumes you've already ran the m3 one click demo script.
"

echo -e "Having SLE-Micro.x86_64-5.4.0-Default-GM.raw.xz within the current directory is
a requirement for this script, continue? (y/n)"

read continue

if [[ $continue != "y" ]]; then
    echo "Exiting"
    exit
fi

if [[ ! -f SLE-Micro.x86_64-5.4.0-Default-GM.raw.xz ]]; then
    echo "File doesn't exist within current directory, exiting"
    exit
fi

mkdir vbmc
cp SLE-Micro.x86_64-5.4.0-Default-GM.raw.xz /vbmc
cd vbmc

# SLE-Micro requires your email and registration code, this can be generated through your account

echo -e "Please enter your email for your SUSE account"
read email

echo -e "Please enter your SLE Micro registration code"
read code

# We unzip the file and do all of the necessary VM prep

echo "Unzipping SLE"
xz -d SLE-Micro.x86_64-5.4.0-Default-GM.raw.xz 
echo "Finished unzipping"

echo "Resizing and converting image"
qemu-img resize -f raw ./SLE-Micro.x86_64-5.4.0-Default-GM.raw 30G > /dev/null

qemu-img convert -O qcow2 SLE-Micro.x86_64-5.4.0-Default-GM.raw slemicro1

cp slemicro1 slemicro2

cp slemicro1 slemicro3

echo "Finished resizing and converting"

echo "Creating ignition and combustion"

TMPDIR=$(mktemp -d)
mkdir -p ${TMPDIR}/{combustion,ignition}

cat << 'EOF' > ${TMPDIR}/config.fcc 
variant: fcos 
version: 1.4.0 
storage: 
  files: 
    - path: /etc/hostname 
      mode: 0644 
      overwrite: true 
      contents: 
        inline: "slemicro" 
passwd: 
  users: 
   - name: root 
     password_hash: "$y$j9T$/t4THH10B7esLiIVBROsE.$G1lyxfy/MoFVOrfXSnWAUq70Tf3mjfZBIe18koGOuXB" 
EOF
cat << EOF > ${TMPDIR}/combustion/script  
#!/bin/bash 
# combustion: network 

# Redirect output to the console 
exec > >(exec tee -a /dev/tty0) 2>&1

# Set hostname at combustion phase for SUSEConnect
hostname slemicro

# Registration 
if ! which SUSEConnect > /dev/null 2>&1; then 
    zypper --non-interactive install suseconnect-ng 
fi 

SUSEConnect --email $email --url https://scc.suse.com --regcode $code

# Leave a marker 
echo "Configured with combustion" > /etc/issue.d/combustion 
EOF

wget https://github.com/coreos/butane/releases/download/v0.18.0/butane-x86_64-unknown-linux-gnu

mv butane-x86_64-unknown-linux-gnu butane

chmod +x ./butane

./butane -p -o ${TMPDIR}/ignition/config.ign ${TMPDIR}/config.fcc

mkisofs -full-iso9660-filenames -o ignition-and-combustion.iso -V ignition ${TMPDIR}

rm -Rf ${TMPDIR}

# Need to define default pool for redfish to work properly

virsh pool-define-as default dir - - - - "/default"
virsh pool-build default
virsh pool-start default
virsh pool-autostart default

cp slemicro1 /var/lib/libvirt/images
cp slemicro2 /var/lib/libvirt/images
cp slemicro3 /var/lib/libvirt/images
cp ignition-and-combustion.iso /var/lib/libvirt/images

echo "Finished creating ignition and combustion scripts"

echo "Installing apache-utils, podman, and sushy-tools"

sudo apt install apache2-utils -y
pip install sushy-tools
sudo DEBIAN_FRONTEND=noninteractive apt install podman -y

if [ ! -d "/root/vbmc" ]; then
  mkdir /root/vbmc
fi

# We create 3 VMs that act as bare metal hosts

echo "Creating 3 virtual nodes"

virt-install --name node-1 --memory 4096 --vcpus 2 --disk /var/lib/libvirt/images/slemicro1 --import --cdrom /var/lib/libvirt/images/ignition-and-combustion.iso --network bridge=m3-prov,model=virtio --osinfo detect=on,name=sle-unknown --console pty,target_type=virtio --noautoconsole --graphics vnc --boot nvram.template=/usr/share/OVMF/OVMF_VARS.fd --boot loader=/usr/share/OVMF/OVMF_CODE.secboot.fd --boot loader.secure=no --boot loader.type=pflash --boot loader.readonly=yes --debug -v --machine pc-q35-5.1 --noautoconsole

virt-install --name node-2 --memory 4096 --vcpus 2 --disk /var/lib/libvirt/images/slemicro2 --import --cdrom /var/lib/libvirt/images/ignition-and-combustion.iso --network bridge=m3-prov,model=virtio --osinfo detect=on,name=sle-unknown --console pty,target_type=virtio --noautoconsole --graphics vnc --boot nvram.template=/usr/share/OVMF/OVMF_VARS.fd --boot loader=/usr/share/OVMF/OVMF_CODE.secboot.fd --boot loader.secure=no --boot loader.type=pflash --boot loader.readonly=yes --debug -v --machine pc-q35-5.1 --noautoconsole

virt-install --name node-3 --memory 4096 --vcpus 2 --disk /var/lib/libvirt/images/slemicro3 --import --cdrom /var/lib/libvirt/images/ignition-and-combustion.iso --network bridge=m3-prov,model=virtio --osinfo detect=on,name=sle-unknown --console pty,target_type=virtio --noautoconsole --graphics vnc --boot nvram.template=/usr/share/OVMF/OVMF_VARS.fd --boot loader=/usr/share/OVMF/OVMF_CODE.secboot.fd --boot loader.secure=no --boot loader.type=pflash --boot loader.readonly=yes --debug -v --machine pc-q35-5.1 --noautoconsole

echo "Finished creating 3 virtual nodes"
echo "Starting sushy-tools podman"

cd /root/vbmc

IP_ADDR=$(ifconfig | grep "bond0: " -A 1 | awk '/inet / {print $2}')

echo $IP_ADDR

cat << EOF > /root/vbmc/sushy.config
SUSHY_EMULATOR_AUTH_FILE = '/root/vbmc/auth.conf'
SUSHY_EMULATOR_SSL_CERT = '/root/vbmc/cert.pem'
SUSHY_EMULATOR_SSL_KEY = '/root/vbmc/key.pem'
SUSHY_EMULATOR_LISTEN_IP = '0.0.0.0'
SUSHY_EMULATOR_VMEDIA_DEVICES = {
    "Cd": {
        "Name": "Virtual CD",
        "MediaTypes": [
            "CD",
            "DVD"
        ]
    },
    "Floppy": {
        "Name": "Virtual Removable Media",
        "MediaTypes": [
            "Floppy",
            "USBStick"
        ]
    }
}
EOF

htpasswd -b -B -c auth.conf foo foo

openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 365 --noenc -subj "/C=/ST=/L=/O=/OU=/CN="


# We run sushy-tools in podman so that it is running in the background

sudo podman run -d --rm  --privileged  --name sushy-tools   -v ${HOME}/vbmc:/root/vbmc:Z   -v /var/run/libvirt:/var/run/libvirt:Z   -e SUSHY_EMULATOR_CONFIG=/root/vbmc/sushy.config   -p 8000:8000   quay.io/metal3-io/sushy-tools:latest sushy-emulator
echo "Finished starting sushy-tools podman"

echo "Sleeping for 10 seconds to make sure podman has started"
sleep 10s

# We automatically grab the mac address of each vm and the sushy-tools id of each vm

NODE1ID=$(curl -L https://$IP_ADDR:8000/redfish/v1/Systems/node-1 -k -u "foo:foo" | jq -r '.UUID')
NODE2ID=$(curl -L https://$IP_ADDR:8000/redfish/v1/Systems/node-2 -k -u "foo:foo" | jq -r '.UUID')
NODE3ID=$(curl -L https://$IP_ADDR:8000/redfish/v1/Systems/node-3 -k -u "foo:foo" | jq -r '.UUID')

echo $NODE1ID
echo $NODE2ID
echo $NODE3ID

NODE1MAC=$(virsh dumpxml node-1 | grep 'mac address' | grep -ioE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
NODE2MAC=$(virsh dumpxml node-2 | grep 'mac address' | grep -ioE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
NODE3MAC=$(virsh dumpxml node-3 | grep 'mac address' | grep -ioE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")

echo $NODE1MAC
echo $NODE2MAC
echo $NODE3MAC

# We create custom BMH yamls using the data we collected earlier

cat << EOF > /root/vbmc/node1.yaml
apiVersion: v1
kind: Secret
metadata:
  name: bmc-1-credentials
  namespace: default
type: Opaque
data:
  username: Zm9vCg==
  password: Zm9vCg==
---
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: bmc-1
  namespace: default
  labels:
    cluster-role: worker
spec:
  online: true
  bootMACAddress: $NODE1MAC
  bmc:
    address: redfish-virtualmedia://$IP_ADDR:8000/redfish/v1/Systems/$NODE1ID
    disableCertificateVerification: true
    credentialsName: bmc-1-credentials
EOF

cat << EOF > /root/vbmc/node2.yaml
apiVersion: v1
kind: Secret
metadata:
  name: bmc-2-credentials
  namespace: default
type: Opaque
data:
  username: Zm9vCg==
  password: Zm9vCg==
---
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: bmc-2
  namespace: default
  labels:
    cluster-role: worker
spec:
  online: true
  bootMACAddress: $NODE2MAC
  bmc:
    address: redfish-virtualmedia://$IP_ADDR:8000/redfish/v1/Systems/$NODE2ID
    disableCertificateVerification: true
    credentialsName: bmc-2-credentials
EOF

cat << EOF > /root/vbmc/node3.yaml
apiVersion: v1
kind: Secret
metadata:
  name: bmc-3-credentials
  namespace: default
type: Opaque
data:
  username: Zm9vCg==
  password: Zm9vCg==
---
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: bmc-3
  namespace: default
  labels:
    cluster-role: worker
spec:
  online: true
  bootMACAddress: $NODE3MAC
  bmc:
    address: redfish-virtualmedia://$IP_ADDR:8000/redfish/v1/Systems/$NODE3ID
    disableCertificateVerification: true
    credentialsName: bmc-3-credentials
EOF

# In order for this to work properly with SLE micro, we need to add suse.autologin on multiple lines within the ironic config map
# Here we create a script that does this, then move it to the metal3 core vm using ansible

cat << EOF > /root/vbmc/config.sh
sed -i '289s#.*#    kernel --timeout 60000 {{ env.IRONIC_BOOT_BASE_URL }}/images/ironic-python-agent.kernel suse.autologin ipa-insecure=1 ipa-inspection-collectors=default,extra-hardware,logs systemd.journald.forward_to_console=yes BOOTIF=${mac} ipa-debug=1 ipa-enable-vlan-interfaces={{ env.IRONIC_INSPECTOR_VLAN_INTERFACES }} ipa-inspection-dhcp-all-interfaces=1 ipa-collect-lldp=0 {{ env.INSPECTOR_EXTRA_ARGS }} initrd=ironic-python-agent.initramfs {% if env.IRONIC_RAMDISK_SSH_KEY %}sshkey="{{ env.IRONIC_RAMDISK_SSH_KEY|trim }}"{% endif %} {{ env.IRONIC_KERNEL_PARAMS|trim }} || goto retry_boot#' output.yaml

sed -i '728s#.*#    kernel_append_params = nofb nomodeset vga=normal suse.autologin ipa-insecure={{ env.IPA_INSECURE }} {% if env.IRONIC_RAMDISK_SSH_KEY %}sshkey="{{ env.IRONIC_RAMDISK_SSH_KEY|trim }}"{% endif %} {{ env.IRONIC_KERNEL_PARAMS|trim }}#' output.yaml

sed -i '733s#.*#    kernel_append_params = nofb nomodeset vga=normal suse.autologin ipa-insecure={{ env.IPA_INSECURE }} {% if env.IRONIC_RAMDISK_SSH_KEY %}sshkey="{{ env.IRONIC_RAMDISK_SSH_KEY|trim }}"{% endif %} {{ env.IRONIC_KERNEL_PARAMS|trim }}#' output.yaml
EOF

# We run an ansible playbook that completes setting up the VBMC BMHs
curl https://raw.githubusercontent.com/dbw7/m3-one-click-demo/main/vbmc/playbook.yaml > ~/vbmc/playbook.yaml
ansible-playbook playbook.yaml -vvv