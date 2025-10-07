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
    security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
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

# 로드밸런서 정보
output "loadbalancer_info" {
  description = "로드밸런서 정보"
  value = {
    floating_ip = openstack_networking_floatingip_v2.lb_fip.address
    note        = "카카오클라우드 콘솔에서 로드밸런서 생성 후 이 Floating IP를 연결하세요"
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
    mysql_type = "Kubernetes 내부 MySQL (Helm)"
    mysql_endpoint = local.mysql_endpoint_effective
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
    mysql_service = local.mysql_endpoint_effective
    note = "MySQL은 카카오클라우드 관리형 RDS, 나머지는 Helm으로 설치"
  }
}

# Ingress Controller 정보
output "ingress_controller_info" {
  description = "Ingress Controller 정보"
  value = {
    name      = helm_release.nginx_ingress.name
    namespace = helm_release.nginx_ingress.namespace
    status    = helm_release.nginx_ingress.status
    version   = helm_release.nginx_ingress.version
  }
}


# ArgoCD 및 Ingress 테스트 방법 안내
output "argocd_test_instructions" {
  description = "ArgoCD 및 Ingress Controller 테스트 방법"
  value = <<-EOT
    OpenStack Kubernetes 클러스터에 ArgoCD와 Ingress Controller가 설치되었습니다!
    
           테스트 방법:
           1. 클러스터에 연결:
               ssh -i keys/k8s-cluster-key ubuntu@${openstack_networking_floatingip_v2.k8s_master_fip.address}
       sudo cp /etc/kubernetes/admin.conf ~/.kube/config
       sudo chown ubuntu:ubuntu ~/.kube/config
    
    2. ArgoCD 상태 확인:
       kubectl get pods -n argocd
       kubectl get svc -n argocd
    
    3. Ingress Controller 상태 확인:
       kubectl get pods -n ingress-nginx
       kubectl get svc -n ingress-nginx
    
    4. ArgoCD UI 접속:
       kubectl port-forward -n argocd svc/argocd-server 8080:80
       # 브라우저에서 http://localhost:8080 접속
    
    5. auth-service 애플리케이션 확인 (ArgoCD가 자동 배포):
       kubectl get applications -n argocd
       kubectl get pods -n auth-service
       kubectl get svc -n auth-service
       kubectl get ingress -n auth-service
    
    6. LoadBalancer IP 확인 및 테스트:
       kubectl get svc -n ingress-nginx ingress-nginx-controller
       # auth-service 엔드포인트로 테스트
  EOT
}
