#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# Usage:
#   ./scripts/port-forward.sh start <namespace> <service_name> <local_port>:<svc_port>
#   ./scripts/port-forward.sh stop  <namespace> <service_name>
#   ./scripts/port-forward.sh list

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
PF_DIR="$ROOT_DIR/.port-forward"
mkdir -p "$PF_DIR"

cmd=${1:-}

pf_start() {
  local ns=$1 svc=$2 mapping=$3
  local pid_file="$PF_DIR/${ns}_${svc}.pid"

  if [[ -f "$pid_file" ]] && ps -p $(cat "$pid_file") >/dev/null 2>&1; then
    echo "[INFO] port-forward already running for $ns/$svc (pid $(cat "$pid_file"))"
    exit 0
  fi

  # Kill any stale processes
  pkill -f "kubectl port-forward svc/${svc} -n ${ns} ${mapping}" 2>/dev/null || true

  echo "[INFO] Starting port-forward: ns=$ns svc=$svc map=$mapping"
  nohup kubectl port-forward svc/${svc} -n ${ns} ${mapping} >/dev/null 2>&1 &
  echo $! > "$pid_file"
  sleep 1
  if ps -p $(cat "$pid_file") >/dev/null 2>&1; then
    echo "[OK] Started (pid $(cat "$pid_file"))"
  else
    echo "[ERROR] Failed to start port-forward"
    rm -f "$pid_file"
    exit 1
  fi
}

pf_stop() {
  local ns=$1 svc=$2
  local pid_file="$PF_DIR/${ns}_${svc}.pid"
  if [[ -f "$pid_file" ]]; then
    local pid=$(cat "$pid_file")
    if ps -p $pid >/dev/null 2>&1; then
      echo "[INFO] Stopping port-forward for $ns/$svc (pid $pid)"
      kill $pid || true
      sleep 1
    fi
    rm -f "$pid_file"
    echo "[OK] Stopped $ns/$svc"
  else
    echo "[INFO] No pid file for $ns/$svc"
  fi
}

pf_list() {
  printf "%-30s %-8s\n" "NAME" "PID"
  local files=("$PF_DIR"/*.pid)
  if [[ ${#files[@]} -eq 1 && ${files[0]} == "$PF_DIR/*.pid" ]]; then
    echo "(none)"; return 0
  fi
  if [[ ${#files[@]} -eq 0 ]]; then echo "(none)"; return 0; fi
  for f in "${files[@]}"; do
    base=$(basename "$f" .pid)
    pid=$(cat "$f")
    if ps -p "$pid" >/dev/null 2>&1; then
      printf "%-30s %-8s\n" "$base" "$pid"
    else
      printf "%-30s %-8s (stale)\n" "$base" "$pid"
    fi
  done
}

case "$cmd" in
  start)
    ns=${2:-}
    svc=${3:-}
    map=${4:-}
    if [[ -z "$ns" || -z "$svc" || -z "$map" ]]; then
      echo "Usage: $0 start <namespace> <service_name> <local_port>:<svc_port> | start <preset>"; echo "Presets: argocd | auth-service | redis | all"; exit 1
    fi
    pf_start "$ns" "$svc" "$map"
    ;;
  start-all)
    # Preset: start all common forwards
    pf_start argocd argocd-server 8000:80 || true
    pf_start auth-service auth-service 8080:80 || true
    # Redis: prefer 16379 to avoid local 6379 conflicts
    pf_start redis redis-redis 16379:6379 || true
    ;;
  start-preset)
    preset=${2:-}
    case "$preset" in
      argocd)
        pf_start argocd argocd-server 8000:80;;
      auth-service)
        pf_start auth-service auth-service 8080:80;;
      redis)
        # use 16379 locally to avoid conflicts
        pf_start redis redis-redis 16379:6379;;
      all)
        "$0" start-all;;
      *) echo "Unknown preset. Use: argocd | auth-service | redis | all"; exit 1;;
    esac
    ;;
  stop)
    ns=${2:-}
    svc=${3:-}
    if [[ -z "$ns" || -z "$svc" ]]; then
      echo "Usage: $0 stop <namespace> <service_name> | stop <preset> | stop-all"; echo "Presets: argocd | auth-service | redis | all"; exit 1
    fi
    pf_stop "$ns" "$svc"
    ;;
  stop-all)
    pf_stop argocd argocd-server || true
    pf_stop auth-service auth-service || true
    pf_stop redis redis-redis || true
    ;;
  stop-preset)
    preset=${2:-}
    case "$preset" in
      argocd)
        pf_stop argocd argocd-server;;
      auth-service)
        pf_stop auth-service auth-service;;
      redis)
        pf_stop redis redis-redis;;
      all)
        "$0" stop-all;;
      *) echo "Unknown preset. Use: argocd | auth-service | redis | all"; exit 1;;
    esac
    ;;
  list)
    pf_list
    ;;
  *)
    cat <<USAGE
Usage:
  $0 start <namespace> <service> <local_port>:<svc_port>
  $0 stop  <namespace> <service>
  $0 list

Presets:
  $0 start-preset argocd|auth-service|redis|all
  $0 stop-preset  argocd|auth-service|redis|all
  $0 start-all
  $0 stop-all

Defaults:
  argocd       -> argocd/argocd-server 8000:80
  auth-service -> auth-service/auth-service 8080:80
  redis        -> redis/redis-redis 16379:6379
USAGE
    exit 1
    ;;
esac


