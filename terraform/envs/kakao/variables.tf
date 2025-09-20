// consolidated below; removed duplicated single-line declarations

variable "name_prefix" {
  type        = string
  default     = "kakao-dev"
  description = "리소스 이름 접두사"
}

variable "external_network_id" {
  type        = string
  description = "외부 네트워크 ID(라우터 GW 연결용)"
}

variable "public_subnet_cidr" {
  type        = string
  default     = "10.30.1.0/24"
  description = "Public Subnet CIDR"
}

variable "private_subnet_cidr" {
  type        = string
  default     = "10.30.2.0/24"
  description = "Private Subnet CIDR"
}

variable "dns_nameservers" {
  type        = list(string)
  default     = ["8.8.8.8", "1.1.1.1"]
}

variable "create_k8s" {
  type        = bool
  default     = true
  description = "Magnum Kubernetes 클러스터 생성 여부"
}

variable "cluster_image" {
  type        = string
  description = "Magnum 클러스터 이미지 이름/ID"
}

variable "node_flavor" {
  type        = string
  description = "워커 노드 flavor"
}

variable "master_flavor" {
  type        = string
  description = "마스터 노드 flavor"
}

variable "docker_volume_size" {
  type        = number
  default     = 50
}

variable "network_driver" {
  type        = string
  default     = "flannel"
}

variable "volume_driver" {
  type        = string
  default     = "cinder"
}

variable "cluster_labels" {
  type        = map(string)
  default     = {}
}

variable "keypair" {
  type        = string
  description = "접속용 키페어 이름"
}

variable "master_count" {
  type        = number
  default     = 1
}

variable "node_count" {
  type        = number
  default     = 2
}

# GitHub webhook variables
variable "create_github_webhook" {
  type        = bool
  default     = false
  description = "Whether to create GitHub webhook to trigger infra repo CI"
}

variable "github_infra_repo_owner" {
  type        = string
  description = "GitHub owner/org of the infra repository"
}

variable "github_infra_repo_name" {
  type        = string
  description = "GitHub repository name of the infra repository"
}

variable "github_webhook_secret" {
  type        = string
  description = "GitHub webhook secret for infra repo CI trigger"
  sensitive   = true
}


