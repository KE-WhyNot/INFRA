data "openstack_compute_flavor_v2" "master" {
  name = var.master_flavor_name
}
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

# 3. 보안그룹 (Kubernetes 워커 노드용)
resource "openstack_networking_secgroup_v2" "k8s_worker_security_group" {
  name        = "${var.k8s_cluster_name}-worker-sg-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  description = "Kubernetes Worker Nodes Security Group"
}

# 3-1. 보안그룹 (Kubernetes 마스터 노드용)
resource "openstack_networking_secgroup_v2" "k8s_master_security_group" {
  name        = "${var.k8s_cluster_name}-master-sg-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  description = "Kubernetes Master Node Security Group"
}

# 마스터 노드 전용 보안 그룹 규칙들
resource "openstack_networking_secgroup_rule_v2" "master_ssh_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_master_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "master_http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_master_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "master_https_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_master_security_group.id
}

# 마스터 노드용 Kubernetes API 서버 포트
resource "openstack_networking_secgroup_rule_v2" "master_k8s_api_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_master_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "master_icmp_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_master_security_group.id
}

# 마스터 노드에서 워커 노드로의 통신 허용
resource "openstack_networking_secgroup_rule_v2" "master_to_worker_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "10.0.0.0/20"
  security_group_id = openstack_networking_secgroup_v2.k8s_master_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "master_to_worker_udp_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "10.0.0.0/20"
  security_group_id = openstack_networking_secgroup_v2.k8s_master_security_group.id
}

# 마스터 노드 egress 규칙
resource "openstack_networking_secgroup_rule_v2" "master_all_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_master_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "master_all_udp_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_master_security_group.id
}

# 3-2. 보안그룹 (Kubernetes 로드밸런서용)
resource "openstack_networking_secgroup_v2" "k8s_lb_security_group" {
  name        = "${var.k8s_cluster_name}-lb-sg-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  description = "Kubernetes LoadBalancer Security Group"
}

# 4. 보안그룹 규칙들 (워커 노드용)
# DHCP 응답 수신 (인스턴스가 IP 못 받으면 SSH 절대 안 열립니다)
resource "openstack_networking_secgroup_rule_v2" "dhcp_client_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 68
  port_range_max    = 68
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "dhcp_client_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 67
  port_range_max    = 67
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

# 진단/MTU 문제 방지용
resource "openstack_networking_secgroup_rule_v2" "icmp_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "k8s_api_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "https_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "nodeport_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

# 워커가 마스터에서 join-command를 HTTP(8080)로 가져오기 위한 내부 통신 허용
resource "openstack_networking_secgroup_rule_v2" "join_http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = local.master_subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

# 노드 간 필수 통신 허용 (Kubelet, Flannel VXLAN)
resource "openstack_networking_secgroup_rule_v2" "kubelet_internal_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_ip_prefix  = local.master_subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "flannel_vxlan_internal_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  remote_ip_prefix  = local.master_subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

# 메타데이터 서버 통신을 위한 HTTP 규칙 (SSH 키 설정용)
resource "openstack_networking_secgroup_rule_v2" "metadata_http_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "169.254.169.254/32"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "all_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

resource "openstack_networking_secgroup_rule_v2" "all_udp_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
}

# 4-1. 보안그룹 규칙들 (로드밸런서용)
# HTTP 트래픽
resource "openstack_networking_secgroup_rule_v2" "lb_http_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_lb_security_group.id
}

# HTTPS 트래픽
resource "openstack_networking_secgroup_rule_v2" "lb_https_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_lb_security_group.id
}

# 로드밸런서용 Kubernetes API 서버 포트
resource "openstack_networking_secgroup_rule_v2" "lb_k8s_api_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_lb_security_group.id
}

# 로드밸런서용 SSH 포트
resource "openstack_networking_secgroup_rule_v2" "lb_ssh_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_lb_security_group.id
}

# 로드밸런서용 NodePort 범위 (Kubernetes NodePort 서비스용)
resource "openstack_networking_secgroup_rule_v2" "lb_nodeport_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_lb_security_group.id
}

