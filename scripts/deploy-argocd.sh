#!/bin/bash

# ArgoCD 공식 Helm Chart 배포 스크립트
# 이 스크립트는 공식 ArgoCD Helm Chart를 설치하고 우리 서비스들을 자동 등록합니다.

set -e

echo "🚀 ArgoCD 공식 Helm Chart 배포를 시작합니다..."

# 1. Helm 저장소 및 설정 확인
echo "📋 Helm 저장소 및 설정 확인 중..."

# Argo Helm 저장소 추가
if ! helm repo list | grep -q "argo"; then
    echo "  - Argo Helm 저장소 추가 중..."
    helm repo add argo https://argoproj.github.io/argo-helm
fi

echo "  - Helm 저장소 업데이트 중..."
helm repo update

# Values 파일 확인
if [ ! -f "../k8s/argocd/values.yaml" ]; then
    echo "  ❌ ArgoCD values.yaml 파일을 찾을 수 없습니다: ../k8s/argocd/values.yaml"
    exit 1
fi

echo "  ✅ Helm 저장소 및 설정 확인 완료"

# 2. 기존 ArgoCD 리소스 확인
echo "🔍 기존 ArgoCD 리소스 확인 중..."
if kubectl get namespace argocd >/dev/null 2>&1; then
    echo "  ℹ️  argocd 네임스페이스가 존재합니다"
    if kubectl get all -n argocd | grep -q argocd; then
        echo "  ⚠️  ArgoCD 리소스가 실행 중입니다"
        echo "  💡 먼저 cleanup-argocd.sh를 실행하여 정리하세요"
        exit 1
    else
        echo "  ✅ 네임스페이스가 비어있습니다. 계속 진행합니다."
    fi
else
    echo "  ℹ️  argocd 네임스페이스가 없습니다. 새로 생성합니다."
fi

# 3. Helm 릴리스 확인
if helm list -A | grep -q argocd; then
    echo "  ⚠️  ArgoCD Helm 릴리스가 이미 존재합니다"
    echo "  💡 먼저 cleanup-argocd.sh를 실행하여 정리하세요"
    exit 1
fi

# 4. ArgoCD 설치 (공식 Helm Chart 사용)
echo "📦 ArgoCD 공식 Helm Chart 설치 중..."
helm install argocd argo/argo-cd -n argocd --create-namespace -f ../k8s/argocd/values.yaml

echo "  ✅ ArgoCD 설치 완료"

# 5. 설치 확인
echo "🔍 설치 상태 확인 중..."
echo "  - 파드 상태 확인..."
kubectl get pods -n argocd

echo "  - 서비스 상태 확인..."
kubectl get services -n argocd

echo "  - Helm 릴리스 상태 확인..."
helm list -n argocd

# 6. ArgoCD 서버가 준비될 때까지 대기
echo "⏳ ArgoCD 서버가 준비될 때까지 대기 중..."
echo "  - 최대 5분까지 대기합니다..."
if ! kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd; then
    echo "  ⚠️  ArgoCD 서버 시작 타임아웃 (5분)"
    echo "  💡 수동으로 확인하세요: kubectl get pods -n argocd"
    echo "  💡 로그 확인: kubectl logs -f deployment/argocd-server -n argocd"
    exit 1
fi
echo "  ✅ ArgoCD 서버 준비 완료"

# 7. ArgoCD Application들 생성
echo "📊 ArgoCD Application들 생성 중..."

# Application 파일들이 있는지 확인
if [ -d "../k8s/argocd/applications" ]; then
    echo "  - Application 파일들을 찾았습니다. 생성 중..."
    
    # Auth Service Application 생성
    if [ -f "../k8s/argocd/applications/auth-service-app.yaml" ]; then
        echo "  - Auth Service Application 생성..."
        kubectl apply -f ../k8s/argocd/applications/auth-service-app.yaml
    fi
    
    # Nginx Ingress Controller Application 생성
    if [ -f "../k8s/argocd/applications/nginx-ingress-app.yaml" ]; then
        echo "  - Nginx Ingress Controller Application 생성..."
        kubectl apply -f ../k8s/argocd/applications/nginx-ingress-app.yaml
    fi
    
    echo "  ✅ Application 생성 완료"
