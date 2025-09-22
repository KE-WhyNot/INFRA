# 카카오클라우드 자체 구축 Kubernetes 클러스터

# 1. 네트워크 리소스 (OpenStack)
data "openstack_networking_network_v2" "existing_vpc" {
  count = length(var.existing_vpc_id) > 0 ? 1 : 0
  network_id = var.existing_vpc_id
}

data "openstack_networking_subnet_v2" "existing_subnets" {
  count = length(var.existing_subnet_ids)
  subnet_id = var.existing_subnet_ids[count.index]
}

# 2. SSH 키페어 조회
data "openstack_compute_keypair_v2" "k8s_keypair" {
  name = var.ssh_key_name
}

# 3. 보안그룹 (Kubernetes 클러스터용)
resource "openstack_networking_secgroup_v2" "k8s_security_group" {
  name        = "${var.k8s_cluster_name}-sg-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  description = "Kubernetes Cluster Security Group"
}

# 4. 보안그룹 규칙들
resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_api_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "https_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "nodeport_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

# 워커가 마스터에서 join-command를 HTTP(8080)로 가져오기 위한 내부 통신 허용
resource "openstack_networking_secgroup_rule_v2" "join_http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "10.0.0.0/8"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

# 노드 간 필수 통신 허용 (Kubelet, Flannel VXLAN)
resource "openstack_networking_secgroup_rule_v2" "kubelet_internal_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_ip_prefix  = "10.0.0.0/8"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "flannel_vxlan_internal_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  remote_ip_prefix  = "10.0.0.0/8"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

# 메타데이터 서버 통신을 위한 HTTP 규칙 (SSH 키 설정용)
resource "openstack_networking_secgroup_rule_v2" "metadata_http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "169.254.169.254/32"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "all_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "all_udp_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
}

# 5. 마스터 노드 포트(고정 IP/보안그룹 명시) 생성
resource "openstack_networking_port_v2" "k8s_master_port" {
  name                = "${var.k8s_cluster_name}-master-port"
  network_id          = local.vpc_id
  admin_state_up      = true
  security_group_ids  = [openstack_networking_secgroup_v2.k8s_security_group.id]

  fixed_ip {
    subnet_id = local.master_subnet.id
    ip_address = cidrhost(local.master_subnet.cidr, 10)
  }
}

# 6. Floating IP 생성 및 포트에 직접 연결(연결 리소스 제거)
resource "openstack_networking_floatingip_v2" "k8s_master_fip" {
  pool    = var.floating_ip_pool
  port_id = openstack_networking_port_v2.k8s_master_port.id
}

# 6. 마스터 노드 생성
resource "openstack_compute_instance_v2" "k8s_master" {
  count           = var.master_node_count
  name            = "${var.k8s_cluster_name}-master-${count.index + 1}"
  image_id        = var.master_image_id
  flavor_id       = var.master_flavor_id
  key_pair        = data.openstack_compute_keypair_v2.k8s_keypair.name
  security_groups = [] # 포트 수준에서 SG 적용

  network {
    port = openstack_networking_port_v2.k8s_master_port.id
  }

  block_device {
    uuid                  = var.master_image_id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = var.master_volume_size
    boot_index            = 0
    delete_on_termination = true
  }

  metadata = {
    role = "master"
    cluster = var.k8s_cluster_name
    node_index = count.index + 1
  }

  tags = [for k, v in var.tags : "${k}=${v}"]
}

