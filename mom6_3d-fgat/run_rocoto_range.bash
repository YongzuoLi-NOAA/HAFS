#!/bin/bash -l
# Drive Rocoto cycles WITHOUT scrontab.
# Usage:
#   ./run_rocoto_range.bash START_CYCLE END_CYCLE STEP_HOURS XML DB
#
# Examples:
#   ./run_rocoto_range.bash 202404231200 202405311200 24 test_soca_workflow.xml test_soca_workflow.db
#   ./run_rocoto_range.bash 2024042312   2024053112   24 test_soca_workflow.xml test_soca_workflow.db
#
# Notes:
# - START/END may be 10 digits (YYYYMMDDHH) or 12 digits (YYYYMMDDHHMM).
# - We normalize internally to 12-digit (append "00" if needed).

set -euo pipefail

# ---------- Args & defaults ----------
START_RAW=${1:?Usage: $0 START_CYCLE END_CYCLE STEP_HOURS XML DB}
END_RAW=${2:?Usage: $0 START_CYCLE END_CYCLE STEP_HOURS XML DB}
STEP_HOURS=${3:-24}
XML=${4:-test_soca_workflow.xml}
DB=${5:-test_soca_workflow.db}

SLEEP_SECS=${SLEEP_SECS:-180}   # polling interval
VERBOSE=${VERBOSE:-10}          # rocotorun -v level

# ---------- Helpers ----------
die(){ echo "ERROR: $*" >&2; exit 2; }

norm_cycle_12 () {
  # Normalize to 12-digit cycle (YYYYMMDDHHMM).
  local c="$1"
  case "${#c}" in
    12) echo "$c" ;;
    10) echo "${c}00" ;;             # append minutes
    *)  die "Cycle '$c' must be 10 or 12 digits (got ${#c})." ;;
  esac
}

# Print a single-cycle rocotostat table; return 0 even if empty so caller can parse
get_table () {
  local c12="$1"
  rocotostat -w "$XML" -d "$DB" -c "$c12" 2>/dev/null || true
}

# Count state lines from rocotostat table (excluding headers)

count_states () {
  local table="$1"
  local total ready queued running delayed submitting submitted retrying succeeded dead other
  total=$(      awk 'NR>1{n++} END{print n+0}'                           <<<"$table")
  ready=$(      awk 'NR>1 && $0 ~ / READY /{n++}      END{print n+0}'     <<<"$table")
  queued=$(     awk 'NR>1 && $0 ~ / QUEUED /{n++}     END{print n+0}'     <<<"$table")
  running=$(    awk 'NR>1 && $0 ~ / RUNNING /{n++}    END{print n+0}'     <<<"$table")
  delayed=$(    awk 'NR>1 && $0 ~ / DELAYED /{n++}    END{print n+0}'     <<<"$table")
  submitting=$( awk 'NR>1 && $0 ~ / SUBMITTING /{n++} END{print n+0}'     <<<"$table")
  submitted=$(  awk 'NR>1 && $0 ~ / SUBMITTED /{n++}  END{print n+0}'     <<<"$table")
  retrying=$(   awk 'NR>1 && $0 ~ / RETRYING /{n++}   END{print n+0}'     <<<"$table")
  succeeded=$(  awk 'NR>1 && $0 ~ / SUCCEEDED /{n++}  END{print n+0}'     <<<"$table")
  dead=$(       awk 'NR>1 && $0 ~ / DEAD /{n++}       END{print n+0}'     <<<"$table")
  other=$(( total - ready - queued - running - delayed - submitting - submitted - retrying - succeeded - dead ))
  echo "$ready,$queued,$running,$delayed,$submitting,$submitted,$retrying,$succeeded,$dead,$other,$total"
}

# Generate 12-digit cycles (YYYYMMDDHHMM) inclusive range
gen_cycles_12 () {
  python3 - "$START12" "$END12" "$STEP_HOURS" << 'PY'
import sys, datetime as dt
start = dt.datetime.strptime(sys.argv[1], "%Y%m%d%H%M")
end   = dt.datetime.strptime(sys.argv[2], "%Y%m%d%H%M")
step  = dt.timedelta(hours=int(sys.argv[3]))
t = start
while t <= end:
    print(t.strftime("%Y%m%d%H%M"))
    t += step
PY
}

