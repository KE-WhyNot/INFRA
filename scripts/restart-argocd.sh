#!/bin/bash

# ArgoCD 재시작 스크립트
# 이 스크립트는 ArgoCD 컴포넌트들을 재시작합니다.

set -e

echo "🔄 ArgoCD 재시작을 시작합니다..."

# 1. ArgoCD 네임스페이스 확인
if ! kubectl get namespace argocd >/dev/null 2>&1; then
    echo "❌ ArgoCD 네임스페이스가 존재하지 않습니다."
    echo "💡 먼저 deploy-argocd.sh를 실행하여 ArgoCD를 설치하세요."
    exit 1
fi

# 2. ArgoCD CRD 설치 (필요한 경우)
echo "📋 ArgoCD CRD 확인 및 설치 중..."
if ! kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
    echo "  - ArgoCD CRD 설치 중..."
    kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/application-crd.yaml
    kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/appproject-crd.yaml
    kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/applicationset-crd.yaml
    echo "  ✅ ArgoCD CRD 설치 완료"
else
    echo "  ✅ ArgoCD CRD가 이미 설치되어 있습니다"
fi

# 3. ArgoCD 컴포넌트 재시작
echo "🔄 ArgoCD 컴포넌트 재시작 중..."

echo "  - ArgoCD Server 재시작..."
kubectl rollout restart deployment/argocd-server -n argocd

echo "  - ArgoCD Application Controller 재시작..."
kubectl rollout restart deployment/argocd-application-controller -n argocd

echo "  - ArgoCD Repository Server 재시작..."
kubectl rollout restart deployment/argocd-repo-server -n argocd

echo "  - ArgoCD Redis 재시작..."
kubectl rollout restart deployment/argocd-redis -n argocd

# 4. 재시작 상태 확인
echo "⏳ 재시작 상태 확인 중..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-application-controller -n argocd --timeout=300s
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-redis -n argocd --timeout=300s

# 5. 최종 상태 확인
echo "🔍 최종 상태 확인 중..."
kubectl get pods -n argocd

echo ""
echo "🎉 ArgoCD 재시작이 완료되었습니다!"
echo ""
echo "📋 접속 정보:"
echo "  - ArgoCD UI: http://localhost:8080"
echo "  - 포트 포워딩: kubectl port-forward svc/argocd-server -n argocd 8080:8080"
echo ""
echo "🔧 유용한 명령어:"
echo "  - 파드 상태 확인: kubectl get pods -n argocd"
echo "  - 로그 확인: kubectl logs -f deployment/argocd-server -n argocd"