# 로드밸런서 아웃바운드 트래픽
resource "openstack_networking_secgroup_rule_v2" "lb_all_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_lb_security_group.id
}

# 5. 마스터 노드 포트(고정 IP/보안그룹 명시) 생성
resource "openstack_networking_port_v2" "k8s_master_port" {
  name                = "${var.k8s_cluster_name}-master-port"
  network_id          = local.vpc_id
  admin_state_up      = true
  security_group_ids  = [openstack_networking_secgroup_v2.k8s_master_security_group.id]

  fixed_ip {
    subnet_id = local.master_subnet.id
    ip_address = cidrhost(local.master_subnet.cidr, 10)
  }
}

# 마스터 노드 Floating IP 제거 (로드밸런서를 통한 접속 사용)

# 7. 마스터 노드 생성
resource "openstack_compute_instance_v2" "k8s_master" {
  count           = var.master_node_count
  name            = "${var.k8s_cluster_name}-master-${count.index + 1}"
  image_id        = var.master_image_id
  #flavor_id       = var.master_flavor_id
  flavor_id       = coalesce(try(data.openstack_compute_flavor_v2.master.id, null), var.master_flavor_id)
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

# 8. Floating IP를 포트에 연결 (인스턴스 부팅 후)
# Floating IP 연결 제거 (로드밸런서를 통한 접속 사용)

# 11. 워커 노드 생성
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
        LOG_FILE=/var/log/kubeadm-join.log
        echo "[cloud-init] starting join sequence" | tee -a "$LOG_FILE"

        # 1) join-command 가져오기: 최대 60회, 10초 간격
        for i in $(seq 1 60); do
          echo "[cloud-init] fetching join-command (attempt $i)..." | tee -a "$LOG_FILE"
          JOIN_CMD=$(curl -fsS http://$MASTER_IP:8080/join-command.sh || true)
          if [ -n "$JOIN_CMD" ]; then
            echo "$JOIN_CMD" > /root/join.sh
            chmod +x /root/join.sh
            echo "[cloud-init] join-command fetched" | tee -a "$LOG_FILE"
            break
          fi
          sleep 10
        done

        # 2) kubeadm join 재시도: 최대 20회, 10초 간격 (실패 시 reset 후 재시도)
        if [ -s /root/join.sh ]; then
          for j in $(seq 1 20); do
            echo "[cloud-init] executing kubeadm join (try $j/20)" | tee -a "$LOG_FILE"
            if bash -c "sudo /root/join.sh" >> "$LOG_FILE" 2>&1; then
              echo "[cloud-init] kubeadm join success" | tee -a "$LOG_FILE"
              break
            else
              echo "[cloud-init] kubeadm join failed, resetting and retrying..." | tee -a "$LOG_FILE"
              kubeadm reset -f >> "$LOG_FILE" 2>&1 || true
              systemctl restart kubelet || true
              sleep 10
            fi
          done
        else
          echo "[cloud-init] failed to fetch join command" | tee -a "$LOG_FILE" >&2
        fi
  CLOUD
}

# 12. 워커 노드용 포트 생성 (보안그룹을 포트에 직접 적용)
resource "openstack_networking_port_v2" "k8s_worker_port" {
  count               = var.worker_node_count * var.worker_nodes_per_pool
  name                = "${var.k8s_cluster_name}-worker-port-${count.index + 1}"
  network_id          = local.vpc_id
  admin_state_up      = true
  security_group_ids  = [openstack_networking_secgroup_v2.k8s_worker_security_group.id]

  fixed_ip {
    subnet_id  = local.master_subnet.id
    ip_address = cidrhost(local.master_subnet.cidr, 20 + count.index)
  }
}

# 8. Floating IP는 별도 association 리소스에서 포트에 연결됨

# Floating IP 연결 상태 확인 제거 (로드밸런서를 통한 접속 사용)

# 10. SSH 연결 대기 및 검증 (단순화)
resource "null_resource" "wait_for_ssh" {
  depends_on = [openstack_networking_floatingip_associate_v2.k8s_master_fip_association]

  provisioner "local-exec" {
    command = <<-EOT
      echo "SSH 연결 준비 중..."
      
      # SSH 키 권한 설정
      chmod 0400 ${path.module}/keys/k8s-cluster-key
      
      FIP_ADDRESS="${openstack_networking_floatingip_v2.k8s_master_fip.address}"
      echo "대상 서버: ubuntu@$FIP_ADDRESS"
      
      # 간단한 대기 (2분)
      echo "SSH 서비스 준비를 위해 2분 대기..."
      sleep 120
      
      # SSH 연결 테스트
      echo "SSH 연결 테스트..."
      ssh -i ${path.module}/keys/k8s-cluster-key \
          -o StrictHostKeyChecking=no \
          -o ConnectTimeout=30 \
          -o BatchMode=yes \
          -o UserKnownHostsFile=/dev/null \
          ubuntu@$FIP_ADDRESS \
          "echo 'SSH 연결 성공!'" || echo "SSH 연결 실패 - 수동으로 확인 필요"
    EOT
  }
}

# API 서버 가용성 대기 (단순화)
resource "null_resource" "wait_for_k8s_api" {
  depends_on = [null_resource.k8s_master_init]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Kubernetes API 서비스 준비 대기 중..."
      
      # 간단한 대기 (2분)
      echo "API 서버 준비를 위해 2분 대기..."
      sleep 120
      
      # API 연결 테스트
      echo "API 서버 연결 테스트..."
      nc -zv ${openstack_networking_floatingip_v2.k8s_master_fip.address} 6443 || echo "API 연결 실패 - 수동으로 확인 필요"
    EOT
  }
}