# ---------- Sanity ----------
[[ -f "$XML" ]] || die "Missing XML: $XML"

START12=$(norm_cycle_12 "$START_RAW")
END12=$(norm_cycle_12 "$END_RAW")

echo "XML: $XML"
echo "DB : $DB"
echo "Range: ${START12} → ${END12} (Δ=${STEP_HOURS}h)"
echo

# ---------- Main loop ----------
for c12 in $(gen_cycles_12); do
  echo "=== Cycle $c12 ==="

  # Shepherd this cycle until no active tasks remain
  while true; do
    # Kick Rocoto once
    
    echo ++++++++++ AT AAAA ++++++++++
    date
    squeue -l -u $USER
    if [[ -f test_soca_workflow.db ]]; then
    rocotostat -w test_soca_workflow.xml -d test_soca_workflow.db | grep "$c12"
    fi 

    rocotorun -w "$XML" -d "$DB"

    echo after ROCOTORUN HAHaHaha 
    date
    squeue -l -u $USER
    if [[ -f test_soca_workflow.db ]]; then
    rocotostat -w test_soca_workflow.xml -d test_soca_workflow.db | grep "$c12"
    fi 

    rocotorun -w "$XML" -d "$DB" -c "$c12" -v "$VERBOSE" || true

    echo after ROCOTORUN BBBB 
    #date
    #squeue -l -u $USER
    # if [[ -f test_soca_workflow.db ]]; then
    # rocotostat -w test_soca_workflow.xml -d test_soca_workflow.db | grep "$c12"
    # fi 
    # echo before SLEEP "$SLEEP_SECS"
    # sleep "$SLEEP_SECS"
    # echo after SLEEP "$SLEEP_SECS"
    date
    squeue -l -u $USER
    if [[ -f test_soca_workflow.db ]]; then
    rocotostat -w test_soca_workflow.xml -d test_soca_workflow.db | grep "$c12"
    fi 

    table="$(get_table "$c12")"

    # If table has only header (or is empty), hint about missing jobs
    lines=$(wc -l <<<"$table" | awk '{print $1}')
    if [[ -z "$table" || "$lines" -le 1 ]]; then
      echo "   No jobs exist for $c12 — check <cycledef> coverage or task filters;"
      echo "   ensure tasks include cycledefs=\"group1\" (or your cycledef name),"
      echo "   and that the cycle timestamp format matches your workflow."
      # Nothing to do; advance to next cycle
      break
    fi

    stats=$(count_states "$table")
    IFS=',' read ready queued running delayed submitting submitted retrying succeeded dead other total <<< "$stats"
    active=$(( ready + queued + running + delayed + submitting + submitted + retrying ))

    echo "State: READY=$ready QUEUED=$queued RUNNING=$running DELAYED=$delayed SUBMITTING=$submitting SUBMITTED=$submitted RETRY=$retrying | OK=$succeeded DEAD=$dead OTHER=$other TOTAL=$total"

    if (( dead > 0 )); then
      echo "❌ DEAD tasks detected for $c12. Stopping for debug."
      exit 3
    fi

    echo YONGZUO CCCC active = ${active}

    BACKOFF=${BACKOFF:-$SLEEP_SECS}
    MAX_BACKOFF=${MAX_BACKOFF:-600}  # cap at 10 min
    # after computing $active:
    if (( active > 0 )); then
      # sleep "$BACKOFF"
    # grow backoff a bit while we're still active
       BACKOFF=$(( BACKOFF < MAX_BACKOFF ? BACKOFF + 30 : MAX_BACKOFF ))
   
    date
     echo before SLEEP "$SLEEP_SECS"
     sleep "$SLEEP_SECS"
     echo after SLEEP "$SLEEP_SECS"
    date

    else
       BACKOFF=$SLEEP_SECS  # reset when cycle finishes
    fi

    if (( active == 0 )); then
      echo "This cycle $c12 no longer has active tasks. Go to next cycle"
      break
    fi

  done  ## running inside this cycle

done    ## loop cycles

echo "All requested cycles processed."

