locals { name_prefix = var.name_prefix }

# 네트워크: 퍼블릭/프라이빗 서브넷, 라우터(SNAT), 보안그룹
resource "openstack_networking_network_v2" "net" {
  name           = "${local.name_prefix}-net"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "public" {
  name            = "${local.name_prefix}-public"
  network_id      = openstack_networking_network_v2.net.id
  cidr            = var.public_subnet_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
}

resource "openstack_networking_subnet_v2" "private" {
  name            = "${local.name_prefix}-private"
  network_id      = openstack_networking_network_v2.net.id
  cidr            = var.private_subnet_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers
}

resource "openstack_networking_router_v2" "router" {
  name                = "${local.name_prefix}-router"
  admin_state_up      = true
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "ri_public" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.public.id
}

resource "openstack_networking_router_interface_v2" "ri_private" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.private.id
}

resource "openstack_networking_secgroup_v2" "allow_common" {
  name        = "${local.name_prefix}-sg"
  description = "Common rules for K8s nodes and ingress"
}

resource "openstack_networking_secgroup_rule_v2" "ingress_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_common.id
}

resource "openstack_networking_secgroup_rule_v2" "ingress_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_common.id
}

resource "openstack_networking_secgroup_rule_v2" "ingress_k8s_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_common.id
}

resource "openstack_networking_secgroup_rule_v2" "egress_all" {
  direction         = "egress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_common.id
}



# Magnum 템플릿/클러스터 (옵션)
resource "openstack_containerinfra_clustertemplate_v1" "tmpl" {
  count                 = var.create_k8s ? 1 : 0
  name                  = "${local.name_prefix}-k8s-template"
  coe                   = "kubernetes"
  image                 = var.cluster_image
  external_network_id   = var.external_network_id
  flavor                = var.node_flavor
  master_flavor         = var.master_flavor
  dns_nameserver        = var.dns_nameservers[0]
  docker_storage_driver = "overlay2"
  network_driver        = var.network_driver
  volume_driver         = var.volume_driver
  docker_volume_size    = var.docker_volume_size
  master_lb_enabled     = true
  floating_ip_enabled   = true
  tls_disabled          = false
  server_type           = "vm"
  public                = false
  labels                = var.cluster_labels
}

resource "openstack_containerinfra_cluster_v1" "cluster" {
  count                = var.create_k8s ? 1 : 0
  name                 = "${local.name_prefix}-k8s"
  cluster_template_id  = openstack_containerinfra_clustertemplate_v1.tmpl[0].id
  keypair              = var.keypair
  master_count         = var.master_count
  node_count           = var.node_count
  create_timeout       = 60
  master_flavor        = var.master_flavor
  flavor               = var.node_flavor
  fixed_network        = openstack_networking_network_v2.net.name
  fixed_subnet         = openstack_networking_subnet_v2.private.name
}

# GitHub webhook to trigger infra repo CI on service repo pushes
resource "github_repository_webhook" "infra_trigger" {
  count      = var.create_github_webhook ? 1 : 0
  repository = var.github_infra_repo_name
  events     = ["push"]
  configuration {
    url          = "https://api.github.com/repos/${var.github_infra_repo_owner}/${var.github_infra_repo_name}/dispatches"
    content_type = "json"
    secret       = var.github_webhook_secret
  }
  active = true
}

// removed duplicate second block; first half of file remains canonical