# Helm 사전 정리(있다면 제거) - ingress-nginx
resource "null_resource" "preclean_ingress" {
  depends_on = [null_resource.copy_kubeconfig, null_resource.wait_for_k8s_api]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "[preclean] ingress-nginx 기존 릴리즈 점검/정리"
      if helm -n ingress-nginx status ingress-nginx >/dev/null 2>&1; then
        echo "[preclean] 기존 ingress-nginx 발견 → 삭제"
        helm -n ingress-nginx uninstall ingress-nginx || true
      else
        echo "[preclean] 기존 ingress-nginx 없음"
      fi
    EOT
  }
}

# Helm 사전 정리(있다면 제거) - argocd
resource "null_resource" "preclean_argocd" {
  depends_on = [null_resource.copy_kubeconfig, null_resource.wait_for_k8s_api]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "[preclean] argocd 기존 릴리즈 점검/정리"
      if helm -n argocd status argocd >/dev/null 2>&1; then
        echo "[preclean] 기존 argocd 발견 → 삭제"
        helm -n argocd uninstall argocd || true
      else
        echo "[preclean] 기존 argocd 없음"
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
      private_key = file(coalesce(var.ssh_private_key_path, "${path.module}/keys/k8s-cluster-key"))
      timeout     = "10m"
      agent       = false
    }

    script = "${path.module}/scripts/k8s-init.sh"
  }
}

# 11. kubeconfig 파일을 로컬로 복사 (TLS 인증서 문제 해결)
resource "null_resource" "copy_kubeconfig" {
  depends_on = [null_resource.k8s_master_init, null_resource.ssh_connection_test]

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ~/.kube
      
      # SSH 호스트 키 정리 (IP 변경 시 발생하는 문제 해결)
      ssh-keygen -R ${openstack_networking_floatingip_v2.k8s_master_fip.address} 2>/dev/null || true
      
      # 새로운 kubeconfig 복사
      scp -i ${path.module}/keys/k8s-cluster-key \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          ubuntu@${openstack_networking_floatingip_v2.k8s_master_fip.address}:~/.kube/config \
          ~/.kube/config
      
      # kubeconfig의 server를 퍼블릭 IP로 치환
      KCFG=~/.kube/config
      API_PUBLIC=https://${openstack_networking_floatingip_v2.k8s_master_fip.address}:6443
      export API_PUBLIC
      
      echo "현재 kubeconfig server 주소 확인:"
      grep -A 5 "server:" "$KCFG" || true
      
      # server 교체 (퍼블릭 IP) - 강제로 모든 server 주소 변경
      sed -i '' "s#server: https://.*:6443#server: $${API_PUBLIC}#g" "$KCFG"
      sed -i '' "s#server: https://10\..*:6443#server: $${API_PUBLIC}#g" "$KCFG"
      
      # TLS 인증서 검증 비활성화 (클러스터 섹션에만 적용)
      sed -i '' '/^  cluster:/a\    insecure-skip-tls-verify: true' "$KCFG"
      
      echo "수정된 kubeconfig server 주소:"
      grep -A 5 "server:" "$KCFG" || true
      
      echo "kubeconfig 업데이트 완료: $API_PUBLIC"
    EOT
  }
}

