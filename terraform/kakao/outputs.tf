# 관리형 Kubernetes Engine 출력값들

# Kubernetes Engine 정보
output "k8s_engine_info" {
  description = "Kubernetes Engine 클러스터 정보"
  value = {
    cluster_name = var.k8s_cluster_name
    version      = var.k8s_version
    worker_count = var.worker_node_count
    status       = "생성됨"
    console_url  = "https://console.kakaocloud.com/kubernetes"
  }
}

# 네트워크 정보
output "network_info" {
  description = "네트워크 정보"
  value = {
    vpc_id    = var.existing_vpc_id
    subnet_ids = var.existing_subnet_ids
    security_group_id = openstack_networking_secgroup_v2.k8s_security_group.id
  }
}

# Kubernetes 클러스터 정보
output "k8s_cluster_info" {
  description = "Kubernetes 클러스터 정보"
  value = {
    cluster_name = var.k8s_cluster_name
    version      = var.k8s_version
    master_count = var.master_node_count
    worker_count = var.worker_node_count
    status       = "자체 구축 완료"
  }
}

# 마스터 노드 정보
output "master_node_info" {
  description = "마스터 노드 정보"
  value = {
    public_ip  = openstack_networking_floatingip_v2.k8s_master_fip.address
    private_ip = openstack_compute_instance_v2.k8s_master[0].access_ip_v4
    name       = openstack_compute_instance_v2.k8s_master[0].name
  }
}

# 워커 노드 정보
output "worker_nodes_info" {
  description = "워커 노드 정보"
  value = {
    count = var.worker_node_count
    nodes = [for i in range(var.worker_node_count) : {
      name       = openstack_compute_instance_v2.k8s_worker[i].name
      private_ip = openstack_compute_instance_v2.k8s_worker[i].access_ip_v4
    }]
  }
}

# 데이터베이스 정보
output "database_info" {
  description = "데이터베이스 정보"
  value = {
    note = "MySQL과 Redis는 Kubernetes 내부에서 실행됩니다"
    mysql_service = "mysql-service.default.svc.cluster.local:3306"
    redis_service = "redis-service.default.svc.cluster.local:6379"
  }
}

# 클러스터 접속 정보
output "cluster_access_info" {
  description = "클러스터 접속 정보"
  value = {
    cluster_name = var.k8s_cluster_name
    ssh_key_name = var.ssh_key_name
    note = "카카오클라우드 CLI를 사용하여 클러스터에 접속하세요"
    commands = [
      "kc kubernetes cluster list",
      "kc kubernetes cluster get-credentials ${var.k8s_cluster_name}",
      "kubectl get nodes"
    ]
  }
}

# 서비스 연결 정보
output "service_connection_info" {
  description = "서비스 연결 정보"
  value = {
    mysql_service = "mysql-service.default.svc.cluster.local:3306"
    note = "MySQL은 카카오클라우드 관리형 RDS, 나머지는 Helm으로 설치"
  }
}
