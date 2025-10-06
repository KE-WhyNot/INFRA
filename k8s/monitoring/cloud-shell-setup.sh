#!/bin/bash

# 모니터링 스택 Cloud Shell 배포 스크립트
# 이 스크립트는 Oracle Cloud Shell에서 실행하세요

set -e

echo "🚀 모니터링 스택 배포를 시작합니다..."

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

# 1. 환경 변수 설정
print_step "환경 변수 설정"
read -p "Grafana 관리자 비밀번호를 입력하세요: " GRAFANA_ADMIN_PASSWORD

# 비밀번호 검증
if [ ${#GRAFANA_ADMIN_PASSWORD} -lt 8 ]; then
    print_error "Grafana 비밀번호는 8자 이상이어야 합니다."
    exit 1
fi

# 2. 네임스페이스 생성
print_step "monitoring 네임스페이스 생성"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 3. Grafana 관리자 시크릿 생성
print_step "Grafana 관리자 시크릿 생성"
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="${GRAFANA_ADMIN_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Helm Repository 추가
print_step "Helm Repository 추가"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 5. kube-prometheus-stack 배포
print_step "kube-prometheus-stack 배포"
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f k8s/monitoring/values-prom.yaml \
  --wait

# 6. 배포 상태 확인
print_step "배포 상태 확인"
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get ingress -n monitoring

# 7. 접근 정보 출력
print_step "접근 정보"
echo ""
echo "📊 Prometheus 접근:"
echo "   kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring"
echo "   http://localhost:9090"
echo ""
echo "📈 Grafana 접근:"
echo "   외부: https://grafana.youth-fi.com (Load Balancer에서 HTTPS 처리)"
echo "   포트포워딩: kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring"
echo "   로그인 정보:"
echo "     사용자명: admin"
echo "     비밀번호: ${GRAFANA_ADMIN_PASSWORD}"
echo ""

# 8. DNS 설정 안내
print_warning "DNS 설정이 필요합니다:"
echo "   grafana.youth-fi.com을 Nginx Ingress LoadBalancer IP로 설정하세요"
echo "   LoadBalancer IP 확인: kubectl get svc -n nginx-ingress"

print_step "배포 완료! 🎉"