# kubeconfig 수동 재생성 (TLS 문제 해결용)
resource "null_resource" "regenerate_kubeconfig" {
  depends_on = [null_resource.copy_kubeconfig]

  provisioner "local-exec" {
    command = <<-EOT
      echo "=========================================="
      echo "kubeconfig 수동 재생성"
      echo "=========================================="
      
      # SSH 호스트 키 정리
      ssh-keygen -R ${openstack_networking_floatingip_v2.k8s_master_fip.address} 2>/dev/null || true
      
      # SSH로 마스터 노드에 접속하여 kubeconfig 재생성
      ssh -i ${path.module}/keys/k8s-cluster-key \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          ubuntu@${openstack_networking_floatingip_v2.k8s_master_fip.address} << 'EOF'
        
        # kubeconfig 재생성
        sudo cp /etc/kubernetes/admin.conf ~/.kube/config
        sudo chown ubuntu:ubuntu ~/.kube/config
        
        # 클러스터 정보 확인
        kubectl cluster-info
        kubectl get nodes
        
      EOF
      
      # 로컬로 kubeconfig 다시 복사
      scp -i ${path.module}/keys/k8s-cluster-key \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          ubuntu@${openstack_networking_floatingip_v2.k8s_master_fip.address}:~/.kube/config \
          ~/.kube/config
      
      # kubeconfig server 주소 수정
      API_PUBLIC=https://${openstack_networking_floatingip_v2.k8s_master_fip.address}:6443
      sed -i '' "s#server: https://.*:6443#server: $${API_PUBLIC}#g" ~/.kube/config
      
      # TLS 인증서 검증 비활성화 (클러스터 섹션에만 적용)
      sed -i '' '/^  cluster:/a\    insecure-skip-tls-verify: true' ~/.kube/config
      
      echo "kubeconfig 재생성 완료: $API_PUBLIC"
      echo "=========================================="
    EOT
  }
}

# kubeconfig 검증 및 kubectl 연결 테스트
resource "null_resource" "kubeconfig_validation" {
  depends_on = [null_resource.regenerate_kubeconfig]

  provisioner "local-exec" {
    command = <<-EOT
      echo "=========================================="
      echo "kubeconfig 검증 및 연결 테스트"
      echo "=========================================="
      
      # kubeconfig server 주소 확인
      echo "현재 kubeconfig server 주소:"
      kubectl config view --minify | grep server || true
      
      # TLS 설정 확인
      echo "TLS 설정 확인:"
      kubectl config view --minify | grep -A 5 "cluster:" || true
      
      # 클러스터 연결 테스트
      echo "클러스터 연결 테스트:"
      kubectl cluster-info || true
      
      # 노드 상태 확인
      echo "노드 상태:"
      kubectl get nodes || true
      
      echo "=========================================="
    EOT
  }
}

