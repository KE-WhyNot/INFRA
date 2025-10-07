# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# VCN
resource "oci_core_vcn" "oke_vcn" {
  compartment_id = var.compartment_id
  display_name   = "${var.environment}-oke-vcn"
  cidr_blocks    = [var.vcn_cidr]
  dns_label      = "okevcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "oke_ig" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.environment}-oke-ig"
}

# Route Table
resource "oci_core_route_table" "oke_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.environment}-oke-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke_ig.id
  }
}

# Security List for worker nodes
resource "oci_core_security_list" "oke_worker_seclist" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.environment}-oke-worker-seclist"

  # Egress rules
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Ingress rules
  ingress_security_rules {
    protocol = "all"
    source   = var.vcn_cidr
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 10250
      max = 10250
    }
  }
}

# Security List for load balancer
resource "oci_core_security_list" "oke_lb_seclist" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke_vcn.id
  display_name   = "${var.environment}-oke-lb-seclist"

  # Egress rules
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Ingress rules
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

# Subnet for worker nodes
resource "oci_core_subnet" "oke_worker_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.oke_vcn.id
  display_name        = "${var.environment}-oke-worker-subnet"
  cidr_block          = var.subnet_cidr
  dns_label           = "workersubnet"
  route_table_id      = oci_core_route_table.oke_rt.id
  security_list_ids   = [oci_core_security_list.oke_worker_seclist.id]
  prohibit_public_ip_on_vnic = false
}

# Subnet for load balancer
resource "oci_core_subnet" "oke_lb_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.oke_vcn.id
  display_name        = "${var.environment}-oke-lb-subnet"
  cidr_block          = var.load_balancer_subnet_cidr
  dns_label           = "lbsubnet"
  route_table_id      = oci_core_route_table.oke_rt.id
  security_list_ids   = [oci_core_security_list.oke_lb_seclist.id]
  prohibit_public_ip_on_vnic = false
}

# 고정 IP 사용
data "oci_core_public_ip" "existing_reserved_ip" {
  id = var.existing_reserved_ip_id
}

# 로컬 변수로 IP 주소 결정
locals {
  reserved_ip_address = data.oci_core_public_ip.existing_reserved_ip.ip_address
}

# OKE Cluster
resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = oci_core_vcn.oke_vcn.id

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.oke_worker_subnet.id
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = true
      is_tiller_enabled              = false
    }
    admission_controller_options {
      is_pod_security_policy_enabled = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.oke_lb_subnet.id]
  }
}

# Node Pool
resource "oci_containerengine_node_pool" "oke_node_pool" {
  cluster_id         = oci_containerengine_cluster.oke_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.node_pool_name
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.oke_worker_subnet.id
    }
    size = var.node_count
  }
  node_shape = var.node_shape
  node_shape_config {
    memory_in_gbs = var.node_memory_in_gbs
    ocpus         = var.node_ocpus
  }
  node_source_details {
    image_id    = data.oci_core_images.oke_node_pool_images.images[0].id
    source_type = "IMAGE"
  }
  initial_node_labels {
    key   = "name"
    value = var.node_pool_name
  }
}

# Get OKE node pool images
data "oci_core_images" "oke_node_pool_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.node_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ArgoCD Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      name = var.argocd_namespace
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit" = "restricted"
      "pod-security.kubernetes.io/warn" = "restricted"
    }
  }

  depends_on = [
    oci_containerengine_cluster.oke_cluster,
    oci_containerengine_node_pool.oke_node_pool
  ]
}

