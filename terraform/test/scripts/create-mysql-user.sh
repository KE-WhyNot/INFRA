#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-mysql}
MYSQL_SECRET_NAME=${MYSQL_SECRET_NAME:-mysql-secrets}

# MySQL 서비스 이름 자동 탐지 (환경변수 SERVICE_NAME가 없을 때)
# Bitnami MySQL 차트는 일반적으로 Service 이름이 "mysql" 이지만, 환경마다 다를 수 있으므로 탐지합니다.
SERVICE_NAME=${SERVICE_NAME:-$(kubectl get svc -n "$NAMESPACE" -l app.kubernetes.io/instance=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo mysql)}

# MySQL 호스트 도메인 조립
MYSQL_HOST="${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local"

# Secret에서 값 자동 로드 (환경변수 미설정 시)
if [[ -z "${DB_USER:-}" || -z "${DB_PASS:-}" || -z "${DB_NAME:-}" ]]; then
  echo "[mysql] Loading credentials from Secret '$MYSQL_SECRET_NAME' in namespace '$NAMESPACE'..."
  # 존재 확인
  if ! kubectl get secret "$MYSQL_SECRET_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "[mysql] Secret '$MYSQL_SECRET_NAME' not found in namespace '$NAMESPACE'" >&2
    echo "[mysql] Set DB_USER/DB_PASS/DB_NAME envs or create the Secret first." >&2
    exit 1
  fi
  DB_USER=${DB_USER:-$(kubectl get secret "$MYSQL_SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.mysql-username}' | base64 -d)}
  DB_PASS=${DB_PASS:-$(kubectl get secret "$MYSQL_SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.mysql-password}' | base64 -d)}
  DB_NAME=${DB_NAME:-$(kubectl get secret "$MYSQL_SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.mysql-database}' | base64 -d 2>/dev/null || echo auth)}
fi


# MySQL 서비스 준비 대기
echo "[mysql] Waiting for Service '$SERVICE_NAME' and endpoints in namespace '$NAMESPACE'..."
# Service 존재 대기 (최대 300초)
for i in $(seq 1 60); do
  if kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

# Endpoints 준비 대기 (최대 600초)
for i in $(seq 1 120); do
  if kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' >/dev/null; then
    break
  fi
  sleep 5
done

# 파드 Ready 대기 (라벨 기반)
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=mysql -n "$NAMESPACE" --timeout=600s || true


echo "[mysql] Creating user '$DB_USER' on database '$DB_NAME'..."
kubectl run mysql-client --rm -it --restart='Never' \
  --image docker.io/bitnami/mysql:9.4.0-debian-12-r1 \
  --namespace "$NAMESPACE" \
  --env MYSQL_ROOT_PASSWORD="$DB_PASS" \
  --command -- mysql -h "$MYSQL_HOST" -uroot -p"$DB_PASS" -e "
    CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
    CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
    GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
    FLUSH PRIVILEGES;
    SHOW DATABASES;
  "

echo "[mysql] Done."

