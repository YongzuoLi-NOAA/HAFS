#!/bin/bash -l
# Gaea scrontab driver for Rocoto ticks
# Runs under SLURM via #SCRON options from your scrontab entry.
# Safe for repeated invocation (singleton + flock).

set -Eeuo pipefail
umask 022

# --- Paths (edit only if you move things) ---
BASE="/gpfs/f5/cpchso/scratch/Yongzuo.Li/mom6_3d-fgat_rocoto"
ROCOTO_DIR="$BASE/rocoto"
LOG_DIR="$BASE/logs"
LOG="$ROCOTO_DIR/rocoto_cron.log"   # keep same path you already use
XML="$ROCOTO_DIR/test_soca_workflow.xml"
DB="$ROCOTO_DIR/test_soca_workflow.db"
LOCK="$ROCOTO_DIR/rocoto.lock"

# --- Minimal log rotation (5 MB per file) ---
rotate_if_big () {
  local f="$1" max=$((5*1024*1024))
  if [ -f "$f" ] && [ "$(stat -c%s "$f")" -ge "$max" ]; then
    mv -f "$f" "${f}.$(date -u +'%Y%m%dT%H%M%SZ')"
  fi
}

mkdir -p "$ROCOTO_DIR" "$LOG_DIR"
rotate_if_big "$LOG"

# Route all stdout/stderr to LOG from here on
exec >>"$LOG" 2>&1
echo "===== $(date -u +'%Y-%m-%dT%H:%M:%SZ') start (host: $(hostname -s)) ====="

# --- Better error context ---
trap 'rc=$?; echo "[ERROR] Exit code $rc at line $LINENO"
      module -t list || true
      tail -n 200 "$LOG" || true
      echo "===== $(date -u +'%Y-%m-%dT%H:%M:%SZ') end (rc=$rc) ====="
      exit $rc' ERR

set -x

# --- Quick sanity: SLURM partition available? ---
# Skip quietly if cron_c5 is down/unavailable — avoids noisy failures.
if ! sinfo -h -p cron_c5 >/dev/null 2>&1; then
  echo "[WARN] Partition cron_c5 not available; skipping this tick."
  set +x
  echo "===== $(date -u +'%Y-%m-%dT%H:%M:%SZ') end (partition down) ====="
  exit 0
fi

# --- Clean env & load your stack ---
module purge
module use /gpfs/f5/cpchso/scratch/Yongzuo.Li/GDASapp-20250619/global-workflow/sorc/gdas.cd/modulefiles
module load GDAS/gaeac5.intel
module -t list

# --- Ensure Rocoto CLI available ---
if ! command -v rocotorun >/dev/null 2>&1; then
  echo "[FATAL] rocotorun not found in PATH"
  exit 2
fi
rocotorun --version || true

# --- Inputs present? ---
cd "$ROCOTO_DIR"
[ -f "$XML" ] || { echo "[FATAL] Missing workflow XML: $XML"; exit 2; }
[ -f "$DB" ]  || touch "$DB"

# --- Lock to prevent concurrent DB access ---
exec 9>"$LOCK"
if ! flock -n 9; then
  echo "[INFO] Another instance holds $LOCK; skipping this tick."
  set +x
  echo "===== $(date -u +'%Y-%m-%dT%H:%M:%SZ') end (locked) ====="
  exit 0
fi

# --- Optional jitter so many users don’t slam at the same second ---
sleep $((RANDOM % 3))

# --- One Rocoto tick + quick status snapshot ---
rocotorun  -w "$XML" -d "$DB"
rocotostat -w "$XML" -d "$DB" || true

set +x
echo "===== $(date -u +'%Y-%m-%dT%H:%M:%SZ') end (ok) ====="