# SSH 연결 테스트 (단순화)
resource "null_resource" "ssh_connection_test" {
  depends_on = [null_resource.wait_for_ssh]

  provisioner "local-exec" {
    command = <<-EOT
      echo "SSH 연결 최종 테스트..."
      
      FIP_ADDRESS="${openstack_networking_floatingip_v2.k8s_master_fip.address}"
      echo "Floating IP: $FIP_ADDRESS"
      
      # 간단한 연결 테스트
      ping -c 1 $FIP_ADDRESS && echo "✅ Ping 성공" || echo "❌ Ping 실패"
      nc -z -w3 $FIP_ADDRESS 22 && echo "✅ SSH 포트 열림" || echo "❌ SSH 포트 닫힘"
    EOT
  }
}

 
# Secret 파일들을 Kubernetes에 적용
resource "null_resource" "apply_secrets" {
  depends_on = [
    null_resource.kubeconfig_validation,
    null_resource.wait_for_k8s_api
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "[secrets] Creating namespaces and applying Secret files..."
      
      # 필요한 네임스페이스들 생성
      kubectl create namespace auth-service --dry-run=client -o yaml | kubectl apply -f -
      kubectl create namespace mysql --dry-run=client -o yaml | kubectl apply -f -
      kubectl create namespace redis --dry-run=client -o yaml | kubectl apply -f -
      
    EOT
  }
}

# ArgoCD Application 매니페스트들을 자동으로 등록
# 이제 ArgoCD가 GitOps 방식으로 애플리케이션들을 관리합니다
resource "null_resource" "register_argocd_applications" {
  depends_on = [
    helm_release.argocd,
    null_resource.apply_secrets,
    null_resource.kubeconfig_validation,
    null_resource.wait_for_k8s_api
  ]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "[argocd-apps] Registering ArgoCD Applications..."
      
      # ArgoCD가 준비될 때까지 대기
      echo "Waiting for ArgoCD to be ready..."
      kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
      
      # 기존 secrets Application이 있다면 삭제
      kubectl delete application secrets -n argocd --ignore-not-found=true || true
      
      # Application 매니페스트들 적용
      kubectl apply -f ${path.module}/applications/ || true
      
      # Secret 파일들 적용 (네임스페이스 생성 후)
      echo "Applying secrets..."
      kubectl apply -f ${path.module}/secret/ || true
      
      echo "[argocd-apps] ArgoCD Applications registered successfully"
      
      # auth-service Application 강제 동기화 (TLS 설정 반영)
      echo "Syncing auth-service application..."
      kubectl patch application auth-service -n argocd --type merge -p '{"operation":{"sync":{"syncOptions":["CreateNamespace=true"]}}}' || true
    EOT
  }
}

# 로컬 변수들
locals {
  vpc_id       = data.openstack_networking_network_v2.existing_vpc[0].id
  master_subnet = data.openstack_networking_subnet_v2.existing_subnets[0]

  # MySQL 엔드포인트 설정 (Kubernetes 내부 MySQL 사용)
  mysql_endpoint_effective = "mysql.mysql.svc.cluster.local:3306"
}

# cert-manager 및 Let's Encrypt 제거 (Cloudflare 인증서 사용)

############################################
# LoadBalancer Floating IP 연결
############################################

# 마스터 노드용 Floating IP 생성 (SSH, K8s API 접속용)
resource "openstack_networking_floatingip_v2" "k8s_master_fip" {
  pool = var.floating_ip_pool
}

# 마스터 노드 Floating IP 연결
resource "openstack_networking_floatingip_associate_v2" "k8s_master_fip_association" {
  floating_ip = openstack_networking_floatingip_v2.k8s_master_fip.address
  port_id     = openstack_networking_port_v2.k8s_master_port.id
}

# 로드밸런서용 Floating IP 생성 (HTTP/HTTPS용)
resource "openstack_networking_floatingip_v2" "lb_fip" {
  pool = var.floating_ip_pool
  
  # 고정 FIP 주소가 제공되면 해당 FIP를 재사용
  address = length(var.lb_floating_ip_address) > 0 ? var.lb_floating_ip_address : null

  lifecycle {
    ignore_changes = [address]
  }
}

