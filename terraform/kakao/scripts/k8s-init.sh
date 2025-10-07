#!/bin/bash

# Kubernetes 마스터 노드 초기화 스크립트

set -e

echo "🚀 Kubernetes 마스터 노드 초기화 시작..."

# 0. 이미 초기화되어 있으면 init 스킵(토큰/HTTP 서빙만 보장)
if [ -f /etc/kubernetes/admin.conf ]; then
  echo "ℹ️  이미 kubeadm init 완료 상태. 토큰/HTTP 서빙만 보장합니다."
  JOIN_COMMAND=$(kubeadm token create --print-join-command)
  echo "$JOIN_COMMAND" | sudo tee /home/ubuntu/join-command.sh >/dev/null
  sudo chmod +x /home/ubuntu/join-command.sh

  # join-command 8080 서빙 보장
  sudo bash -c 'cat >/etc/systemd/system/join-http.service <<UNIT
[Unit]
Description=Serve join-command over HTTP (port 8080)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always
RestartSec=5s
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
UNIT'
  sudo systemctl daemon-reload
  sudo systemctl enable --now join-http.service || true

  echo "✅ 준비 완료 (init 스킵)."
  echo "📝 조인 토큰: $JOIN_COMMAND"
  exit 0
fi

# 1. 시스템 업데이트
sudo rm -rf /var/lib/apt/lists/* || true
sudo apt-get clean || true
sudo sed -i 's|http://archive.ubuntu.com/ubuntu|https://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list || true
sudo sed -i 's|http://security.ubuntu.com/ubuntu|https://security.ubuntu.com/ubuntu|g' /etc/apt/sources.list || true
sudo apt-get update -o Acquire::Retries=5
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# 2. Docker 설치
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 3. Kubernetes 설치 (Ubuntu 20.04용)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# 4. kubelet 버전 고정 및 containerd 설정
sudo apt-mark hold kubelet kubeadm kubectl

# 5. 프리리퀴짓: swap/커널 설정
sudo swapoff -a || true
sudo sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab || true
sudo modprobe br_netfilter || true
echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables >/dev/null || true
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null || true
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf >/dev/null
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system >/dev/null

# 6. containerd 설정 (가능한 경우에만 기본 설정 생성 후 SystemdCgroup 적용)
sudo mkdir -p /etc/containerd
if command -v containerd >/dev/null 2>&1; then
  if containerd config default >/dev/null 2>&1; then
    containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
  fi
  # SystemdCgroup=true 적용
  if [ -f /etc/containerd/config.toml ]; then
    sudo sed -i 's/^\(\s*SystemdCgroup\s*=\s*\)false/\1true/' /etc/containerd/config.toml || true
  fi
fi
# crictl 엔드포인트 설정
cat <<EOF | sudo tee /etc/crictl.yaml >/dev/null
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF
sudo systemctl restart containerd || true
sudo systemctl enable containerd || true

# 7. Docker 서비스 시작 (필요 시)
sudo systemctl enable docker || true
sudo systemctl start docker || true

# 8. Kubernetes 초기화
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

# 9. kubectl 설정
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 10. Flannel 네트워크 플러그인 설치
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 11. 마스터 노드에서도 Pod 스케줄링 허용
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# 12. 조인 토큰 생성 및 저장
JOIN_COMMAND=$(kubeadm token create --print-join-command)
echo "$JOIN_COMMAND" | sudo tee /home/ubuntu/join-command.sh >/dev/null
sudo chmod +x /home/ubuntu/join-command.sh

# 13. join-command를 8080으로 지속 서빙(systemd)
sudo bash -c 'cat >/etc/systemd/system/join-http.service <<UNIT
[Unit]
Description=Serve join-command over HTTP (port 8080)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always
RestartSec=5s
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
UNIT'
sudo systemctl daemon-reload
sudo systemctl enable --now join-http.service || true

# 14. 마스터 퍼블릭 IP 파일로 저장(워커에서 참조 가능)
MASTER_PUBLIC_IP="$(curl -s http://ifconfig.me || true)"
if [ -n "$MASTER_PUBLIC_IP" ]; then
  echo "$MASTER_PUBLIC_IP" | sudo tee /home/ubuntu/master-public-ip.txt >/dev/null
fi

echo "✅ Kubernetes 마스터 노드 초기화 완료!"
echo "📝 조인 토큰이 /home/ubuntu/join-command.sh에 저장되었습니다:"
echo "$JOIN_COMMAND"
