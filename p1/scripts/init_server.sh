#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND="noninteractive"

PRIVATE_IFACE=$(ip -o -4 addr show | grep -F "${CONTROLLER_IP}/" | awk '{print $2}') || true
TOKEN_K3S="/var/lib/rancher/k3s/server/node-token"
TOKEN_SHARED="/secrets/node-token"
TIMEOUT=60
ELAPSED=0

if [ -z "$PRIVATE_IFACE" ]; then
	echo "Error: No Interface with this IP ${CONTROLLER_IP}" >&2
	exit 1
fi


if [ -e "$TOKEN_SHARED" ]; then
    echo "Deleting old K3s token"
    rm -f "$TOKEN_SHARED"
fi


if ! command -v k3s > /dev/null 2>&1; then
	echo "K3s installation tools verification"
	if ! command -v curl > /dev/null 2>&1; then
		echo "Curl not installed, download curl with apt-get"
		apt-get update
		apt-get install curl -y
	else
		echo "Curl is already installed =)"
	fi
	echo "Installation of k3s"
	curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --flannel-iface $PRIVATE_IFACE --node-ip $CONTROLLER_IP --write-kubeconfig-mode 644" sh
else
	echo "K3s is already installed"
fi

while [ ! -f "$TOKEN_K3S" ]; do
    if (( ELAPSED >= TIMEOUT )); then
        echo "Error: K3s token not found after ${TIMEOUT}s" >&2
        exit 1
    fi
    sleep 1
    (( ELAPSED++ )) || true
done

echo "Copy of the K3s token to the synced folder"
cp "$TOKEN_K3S" "$TOKEN_SHARED"
chmod 600 "$TOKEN_SHARED"

echo "Install sucessfull, server is ready"