# 로드밸런서에 Floating IP 자동 연결
# 주의: 로드밸런서가 이미 생성되어 있어야 함
resource "null_resource" "connect_lb_fip" {
  depends_on = [openstack_networking_floatingip_v2.lb_fip]

  provisioner "local-exec" {
    command = <<-EOT
      echo "로드밸런서에 Floating IP 연결 중..."
      echo "Floating IP: ${openstack_networking_floatingip_v2.lb_fip.address}"
      
      # OpenStack CLI를 사용하여 로드밸런서에 Floating IP 연결
      # 로드밸런서 ID를 찾아서 Floating IP 연결
      LB_ID=$(openstack loadbalancer list --name KEA-LB -f value -c id 2>/dev/null || echo "")
      
      if [ -n "$LB_ID" ]; then
        echo "로드밸런서 ID: $LB_ID"
        echo "Floating IP 연결 시도..."
        
        # 로드밸런서에 Floating IP 연결 (VIP에 연결)
        openstack floating ip set --port $LB_ID ${openstack_networking_floatingip_v2.lb_fip.address} 2>/dev/null || {
          echo "⚠️ 자동 연결 실패 - 수동으로 연결하세요"
          echo "카카오클라우드 콘솔에서 로드밸런서에 Floating IP를 연결하세요"
        }
      else
        echo "⚠️ 로드밸런서를 찾을 수 없습니다 - 수동으로 연결하세요"
        echo "로드밸런서 이름: KEA-LB"
        echo "Floating IP: ${openstack_networking_floatingip_v2.lb_fip.address}"
      fi
    EOT
  }
}

# 로드밸런서 생성 (카카오클라우드 콘솔에서 수동 생성 필요)
# 이 리소스는 실제로는 생성되지 않고, 수동으로 생성한 로드밸런서 정보만 참조
resource "null_resource" "create_loadbalancer" {
  depends_on = [openstack_networking_floatingip_v2.lb_fip]

  provisioner "local-exec" {
    command = <<-EOT
      echo "=========================================="
      echo "로드밸런서 수동 생성 안내"
      echo "=========================================="
      echo "1. 카카오클라우드 콘솔에서 로드밸런서 생성:"
      echo "   - 이름: KEA-LB"
      echo "   - VPC: test"
      echo "   - 서브넷: main"
      echo ""
      echo "2. 백엔드 서버 추가:"
      echo "   - 서버 IP: ${openstack_compute_instance_v2.k8s_master[0].access_ip_v4}"
      echo "   - 포트: 22, 80, 443, 6443"
      echo ""
      echo "3. Floating IP 연결:"
      echo "   - Floating IP: ${openstack_networking_floatingip_v2.lb_fip.address}"
      echo "   - 로드밸런서에 연결"
      echo ""
      echo "4. 로드밸런서 생성 완료 후 다음 명령 실행:"
      echo "   terraform apply -target=null_resource.wait_for_lb_ready"
      echo "=========================================="
    EOT
  }
}

# 로드밸런서 준비 대기
resource "null_resource" "wait_for_lb_ready" {
  depends_on = [null_resource.create_loadbalancer]

  provisioner "local-exec" {
    command = <<-EOT
      echo "로드밸런서 준비 상태 확인 중..."
      echo "Floating IP: ${openstack_networking_floatingip_v2.lb_fip.address}"
      
      # 로드밸런서 HTTP/HTTPS 포트 연결 테스트
      for i in {1..30}; do
        if nc -zv ${openstack_networking_floatingip_v2.lb_fip.address} 80 2>/dev/null; then
          echo "✅ 로드밸런서 HTTP 포트 연결 성공"
          break
        fi
        echo "⏳ 로드밸런서 연결 대기... (attempt $i/30)"
        sleep 10
      done
      
      if ! nc -zv ${openstack_networking_floatingip_v2.lb_fip.address} 80 2>/dev/null; then
        echo "❌ 로드밸런서 연결 실패 - 수동으로 확인 필요"
        exit 1
      fi
    EOT
  }
}

# Fallback externalIPs 설정 제거 (카카오클라우드 콘솔에서 로드밸런서 사용)

# OpenStack CCM 제거 (카카오클라우드 콘솔에서 로드밸런서 사용)

