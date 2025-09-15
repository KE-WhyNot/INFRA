#!/bin/bash

echo "🚀 Deploying ArgoCD to Kubernetes..."

# ArgoCD 네임스페이스 생성
echo "📦 Creating ArgoCD namespace..."
kubectl apply -f k8s/argocd/namespace.yaml

# ArgoCD ConfigMap 및 Secret 배포
echo "⚙️ Deploying ArgoCD ConfigMaps and Secrets..."
kubectl apply -f k8s/argocd/argocd-cm.yaml
kubectl apply -f k8s/argocd/argocd-secret.yaml
kubectl apply -f k8s/argocd/argocd-rbac-cm.yaml

# ArgoCD RBAC 배포
echo "🔐 Deploying ArgoCD RBAC..."
kubectl apply -f k8s/argocd/rbac.yaml

# ArgoCD 컴포넌트 배포
echo "🔧 Deploying ArgoCD components..."
kubectl apply -f k8s/argocd/argocd-repo-server.yaml
kubectl apply -f k8s/argocd/argocd-application-controller.yaml
kubectl apply -f k8s/argocd/argocd-server.yaml

# ArgoCD 서버가 준비될 때까지 대기
echo "⏳ Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# INFRA 레포지토리 Application 생성
echo "📊 Creating INFRA repository application..."
kubectl apply -f k8s/argocd/argocd-infra-app.yaml

# Auth Service Application 생성
echo "🔐 Creating Auth Service application..."
kubectl apply -f k8s/argocd/argocd-auth-app.yaml

# 기존 포트 포워딩 중단
echo "🔌 Stopping existing port-forward processes..."
pkill -f "kubectl.*port-forward.*argocd" 2>/dev/null || true

# ArgoCD 포트 포워딩 시작 (백그라운드)
echo "🌐 Starting ArgoCD port-forward on port 8000..."
kubectl port-forward svc/argocd-server -n argocd 8000:8080 > /dev/null 2>&1 &
ARGOCD_PF_PID=$!

# 포트 포워딩이 시작될 때까지 잠시 대기
sleep 3

# ArgoCD 서비스 정보 출력
echo ""
echo "✅ ArgoCD deployed successfully!"
echo "🌐 ArgoCD UI: http://localhost:8000"
echo "📊 INFRA Repository: https://github.com/KE-WhyNot/INFRA"
echo "📁 Monitoring Path: k8s/"
echo ""
echo "🔍 To check ArgoCD status:"
echo "   kubectl get pods -n argocd"
echo "   kubectl get svc -n argocd"
echo ""
echo "🔧 To check ArgoCD logs:"
echo "   kubectl logs -f deployment/argocd-server -n argocd"
echo ""
echo "🔌 Port-forward PID: $ARGOCD_PF_PID"
echo "   To stop port-forward: kill $ARGOCD_PF_PID"
echo ""
echo "🛑 To delete ArgoCD:"
echo "   kubectl delete namespace argocd"
