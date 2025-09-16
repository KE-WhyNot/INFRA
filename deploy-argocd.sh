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

# Redis 서버 배포
echo "🗄️ Deploying Redis server..."
kubectl apply -f k8s/argocd/argocd-redis.yaml

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

# Nginx Ingress Controller Application 생성
echo "🌐 Creating Nginx Ingress Controller application..."
kubectl apply -f k8s/argocd/argocd-nginx-ingress-app.yaml

# 기존 포트 포워딩 중단
echo "🔌 Stopping existing port-forward processes..."
pkill -f "kubectl.*port-forward.*argocd" 2>/dev/null || true

# 포트 8000이 사용 중인지 확인하고 사용 가능한 포트 찾기
PORT=8000
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; do
    echo "⚠️ Port $PORT is in use, trying port $((PORT+1))..."
    PORT=$((PORT+1))
done

# ArgoCD 포트 포워딩 시작 (백그라운드)
echo "🌐 Starting ArgoCD port-forward on port $PORT..."
kubectl port-forward svc/argocd-server -n argocd $PORT:8080 > /dev/null 2>&1 &
ARGOCD_PF_PID=$!

# 포트 포워딩이 시작될 때까지 잠시 대기
sleep 5

# 포트 포워딩이 정상적으로 시작되었는지 확인
if ! kill -0 $ARGOCD_PF_PID 2>/dev/null; then
    echo "❌ Port-forward failed to start. Trying to start again..."
    kubectl port-forward svc/argocd-server -n argocd $PORT:8080 > /dev/null 2>&1 &
    ARGOCD_PF_PID=$!
    sleep 3
fi

# ArgoCD 서비스 정보 출력
echo ""
echo "✅ ArgoCD deployed successfully!"
echo "🌐 ArgoCD UI: http://localhost:$PORT"
echo "👤 Username: admin"
echo "🔑 Password: admin"
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
echo "🔌 Port-forward PID: $ARGOCD_PF_PID (Port: $PORT)"
echo "   To stop port-forward: kill $ARGOCD_PF_PID"
echo ""
echo "🛑 To delete ArgoCD:"
echo "   kubectl delete namespace argocd"
echo ""
echo "🚀 Opening ArgoCD UI in browser..."
if command -v open >/dev/null 2>&1; then
    open "http://localhost:$PORT"
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:$PORT"
else
    echo "   Please open http://localhost:$PORT in your browser"
fi
