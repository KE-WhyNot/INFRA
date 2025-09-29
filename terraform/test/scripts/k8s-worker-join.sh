#!/bin/bash

# Kubernetes 워커 노드 조인 스크립트

set -e

echo "🚀 Kubernetes 워커 노드 조인 시작..."

# 1. 시스템 업데이트
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# 2. Docker 설치
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 3. Kubernetes 설치
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# 4. Docker 서비스 시작
sudo systemctl enable docker
sudo systemctl start docker

# 5. 마스터 IP 결정 우선순위: 인자 > 환경변수 > 파일 > 기본 사설 IP
MASTER_IP_ARG="$1"
MASTER_IP_ENV="${MASTER_IP:-}"
MASTER_IP_FILE="/home/ubuntu/master-public-ip.txt"
DEFAULT_MASTER_IP="10.0.0.10"

if [ -n "$MASTER_IP_ARG" ]; then
  MASTER_IP="$MASTER_IP_ARG"
elif [ -n "$MASTER_IP_ENV" ]; then
  MASTER_IP="$MASTER_IP_ENV"
elif [ -f "$MASTER_IP_FILE" ]; then
  MASTER_IP="$(cat "$MASTER_IP_FILE" | tr -d '\n' | xargs)"
else
  MASTER_IP="$DEFAULT_MASTER_IP"
fi

echo "🛰️  사용 마스터 IP: $MASTER_IP"

# 6. 마스터 노드에서 조인 토큰 가져오기
JOIN_COMMAND=$(ssh -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "cat /home/ubuntu/join-command.sh" || true)

if [ -z "$JOIN_COMMAND" ]; then
  echo "❌ 마스터에서 조인 명령을 가져오지 못했습니다. 마스터 초기화가 완료되었는지 확인하세요."
  exit 1
fi

# 7. 클러스터에 조인
sudo $JOIN_COMMAND

echo "✅ Kubernetes 워커 노드 조인 완료!"
