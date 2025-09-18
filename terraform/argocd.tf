# Note: ArgoCD is already installed manually
# This file contains the configuration that would be used if ArgoCD was managed by Terraform
# Currently, ArgoCD is managed separately and only infrastructure resources are managed by Terraform

# Uncomment below if you want Terraform to manage ArgoCD:

# ArgoCD Namespace
# resource "kubernetes_namespace" "argocd" {
#   metadata {
#     name = var.argocd_namespace
#     labels = {
#       "name" = var.argocd_namespace
#     }
#   }
#
#   depends_on = [oci_containerengine_node_pool.node_pool]
# }

# ArgoCD Helm Repository
# resource "helm_release" "argocd" {
#   name       = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   version    = var.argocd_chart_version
#   namespace  = kubernetes_namespace.argocd.metadata[0].name
#
#   values = [
#     yamlencode({
#       global = {
#         domain = "argocd.${var.project_name}-${var.environment}.local"
#       }
#       
#       server = {
#         service = {
#           type = "LoadBalancer"
#         }
#         ingress = {
#           enabled = true
#           ingressClassName = "nginx"
#           annotations = {
#             "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
#             "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
#           }
#           hosts = ["argocd.${var.project_name}-${var.environment}.local"]
#         }
#         config = {
#           "url" = "https://argocd.${var.project_name}-${var.environment}.local"
#         }
#         extraArgs = [
#           "--insecure"
#         ]
#       }
#       
#       controller = {
#         metrics = {
#           enabled = true
#         }
#       }
#       
#       repoServer = {
#         metrics = {
#           enabled = true
#         }
#       }
#       
#       applicationSet = {
#         enabled = true
#         metrics = {
#           enabled = true
#         }
#       }
#       
#       notifications = {
#         enabled = true
#         metrics = {
#           enabled = true
#         }
#       }
#       
#       dex = {
#         enabled = false
#       }
#       
#       redis = {
#         enabled = true
#         metrics = {
#           enabled = true
#         }
#       }
#     })
#   ]
#
#   depends_on = [
#     kubernetes_namespace.argocd,
#     oci_containerengine_node_pool.node_pool
#   ]
#
#   timeout = 600
# }

# ArgoCD Applications are managed separately after ArgoCD installation
# Use the existing k8s/argocd/ YAML files to create applications:

# kubectl apply -f k8s/argocd/argocd-infra-app.yaml
# kubectl apply -f k8s/argocd/argocd-auth-app.yaml  
# kubectl apply -f k8s/argocd/argocd-nginx-ingress-app.yaml

# Commented out for separate management:
# 
# # ArgoCD Application for INFRA Repository
# resource "kubernetes_manifest" "argocd_infra_app" {
#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "Application"
#     metadata = {
#       name      = "infra-services"
#       namespace = var.argocd_namespace
#     }
#     spec = {
#       project = "default"
#       source = {
#         repoURL        = "https://github.com/KE-WhyNot/INFRA"
#         targetRevision = "main"
#         path           = "k8s"
#       }
#       destination = {
#         server    = "https://kubernetes.default.svc"
#         namespace = "default"
#       }
#       syncPolicy = {
#         automated = {
#           prune    = true
#           selfHeal = true
#         }
#         syncOptions = ["CreateNamespace=true"]
#       }
#     }
#   }
# }
#
# # ArgoCD Application for Auth Service
# resource "kubernetes_manifest" "argocd_auth_app" {
#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "Application"
#     metadata = {
#       name      = "auth-service"
#       namespace = var.argocd_namespace
#     }
#     spec = {
#       project = "default"
#       source = {
#         repoURL        = "https://github.com/KE-WhyNot/INFRA"
#         targetRevision = "main"
#         path           = "k8s/auth-service/helm"
#         helm = {
#           valueFiles = ["values.yaml"]
#         }
#       }
#       destination = {
#         server    = "https://kubernetes.default.svc"
#         namespace = "auth-service"
#       }
#       syncPolicy = {
#         automated = {
#           prune    = true
#           selfHeal = true
#         }
#         syncOptions = ["CreateNamespace=true"]
#       }
#       revisionHistoryLimit = 10
#     }
#   }
# }
#
# # ArgoCD Application for Nginx Ingress
# resource "kubernetes_manifest" "argocd_nginx_ingress_app" {
#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "Application"
#     metadata = {
#       name      = "nginx-ingress"
#       namespace = var.argocd_namespace
#     }
#     spec = {
#       project = "default"
#       source = {
#         repoURL        = "https://github.com/KE-WhyNot/INFRA"
#         targetRevision = "main"
#         path           = "k8s/nginx-ingress/helm"
#         helm = {
#           valueFiles = ["values.yaml"]
#         }
#       }
#       destination = {
#         server    = "https://kubernetes.default.svc"
#         namespace = "ingress-nginx"
#       }
#       syncPolicy = {
#         automated = {
#           prune    = true
#           selfHeal = true
#         }
#         syncOptions = ["CreateNamespace=true"]
#       }
#     }
#   }
# }
