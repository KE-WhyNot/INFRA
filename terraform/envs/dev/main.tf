resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.11.0"

  values = [<<-YAML
controller:
  service:
    type: LoadBalancer   # KakaoCloud에서 EXTERNAL-IP 할당
  config:
    proxy-read-timeout: "3600"
    proxy-send-timeout: "3600"
YAML
  ]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "6.7.10"

  # 간단 데모용 (실운영은 TLS/인증 강화)
  values = [<<-YAML
server:
  extraArgs: ["--insecure"]
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts: ["localhost"] # 실제 DNS로 수정 필요
YAML
  ]

  depends_on = [helm_release.ingress_nginx]
}
