#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND="noninteractive"

PRIVATE_IFACE=$(ip -o -4 addr show | grep -F "${AGENT_IP}/" | awk '{print $2}') || true
TOKEN_SHARED="/secrets/node-token"
TIMEOUT=300
ELAPSED=0


if [ -z "$PRIVATE_IFACE" ]; then
	echo "Error: No Interface with this IP ${AGENT_IP}" >&2
	exit 1
fi

while [ ! -f "$TOKEN_SHARED" ]; do
    if (( ELAPSED >= TIMEOUT )); then
        echo "Error: K3s token not found after ${TIMEOUT}s" >&2
        exit 1
    fi
    sleep 1
    (( ELAPSED++ )) || true
done

K3S_TOKEN=$(cat "$TOKEN_SHARED")
export K3S_TOKEN

if ! command -v k3s > /dev/null 2>&1; then
	echo "Verification of the tools needed for the installation of K3s"
	if ! command -v curl > /dev/null 2>&1; then
		echo "Curl not installed, installation of curl with apt-get"
		apt-get update
		apt-get install curl -y
	else
		echo "Curl already installed"
	fi
	echo "Installation of k3s"
	curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --flannel-iface $PRIVATE_IFACE --node-ip $AGENT_IP" sh 
else
	echo "K3s is already installed"
fi

echo "K3s for the agent is correctly installed =)"

