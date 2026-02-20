#!/bin/bash
# Bootstrap Docker on kernel 4.4.0 (no nftables, no veth, 9p filesystem)
set -e

echo "==> Switching to iptables-legacy..."
update-alternatives --set iptables /usr/sbin/iptables-legacy 2>/dev/null || true
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy 2>/dev/null || true

echo "==> Mounting tmpfs for Docker data (9p doesn't support xattr)..."
mkdir -p /mnt/docker-data
if ! mountpoint -q /mnt/docker-data; then
    mount -t tmpfs -o size=25G tmpfs /mnt/docker-data
fi

echo "==> Writing /etc/docker/daemon.json..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'JSON'
{
  "iptables": false,
  "bridge": "none",
  "storage-driver": "overlay2",
  "data-root": "/mnt/docker-data"
}
JSON

echo "==> Starting Docker daemon..."
pkill dockerd 2>/dev/null || true
sleep 2
nohup dockerd >/var/log/dockerd.log 2>&1 &

echo "==> Waiting for Docker to be ready..."
for i in $(seq 1 15); do
    if docker info >/dev/null 2>&1; then
        echo "==> Docker is up!"
        docker info | grep "Server Version"
        exit 0
    fi
    sleep 2
done

echo "ERROR: Docker did not start in time. Check /var/log/dockerd.log"
exit 1
