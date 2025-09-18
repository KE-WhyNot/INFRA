# OCI Infrastructure with Terraform

이 프로젝트는 OCI(Oracle Cloud Infrastructure)를 사용하여 Kubernetes 기반 마이크로서비스 인프라스트럭처를 구축하는 Terraform 코드입니다.

## 🏗️ 구성 요소

### 인프라 리소스
- **OKE (Oracle Kubernetes Engine)**: Kubernetes 클러스터
- **VCN (Virtual Cloud Network)**: 네트워킹 인프라
- **Container Registry**: 컨테이너 이미지 저장소
- **Vault**: 시크릿 관리
- **Storage**: 블록 볼륨, 파일 시스템, 객체 스토리지

### 애플리케이션
- **ArgoCD**: GitOps 기반 배포 도구
- **Auth Service**: 인증 서비스
- **Nginx Ingress**: 로드밸런서 및 SSL 종료

## 📋 사전 요구사항

1. **OCI CLI 설치**
   ```bash
   # macOS
   brew install oci-cli
   
   # Linux
   bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
   ```

2. **Terraform 설치**
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **OCI API 키 설정**
   ```bash
   oci setup config
   ```

## 🚀 배포 방법

### 1. 설정 파일 준비
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 파일을 편집하여 OCI 설정 정보 입력
```

### 2. 자동 배포 (권장)
```bash
./deploy.sh
```

### 3. 수동 배포
```bash
terraform init
terraform plan
terraform apply
```

## ⚙️ 설정 변수

주요 설정 변수들:

| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| `tenancy_ocid` | OCI 테넌시 OCID | - |
| `user_ocid` | OCI 사용자 OCID | - |
| `fingerprint` | API 키 지문 | - |
| `private_key_path` | API 키 파일 경로 | - |
| `region` | OCI 리전 | `ap-chuncheon-1` |
| `compartment_id` | 컴파트먼트 ID | - |
| `project_name` | 프로젝트 이름 | `infra` |
| `environment` | 환경 이름 | `dev` |
| `cluster_name` | OKE 클러스터 이름 | `oke-cluster` |
| `node_pool_size` | 노드 풀 크기 | `3` |
| `node_shape` | 노드 셰이프 | `VM.Standard.E4.Flex` |

## 📊 출력 정보

배포 완료 후 다음 정보들을 확인할 수 있습니다:

- **클러스터 정보**: 클러스터 ID, 엔드포인트
- **ArgoCD 접속 정보**: URL, 관리자 비밀번호
- **컨테이너 레지스트리**: 이미지 저장소 URL
- **시크릿 관리**: Vault ID, 시크릿 ID
- **스토리지**: 볼륨, 파일 시스템, 버킷 정보

## 🔧 유용한 명령어

```bash
# 클러스터 상태 확인
kubectl get nodes

# ArgoCD 애플리케이션 확인
kubectl get applications -n argocd

# ArgoCD 포트 포워딩
kubectl port-forward svc/argocd-server -n argocd 8080:80

# ArgoCD 관리자 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## 🗑️ 리소스 정리

```bash
terraform destroy
```

## 📁 파일 구조

```
terraform/
├── providers.tf              # Terraform 프로바이더 설정
├── variables.tf              # 변수 정의
├── networking.tf             # 네트워킹 리소스
├── oke-cluster.tf            # OKE 클러스터 및 노드 풀
├── container-registry.tf     # 컨테이너 레지스트리
├── secrets.tf                # Vault 및 시크릿 관리
├── storage.tf                # 스토리지 리소스
├── argocd.tf                 # ArgoCD 배포
├── outputs.tf                # 출력 정의
├── terraform.tfvars.example  # 설정 예제
├── deploy.sh                 # 자동 배포 스크립트
└── .gitignore                # Git 무시 파일
```

## 🔒 보안 고려사항

1. **API 키 보안**: `terraform.tfvars` 파일을 Git에 커밋하지 마세요
2. **시크릿 관리**: 프로덕션 환경에서는 Vault 시크릿을 적절히 변경하세요
3. **네트워크 보안**: 보안 그룹 규칙을 환경에 맞게 조정하세요
4. **접근 제어**: RBAC 설정을 검토하고 필요한 권한만 부여하세요

## 🆘 문제 해결

### 일반적인 문제들

1. **OCI CLI 인증 오류**
   ```bash
   oci setup config
   ```

2. **Terraform 프로바이더 오류**
   ```bash
   terraform init -upgrade
   ```

3. **ArgoCD 접속 불가**
   ```bash
   kubectl get pods -n argocd
   kubectl logs -f deployment/argocd-server -n argocd
   ```

## 📞 지원

문제가 발생하면 다음을 확인하세요:
- OCI 콘솔에서 리소스 상태 확인
- Terraform 로그 확인
- Kubernetes 클러스터 상태 확인
- ArgoCD 로그 확인
