#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND="noninteractive"

PRIVATE_IFACE=$(ip -o -4 addr show | grep -F "${CONTROLLER_IP}/" | awk '{print $2}') || true

if [ -z "$PRIVATE_IFACE" ]; then
	echo "Error: No Interface with this IP ${CONTROLLER_IP}" >&2
	exit 1
fi

echo "K3s installation tools verification"
if ! command -v curl > /dev/null 2>&1; then
	echo "Curl not installed, download curl with apt-get"
	apt-get update
	apt-get install curl -y
else
	echo "Curl is already installed =)"
fi

echo "Installation de K3s en tant que server"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --flannel-iface $PRIVATE_IFACE --node-ip $CONTROLLER_IP --write-kubeconfig-mode 644" sh

echo "Install sucessfull, server is ready"




