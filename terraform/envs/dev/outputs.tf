# ArgoCD 접속 정보 출력
output "argocd_server_url" {
  description = "ArgoCD Server URL"
  value       = "https://argocd.example.com"
}

output "argocd_admin_password" {
  description = "ArgoCD Admin Password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = true
}

# NGINX Ingress Controller 정보 출력
output "ingress_nginx_external_ip" {
  description = "NGINX Ingress Controller External IP"
  value       = "kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}
