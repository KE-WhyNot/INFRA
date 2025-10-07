# Nginx Ingress Controller를 Helm으로 설치
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = "4.8.3"
  
  create_namespace = true
  wait              = false
  timeout           = 600
  atomic            = false
  
  force_update = true
  replace = true
  
  # OpenStack 환경에 맞는 설정을 values 파일로 관리
  values = [
    file("helm/nginx/values.yaml")
  ]
  
  depends_on = [null_resource.preclean_ingress, null_resource.copy_kubeconfig, null_resource.wait_for_k8s_api]
}

## NGINX Ingress Controller 롤아웃/진단
resource "null_resource" "nginx_ingress_diagnostics" {
  depends_on = [helm_release.nginx_ingress]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "[nginx] 컨트롤러 배포 상태 확인 중..."
      # 실시간 진행도 (rollout status)
      kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=5m || true
      echo "[nginx] 파드 목록:" && kubectl -n ingress-nginx get pods -o wide || true
      echo "[nginx] 서비스 목록:" && kubectl -n ingress-nginx get svc -o wide || true
      echo "[nginx] 최근 이벤트:" && kubectl -n ingress-nginx get events --sort-by=.lastTimestamp | tail -n 50 || true
      echo "[nginx] 컨트롤러 상세:" && kubectl -n ingress-nginx describe deploy/ingress-nginx-controller | tail -n 80 || true
    EOT
  }
}

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "6.7.12"
  create_namespace = true
  wait              = false
  timeout           = 600
  atomic            = false

  values = [
    file("helm/argocd/values.yaml")
  ]

  depends_on = [null_resource.preclean_argocd, null_resource.copy_kubeconfig, null_resource.wait_for_k8s_api, helm_release.nginx_ingress]
}

# Redis는 이제 ArgoCD Application으로 관리됩니다
# Redis Application 매니페스트: applications/redis-app.yaml

## ArgoCD 롤아웃/진단
resource "null_resource" "argocd_diagnostics" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "[argocd] 서버 배포 상태 확인 중..."
      kubectl -n argocd rollout status deploy/argocd-server --timeout=5m || true
      echo "[argocd] 파드 목록:" && kubectl -n argocd get pods -o wide || true
      echo "[argocd] 서비스 목록:" && kubectl -n argocd get svc -o wide || true
      echo "[argocd] 최근 이벤트:" && kubectl -n argocd get events --sort-by=.lastTimestamp | tail -n 50 || true
      echo "[argocd] 서버 상세:" && kubectl -n argocd describe deploy/argocd-server | tail -n 80 || true
    EOT
  }
}