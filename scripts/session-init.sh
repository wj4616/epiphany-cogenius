#!/usr/bin/env bash
# session-init.sh — epiphany-cogenius v1.0.0
# Usage: session-init.sh <session_dir>
# Creates session directory and writes stages/session.md.
# Prints the resolved directory path (stdout line 1) for orchestrator capture.
# Called by orchestrator STEP 2. Mirrors genius session-init.sh with cogenius additions.

set -euo pipefail

RAW_SESSION_DIR="${1:?Usage: session-init.sh <session_dir>}"
SESSION_DIR="${RAW_SESSION_DIR%/}"

# Collision safety: if dir exists, append -N suffix
if [ -d "$SESSION_DIR" ]; then
  N=1
  while [ -d "${SESSION_DIR}-${N}" ]; do
    N=$((N+1))
  done
  SESSION_DIR="${SESSION_DIR}-${N}"
fi

SESSION_ID="$(basename "$SESSION_DIR")"
STAGES_DIR="${SESSION_DIR}/stages"

mkdir -p "${STAGES_DIR}"

TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')
START_EPOCH=$(date +%s)

cat > "${STAGES_DIR}/session.md" << EOF
# epiphany-cogenius Session Manifest

session_id: ${SESSION_ID}
timestamp: ${TIMESTAMP}
start_epoch: ${START_EPOCH}
skill_version: 1.0.0

## State (updated by orchestrator)
scale: TBD
input_type: TBD
depth_flag: TBD
flag_xml: false
flag_quiet: false
flag_verbose: false
flag_conjecture: false
flag_no_save: false
flag_resume: false
wave_plan: TBD
active_conditionals: []
stage_list: []
signals: []

## Hat routing (populated by orchestrator after STEP 0 flag detection)
tier_large: TBD
tier_medium: TBD
tier_small: TBD

## Cost observability (populated at end of run)
spawns_total: 0
wall_seconds: 0
retry_path_taken: none

## Output paths
session_dir: ${SESSION_DIR}/
stages_dir: ${STAGES_DIR}/
EOF

# Line 1 = resolved dir (with trailing slash) so orchestrator can use it
# directly as {session_dir} prefix without an explicit separator
echo "${SESSION_DIR}/"
echo "Session initialized: ${SESSION_DIR}"
echo "Stages directory: ${STAGES_DIR}"