else
    echo "  ℹ️  Application 파일들이 없습니다. ArgoCD만 설치됩니다."
    echo "  💡 필요시 ArgoCD UI에서 수동으로 Application을 생성하세요."
fi

# 8. 포트 8000 자동 연결 설정
echo "🔌 포트 8000 자동 연결 설정 중..."

# 기존 포트 포워딩 중단
echo "  - 기존 포트 포워딩 중단..."
pkill -f "kubectl.*port-forward.*argocd" 2>/dev/null || true

# 포트 8000이 사용 중인지 확인
TARGET_PORT=8000
if lsof -Pi :$TARGET_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "  ⚠️  포트 $TARGET_PORT이 사용 중입니다. 기존 프로세스를 종료합니다..."
    lsof -ti :$TARGET_PORT | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# ArgoCD 포트 포워딩 시작 (로컬 8000 → ArgoCD 80)
echo "  - ArgoCD 포트 8000으로 포트 포워딩 시작..."
kubectl port-forward svc/argocd-server -n argocd $TARGET_PORT:80 > /dev/null 2>&1 &
ARGOCD_PF_PID=$!

# 포트 포워딩이 시작될 때까지 잠시 대기
sleep 5

# 포트 포워딩이 정상적으로 시작되었는지 확인
if ! kill -0 $ARGOCD_PF_PID 2>/dev/null; then
    echo "  ❌ 포트 포워딩 시작 실패. 다시 시도 중..."
    kubectl port-forward svc/argocd-server -n argocd $TARGET_PORT:80 > /dev/null 2>&1 &
    ARGOCD_PF_PID=$!
    sleep 3
fi

PORT=$TARGET_PORT

# 9. 최종 상태 확인
echo "🔍 최종 상태 확인 중..."
echo "  - 파드 상태:"
kubectl get pods -n argocd

echo "  - 서비스 상태:"
kubectl get services -n argocd

echo "  - Application 상태:"
kubectl get applications -n argocd

# 10. 관리자 패스워드 확인
echo "🔑 ArgoCD 관리자 패스워드 확인 중..."
ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "패스워드를 가져올 수 없습니다")

# 11. 접속 정보 출력
echo ""
echo "🎉 ArgoCD 배포가 완료되었습니다!"
echo ""
echo "📋 접속 정보:"
echo "  - ArgoCD UI: http://localhost:$PORT"
echo "  - 사용자명: admin"
echo "  - 패스워드: $ADMIN_PASSWORD"
echo "  - 네임스페이스: argocd"
echo "  - 포트 포워딩 PID: $ARGOCD_PF_PID"
echo ""
echo "📊 등록된 Application:"
echo "  - Auth Service (k8s/auth-service/helm)"
echo "  - Nginx Ingress (k8s/nginx-ingress/helm)"
echo ""
echo "🔧 유용한 명령어:"
echo "  - 파드 상태 확인: kubectl get pods -n argocd"
echo "  - 서비스 확인: kubectl get services -n argocd"
echo "  - Application 확인: kubectl get applications -n argocd"
echo "  - 로그 확인: kubectl logs -f deployment/argocd-server -n argocd"
echo "  - 포트 포워딩 중단: kill $ARGOCD_PF_PID"
echo "  - ArgoCD 삭제: helm uninstall argocd -n argocd"
echo ""
echo "🚀 브라우저에서 ArgoCD UI 열기 중..."
if command -v open >/dev/null 2>&1; then
    open "http://localhost:$PORT"
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:$PORT"
else
    echo "  💡 브라우저에서 http://localhost:$PORT 을 열어주세요"
fi
