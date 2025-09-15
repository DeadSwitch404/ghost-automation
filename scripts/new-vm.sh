#!/bin/bash

# Create a clone of a template virtual machine
# Usage: $0 <vm-name> <static-ip> [template-vm]

set -e

# === Basic script configuration ===

NAME="${1:-debian13_clone}"
IP="$2"
ORIG="${3:-debian13_image}"

source .env

# === Argument parsing ===

if [[ -z "$IP" ]]; then
    echo "Usage: $0 <VM_NAME> <STATIC_IP> [TEMPLATE_VM]"
    exit 1
fi

# === Clone ===

echo -e "[+] Creating the new virtual machine: ${NAME}..."
virt-clone \
  --original "$ORIG" \
  --name "$NAME" \
  --file "${VMDIR}"/"${NAME}".qcow2

echo -e "[+] Setting the image permissions..."
sudo chown "${OWNER}":"${OWNER}" "${VMDIR}"/"${NAME}".qcow2

# === Set the powered off Debian config ===

echo -e "[+] Customizing the VM config..."
virt-customize -q -d "${NAME}" \
               --install sudo \
               --ssh-inject "${USER}:file:${HOME}/.ssh/id_rsa.pub" \
               --hostname "${NAME}" \
               --run-command "echo '${USER} ALL=(ALL) NOPASSWD:ALL' | tee /etc/sudoers.d/${USER}" \
               --run-command "chmod 440 /etc/sudoers.d/${USER}" \
               --run-command "cat > /etc/network/interfaces.d/enp1s0.cfg <<EOF
auto enp1s0
iface enp1s0 inet static
    address ${IP}/24
    gateway $GATEWAY
    dns-nameservers $NAMESERVERS
EOF"

echo -e "[+] The virtual machine is configured..."

cd "$ORIG_DIR"
