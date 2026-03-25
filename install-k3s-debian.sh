#!/bin/bash
systemctl stop xagt
systemctl disable xagt
DEBIAN_FRONTEND=noninteractive apt update -y
DEBIAN_FRONTEND=noninteractive apt upgrade -y
DEBIAN_FRONTEND=noninteractive apt autoremove -y
DEBIAN_FRONTEND=noninteractive apt install curl git podman -y
mkdir -p /opt/cni/bin
wget https://github.com$(curl -s https://github.com/containernetworking/plugins/releases \
  | grep download | grep amd64 | grep tgz\" | sed -n 's/.*href=\"\(\S*\)\".*/\1/p')
tar -xvf cni-plugins-linux-amd64-*.tgz -C /opt/cni/bin/
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash -
curl -sfL https://get.k3s.io | sh -
SECONDS_LEFT=45
while [ $SECONDS_LEFT -ge 0 ]; do
    printf "\rShort pause: %02d" "$SECONDS_LEFT"
    sleep 1
    SECONDS_LEFT=$((SECONDS_LEFT - 1))
done
echo ""
helm repo add harbor https://helm.goharbor.io
KUBECONFIG=/etc/rancher/k3s/k3s.yaml \
  helm install registry harbor/harbor \
  --set expose.type=ingress \
  --set expose.ingress.hosts.core=$(hostname -f | tr '[:upper:]' '[:lower:]') \
  --set externalURL=https://$(hostname -f | tr '[:upper:]' '[:lower:]')
SECONDS_LEFT=45
while [ $SECONDS_LEFT -ge 0 ]; do
    printf "\rShort pause: %02d" "$SECONDS_LEFT"
    sleep 1
    SECONDS_LEFT=$((SECONDS_LEFT - 1))
done
echo ""
mkdir -p /root/usr/local/share/ca-certificates/$(hostname -f | tr '[:upper:]' '[:lower:]') \
  && curl -s -k https://$(hostname -f | tr '[:upper:]' '[:lower:]')/api/v2.0/systeminfo/getcert \
  > /root/usr/local/share/ca-certificates/$(hostname -f | tr '[:upper:]' '[:lower:]')/ca.crt
sed s/ReplaceWithHost/$(hostname -f | tr '[:upper:]' '[:lower:]')/g <<EOF \
  | sed s/ReplaceWithIP/$(hostname -I | cut -f1 -d' ')/g \
  > /etc/rancher/k3s/registries.yaml
mirrors:
  "ReplaceWithIP":
    endpoints:
      - "http://ReplaceWithIP"
  "ReplaceWithHost:5000":
    endpoints:
      - "http://ReplaceWithHost"
configs:
  "ReplaceWithHost":
    tls:
      ca_file: "/root/usr/local/share/ca-certificates/ReplaceWithHost/ca.crt"
EOF
systemctl restart k3s
