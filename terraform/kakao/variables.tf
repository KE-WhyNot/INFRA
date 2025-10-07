# 카카오클라우드 인증 정보
variable "kc_auth_url" {
  description = "카카오클라우드 인증 URL"
  type        = string
  default     = "https://iam.kakaocloud.com/identity/v3"
}

variable "kc_application_credential_id" {
  description = "카카오클라우드 Application Credential ID"
  type        = string
  sensitive   = true
}

variable "kc_application_credential_secret" {
  description = "카카오클라우드 Application Credential Secret"
  type        = string
  sensitive   = true
}

variable "kc_region" {
  description = "카카오클라우드 리전"
  type        = string
  default     = "kr-central-2"
}

# 자체 구축 Kubernetes 클러스터용 변수들

# Kubernetes 클러스터 설정
variable "k8s_cluster_name" {
  description = "Kubernetes 클러스터 이름"
  type        = string
  default     = "k8s-cluster"
}

variable "k8s_version" {
  description = "Kubernetes 버전"
  type        = string
  default     = "1.28"
}

variable "master_node_count" {
  description = "마스터 노드 수"
  type        = number
  default     = 1
}

variable "worker_node_count" {
  description = "워커 노드 수"
  type        = number
  default     = 3
}

variable "worker_nodes_per_pool" {
  description = "워커 노드 풀당 노드 수"
  type        = number
  default     = 1
}

variable "master_flavor_id" {
  description = "마스터 노드 Flavor ID"
  type        = string
  default     = "ff64c2aa-2e80-4cfd-a646-2b475270d31e" # m2a.large
}

variable "worker_flavor_id" {
  description = "워커 노드 Flavor ID"
  type        = string
  default     = "ff64c2aa-2e80-4cfd-a646-2b475270d31e" # m2a.large
}

variable "master_image_id" {
  description = "마스터 노드 이미지 ID"
  type        = string
  default     = "044eae16-ecc2-4f74-9345-5a9fe90d80a9" # Ubuntu 20.04 LTS
}

variable "worker_image_id" {
  description = "워커 노드 이미지 ID"
  type        = string
  default     = "044eae16-ecc2-4f74-9345-5a9fe90d80a9" # Ubuntu 20.04 LTS
}

variable "master_volume_size" {
  description = "마스터 노드 볼륨 크기 (GB)"
  type        = number
  default     = 30
}

variable "worker_volume_size" {
  description = "워커 노드 볼륨 크기 (GB)"
  type        = number
  default     = 30
}

# 네트워크 설정
variable "existing_vpc_id" {
  description = "기존 VPC ID"
  type        = string
  default     = "38717207-42ed-418c-8ed4-e8cc99c6d2b2"
}

variable "floating_ip_pool" {
  description = "Floating IP 풀 이름"
  type        = string
  default     = "EXTERNAL"
}

variable "existing_subnet_ids" {
  description = "기존 서브넷 ID 목록"
  type        = list(string)
  default     = [
    "3ec3dfb1-1942-4884-871d-e379add7387a", # main 서브넷
    "643cfe6d-391b-4725-9b5b-3b49bfc5d86e", # test_d354b_sn_1
    "98f4bc8e-a08b-4d56-90a4-00253b553441", # test_d354b_sn_2
    "8e5315c6-20b9-4f82-87aa-d4de575520d7"  # test_d354b_sn_3
  ]
}

# SSH 키 설정
variable "ssh_key_name" {
  description = "SSH 키페어 이름"
  type        = string
  default     = "k8s-cluster-key"
}

# 프로젝트 설정
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "infra-project"
}

variable "environment" {
  description = "환경"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
    Project     = "INFRA"
  }
}

variable "enable_argocd" {
  description = "ArgoCD 설치 여부 (2단계 적용)"
  type        = bool
  default     = false
}