# ArgoCD Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    yamlencode({
      global = {
        domain = var.argocd_server_host
      }
      server = {
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled = true
          className = var.nginx_ingress_class
          annotations = {
            "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
            "nginx.ingress.kubernetes.io/proxy-body-size" = "0"
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          }
          hosts = [var.argocd_server_host]
          tls = [{
            secretName = "argocd-server-tls"
            hosts = [var.argocd_server_host]
          }]
        }
        config = {
          "url" = "https://${var.argocd_server_host}"
          "application.instanceLabelKey" = "argocd.argoproj.io/instance"
        }
        insecure = false
        extraArgs = [
          "--insecure=false"
        ]
      }
      configs = {
        secret = {
          argocdServerAdminPassword = bcrypt(var.argocd_admin_password)
        }
        cm = {
          "server.insecure" = "false"
        }
      }
      controller = {
        metrics = {
          enabled = true
        }
      }
      repoServer = {
        metrics = {
          enabled = true
        }
      }
      applicationSet = {
        enabled = true
        metrics = {
          enabled = true
        }
      }
    })
  ]

  depends_on = [
    oci_containerengine_cluster.oke_cluster,
    oci_containerengine_node_pool.oke_node_pool,
    helm_release.nginx_ingress,
    helm_release.cert_manager,
    local_file.kubeconfig
  ]
}

# Cert-Manager Namespace
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      name = "cert-manager"
    }
  }

  depends_on = [
    oci_containerengine_cluster.oke_cluster,
    oci_containerengine_node_pool.oke_node_pool
  ]
}

# Nginx Ingress Namespace
resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = var.nginx_ingress_namespace
    labels = {
      name = var.nginx_ingress_namespace
    }
  }

  depends_on = [
    oci_containerengine_cluster.oke_cluster,
    oci_containerengine_node_pool.oke_node_pool
  ]
}

# Cert-Manager Helm Release
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }

  set {
    name  = "webhook.securePort"
    value = "10250"
  }

  depends_on = [
    oci_containerengine_cluster.oke_cluster,
    oci_containerengine_node_pool.oke_node_pool
  ]
}

# Let's Encrypt ClusterIssuer - Production
resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "admin@youth-fi.com"
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
                podTemplate = {
                  spec = {
                    nodeSelector = {
                      "kubernetes.io/os" = "linux"
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager
  ]
}

# Let's Encrypt ClusterIssuer - Staging
resource "kubernetes_manifest" "letsencrypt_staging_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = "admin@youth-fi.com"
        privateKeySecretRef = {
          name = "letsencrypt-staging"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
                podTemplate = {
                  spec = {
                    nodeSelector = {
                      "kubernetes.io/os" = "linux"
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager
  ]
}

# Nginx Ingress Controller Helm Release
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.nginx_ingress_chart_version
  namespace  = kubernetes_namespace.nginx_ingress.metadata[0].name

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          loadBalancerIP = local.reserved_ip_address
          annotations = {
            "service.beta.kubernetes.io/oci-load-balancer-shape" = "flexible"
            "service.beta.kubernetes.io/oci-load-balancer-shape-flex-min" = "10"
            "service.beta.kubernetes.io/oci-load-balancer-shape-flex-max" = "100"
            "service.beta.kubernetes.io/oci-load-balancer-reserved-ip" = local.reserved_ip_address
          }
        }
        ingressClassResource = {
          name = var.nginx_ingress_class
          enabled = true
          default = true
          controllerValue = "k8s.io/ingress-nginx"
        }
        metrics = {
          enabled = true
        }
        podAnnotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port" = "10254"
        }
        config = {
          "proxy-body-size" = "0"
          "ssl-protocols" = "TLSv1.2 TLSv1.3"
          "ssl-ciphers" = "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384"
        }
      }
    })
  ]

  depends_on = [
    oci_containerengine_cluster.oke_cluster,
    oci_containerengine_node_pool.oke_node_pool
  ]
}

# kubeconfig 내용 받기
data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id = oci_containerengine_cluster.oke_cluster.id
}

# 로컬 파일로 써두기
resource "local_file" "kubeconfig" {
  content  = data.oci_containerengine_cluster_kube_config.this.content
  filename = pathexpand("~/.kube/oke.yaml")
  
  depends_on = [
    oci_containerengine_cluster.oke_cluster,
    oci_containerengine_node_pool.oke_node_pool
  ]
}

