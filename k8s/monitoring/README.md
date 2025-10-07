# 모니터링 스택 (kube-prometheus-stack)

이 디렉토리는 OKE(Oracle Kubernetes Engine)에서 kube-prometheus-stack을 사용하여 모니터링 스택을 배포하기 위한 설정을 포함합니다.

## 구성 요소

- **Prometheus**: 메트릭 수집 및 저장
- **Grafana**: 대시보드 및 시각화
- **kube-state-metrics**: Kubernetes 상태 메트릭
- **node-exporter**: 노드 메트릭 수집

## 디렉토리 구조

```
k8s/
└── monitoring/
    ├── cloud-shell-setup.sh   # Cloud Shell 배포 스크립트
    ├── cleanup.sh             # 정리 스크립트
    ├── values-prom.yaml       # kube-prometheus-stack values
    └── README.md              # 이 파일
```

## 배포 방법

### 1. Cloud Shell을 통한 자동 배포 (권장)

```bash
# Oracle Cloud Shell에서 실행
cd /path/to/INFRA
./k8s/monitoring/cloud-shell-setup.sh
```

이 스크립트는 다음을 자동으로 처리합니다:
- Grafana 관리자 비밀번호 입력 받기
- monitoring 네임스페이스 생성
- Grafana 관리자 시크릿 생성
- Helm Repository 추가
- kube-prometheus-stack 배포
- 배포 상태 확인
- 접근 정보 출력

### 2. Helm을 통한 수동 배포

```bash
# 네임스페이스 생성
kubectl create namespace monitoring

# Grafana 관리자 시크릿 생성
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='StrongPassword123!'

# Helm Repository 추가
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# kube-prometheus-stack 배포
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f k8s/monitoring/values-prom.yaml
```

## 접근 방법

### Prometheus
- **내부 접근**: `http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090`
- **포트 포워딩**: `kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring`

### Grafana
- **외부 접근**: `https://grafana.youth-fi.com` (Load Balancer에서 HTTPS 처리)
- **포트 포워딩**: `kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring`
- **로그인**: 
  - 사용자명: `admin`
  - 비밀번호: Cloud Shell에서 설정한 비밀번호

## 주요 설정

### Prometheus 설정
- **스토리지**: 20Gi PVC (oci-bv 스토리지 클래스)
- **리텐션**: 15일
- **자동 발견**: Kubernetes API, Pods, Services, Nodes
- **kube-state-metrics**: 활성화
- **node-exporter**: 활성화

### Grafana 설정
- **스토리지**: 10Gi PVC (oci-bv 스토리지 클래스)
- **데이터소스**: Prometheus 자동 연결
- **기본 대시보드**: Kubernetes 클러스터, Pods, Nodes 등
- **보안**: Load Balancer에서 HTTPS 처리, Ingress는 HTTP
- **관리자 계정**: Secret으로 관리 (Git 커밋 금지)

### 보안 설정
- **RBAC**: Kubernetes API 접근 권한
- **보안 컨텍스트**: 비루트 사용자, 읽기 전용 파일시스템
- **네트워크 정책**: 필요시 추가 설정 가능

## 모니터링 대상

### 자동 모니터링
- Kubernetes API 서버
- Kubernetes 노드
- Kubernetes Pods (prometheus.io/scrape=true 어노테이션)
- Nginx Ingress Controller

### 수동 설정 필요
- 애플리케이션별 메트릭 엔드포인트
- 커스텀 서비스 모니터링

## 트러블슈팅

### 일반적인 문제
1. **PVC 생성 실패**: OKE에서 `oci-bv` 스토리지 클래스 확인
2. **메트릭 수집 실패**: RBAC 권한 및 서비스 계정 확인
3. **Grafana 접근 불가**: Ingress 설정 및 DNS 확인

### 로그 확인
```bash
# Prometheus 로그
kubectl logs -f deployment/prometheus -n monitoring

# Grafana 로그
kubectl logs -f deployment/grafana -n monitoring
```

### 리소스 상태 확인
```bash
# 모든 리소스 상태
kubectl get all -n monitoring

# PVC 상태
kubectl get pvc -n monitoring

# 서비스 상태
kubectl get svc -n monitoring
```

## 업그레이드

### Helm 차트 업그레이드
```bash
# kube-prometheus-stack 업그레이드
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f k8s/monitoring/values-prom.yaml
```

### Cloud Shell을 통한 업그레이드
- Git 저장소의 values-prom.yaml 파일 수정 후 Cloud Shell에서 재실행
- 또는 Helm을 통한 직접 업그레이드

## 백업 및 복구

### Grafana 대시보드 백업
```bash
# 대시보드 내보내기 (Grafana UI에서)
# 또는 API를 통한 자동 백업 스크립트 작성
```

### Prometheus 데이터 백업
```bash
# PVC 백업 (OKE 스냅샷 기능 활용)
# 또는 Prometheus 원격 저장소 설정
```

## 성능 튜닝

### Prometheus
- `retention` 및 `retentionSize` 조정
- `scrape_interval` 최적화
- 리소스 제한 조정

### Grafana
- 대시보드 쿼리 최적화
- 캐싱 설정
- 리소스 제한 조정
