#!/bin/bash

# 모니터링 스택 정리 스크립트
# 이 스크립트는 Oracle Cloud Shell에서 실행하세요

set -e

echo "🧹 모니터링 스택 정리를 시작합니다..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수 정의
print_step() {
    echo -e "${GREEN}📋 $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 확인 메시지
print_warning "이 작업은 모든 모니터링 데이터를 삭제합니다!"
read -p "정말로 계속하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "작업이 취소되었습니다."
    exit 1
fi

# 1. Helm 릴리스 삭제
print_step "Helm 릴리스 삭제"
helm uninstall kube-prometheus-stack -n monitoring || true

# 2. PVC 삭제 (데이터 손실 주의)
print_step "PVC 삭제"
kubectl delete pvc --all -n monitoring || true

# 3. 네임스페이스 삭제
print_step "monitoring 네임스페이스 삭제"
kubectl delete namespace monitoring || true

# 4. 정리 완료
print_step "정리 완료! 🎉"
echo "모든 모니터링 리소스가 삭제되었습니다."