# 7. 워커 노드 생성
resource "openstack_compute_instance_v2" "k8s_worker" {
  count           = var.worker_node_count * var.worker_nodes_per_pool
  name            = "${var.k8s_cluster_name}-worker-${count.index + 1}"
  image_id        = var.worker_image_id
  flavor_id       = var.worker_flavor_id
  key_pair        = data.openstack_compute_keypair_v2.k8s_keypair.name
  security_groups = []

  network {
    port = openstack_networking_port_v2.k8s_worker_port[count.index].id
  }

  block_device {
    uuid                  = var.worker_image_id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = var.worker_volume_size
    boot_index            = 0
    delete_on_termination = true
  }

  metadata = {
    role = "worker"
    cluster = var.k8s_cluster_name
    node_index = count.index + 1
  }

  tags = [for k, v in var.tags : "${k}=${v}"]

  # cloud-init으로 SSH 없이 자동 조인
  user_data = <<-CLOUD
    #cloud-config
    package_update: true
    packages:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
    runcmd:
      - |
        set -e
        # 컨테이너 런타임 및 Kubernetes 설치
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | tee /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor | tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' > /etc/apt/sources.list.d/kubernetes.list
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io kubelet kubeadm kubectl
        apt-mark hold kubelet kubeadm kubectl || true
        swapoff -a || true
        sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab || true
        modprobe br_netfilter || true
        echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables || true
        echo 1 > /proc/sys/net/ipv4/ip_forward || true
        printf "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\n" > /etc/sysctl.d/k8s.conf
        sysctl --system || true
        mkdir -p /etc/containerd
        if command -v containerd >/dev/null 2>&1; then
          containerd config default > /etc/containerd/config.toml || true
          sed -i 's/^\(\s*SystemdCgroup\s*=\s*\)false/\1true/' /etc/containerd/config.toml || true
          systemctl restart containerd || true
          systemctl enable containerd || true
        fi
        systemctl enable docker || true
        systemctl start docker || true
        # 마스터 내부 IP로 join-command 받기
        MASTER_IP="${cidrhost(local.master_subnet.cidr, 10)}"
        for i in $(seq 1 30); do
          echo "[cloud-init] fetching join-command (attempt $i)..."
          JOIN_CMD=$(curl -fsS http://$MASTER_IP:8080/join-command.sh || true)
          if [ -n "$JOIN_CMD" ]; then
            echo "$JOIN_CMD" > /root/join.sh
            chmod +x /root/join.sh
            break
          fi
          sleep 10
        done
        if [ -s /root/join.sh ]; then
          bash -c "sudo /root/join.sh"
        else
          echo "[cloud-init] failed to fetch join command" >&2
        fi
  CLOUD
}

# 워커 노드용 포트 생성 (보안그룹을 포트에 직접 적용)
resource "openstack_networking_port_v2" "k8s_worker_port" {
  count               = var.worker_node_count * var.worker_nodes_per_pool
  name                = "${var.k8s_cluster_name}-worker-port-${count.index + 1}"
  network_id          = local.vpc_id
  admin_state_up      = true
  security_group_ids  = [openstack_networking_secgroup_v2.k8s_security_group.id]

  fixed_ip {
    subnet_id  = local.master_subnet.id
    ip_address = cidrhost(local.master_subnet.cidr, 20 + count.index)
  }
}

# 8. Floating IP는 위 리소스에서 포트에 직접 연결됨

# 9. SSH 연결 대기 및 검증
resource "null_resource" "wait_for_ssh" {
  depends_on = [
    openstack_compute_instance_v2.k8s_master,
    openstack_networking_floatingip_v2.k8s_master_fip
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "SSH 연결 대기 중... (최대 5분)"
      
      # SSH 키 권한 설정
      chmod 0400 ${path.module}/keys/k8s-cluster-key
      
      # SSH 연결 재시도 로직
      MAX_ATTEMPTS=30
      ATTEMPT=1
      
      while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        echo "SSH 연결 시도 $ATTEMPT/$MAX_ATTEMPTS..."
        
        if ssh -i ${path.module}/keys/k8s-cluster-key \
               -o StrictHostKeyChecking=no \
               -o ConnectTimeout=10 \
               -o BatchMode=yes \
               ubuntu@${openstack_networking_floatingip_v2.k8s_master_fip.address} \
               "echo 'SSH 연결 성공!'" 2>/dev/null; then
          echo "✅ SSH 연결 성공!"
          break
        else
          echo "❌ SSH 연결 실패. 10초 후 재시도..."
          sleep 10
          ATTEMPT=$((ATTEMPT + 1))
        fi
      done
      
      if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
        echo "❌ SSH 연결 실패. 최대 시도 횟수 초과."
        exit 1
      fi
    EOT
  }
}

# 10. Kubernetes 클러스터 초기화
resource "null_resource" "k8s_master_init" {
  depends_on = [null_resource.wait_for_ssh]

  provisioner "remote-exec" {
    connection {
      host        = openstack_networking_floatingip_v2.k8s_master_fip.address
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/keys/k8s-cluster-key")
      timeout     = "10m"
      agent       = false
    }

    script = "${path.module}/scripts/k8s-init.sh"
  }
}

# (옵션) kubeconfig를 로컬 파일로 저장 — 현재 Helm은 마스터에서 직접 실행하므로 필수는 아님
resource "null_resource" "fetch_kubeconfig" {
  count      = var.enable_argocd ? 0 : 0
  depends_on = [null_resource.k8s_master_init]
}

# 10. 워커 노드 조인
## SSH 없이 조인하도록 remote-exec 제거됨

# 11. 로컬 변수들
locals {
  vpc_id = data.openstack_networking_network_v2.existing_vpc[0].id
  master_subnet = data.openstack_networking_subnet_v2.existing_subnets[0]
}