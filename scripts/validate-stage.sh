#!/usr/bin/env bash
# validate-stage.sh — epiphany-cogenius v1.0.0
# Usage: validate-stage.sh <session_dir> <stage_id>
# Checks: output file exists + non-empty (FAIL/exit-1) + required sections advisory (WARN/exit-0).
# Section presence issues emit WARN only — the confidence-gate.sh script handles the
# fractional threshold check and escalation decision. This script only hard-fails on
# missing or empty output files.
# Called by orchestrator after each stage completes (STEP 5, STEP 7).
# Exit 0 = PASS or WARN-only. Exit 1 = FAIL (orchestrator will HALT).

set -euo pipefail

SESSION_DIR="${1:?Usage: validate-stage.sh <session_dir> <stage_id>}"
STAGE_ID="${2:?Usage: validate-stage.sh <session_dir> <stage_id>}"
STAGES_DIR="${SESSION_DIR}/stages"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
INDEX_FILE="${SKILL_DIR}/index.json"

FAIL=0
LOG_FILE="${STAGES_DIR}/validation-log.md"
TIMESTAMP=$(date '+%H:%M:%S')

# Resolve output file and required sections from cogenius index.json
if ! command -v python3 &>/dev/null; then
  echo "[WARN] validate-stage.sh: python3 not found — skipping section checks"
  OUTPUT_FILE=""
  REQUIRED_SECTIONS=""
else
  STAGE_INFO=$(python3 - "$STAGE_ID" "$INDEX_FILE" << 'PYEOF'
import json, sys
stage_id = sys.argv[1]
index_path = sys.argv[2]

with open(index_path) as f:
    idx = json.load(f)

entries = idx.get("stages", []) + idx.get("conditional_modules", [])

if stage_id.lower() == "osp":
    osp = idx.get("output_synthesis_pass", {})
    output_file = osp.get("output_file", "stages/output-distilled.md")
    required_sections = osp.get("required_output_sections", [])
    print(f"OUTPUT_FILE={output_file}")
    print(f"REQUIRED_SECTIONS={chr(0x1f).join(required_sections)}")
    sys.exit(0)

for entry in entries:
    if entry.get("stage_id") == stage_id:
        output_file = entry.get("output_file", "")
        required_sections = entry.get("required_output_sections", [])
        print(f"OUTPUT_FILE={output_file}")
        print(f"REQUIRED_SECTIONS={chr(0x1f).join(required_sections)}")
        sys.exit(0)

print(f"ERROR=Stage {stage_id} not found in index.json")
sys.exit(1)
PYEOF
  )

  if echo "$STAGE_INFO" | grep -q "^ERROR="; then
    echo "[WARN] validate-stage.sh: $(echo "$STAGE_INFO" | grep '^ERROR=' | cut -d= -f2-)"
    exit 0
  fi

  OUTPUT_FILE=$(echo "$STAGE_INFO" | grep '^OUTPUT_FILE=' | cut -d= -f2-)
  REQUIRED_SECTIONS_RAW=$(echo "$STAGE_INFO" | grep '^REQUIRED_SECTIONS=' | cut -d= -f2-)
fi

# Resolve absolute path
if [ -n "$OUTPUT_FILE" ]; then
  ABS_OUTPUT="${SESSION_DIR}/${OUTPUT_FILE}"
else
  STAGE_LC=$(printf '%s' "$STAGE_ID" | tr '[:upper:]' '[:lower:]')
  ABS_OUTPUT=$(ls "${STAGES_DIR}/${STAGE_LC}"*.md 2>/dev/null | head -1 || true)
fi

# Check 1 (FAIL): Output file exists
if [ ! -f "$ABS_OUTPUT" ]; then
  echo "FAIL: ${STAGE_ID} — output file not found: ${ABS_OUTPUT}"
  FAIL=1
else
  # Check 2 (FAIL): Output file is non-empty
  if [ ! -s "$ABS_OUTPUT" ]; then
    echo "FAIL: ${STAGE_ID} — output file exists but is empty: ${ABS_OUTPUT}"
    FAIL=1
  else
    echo "PASS: ${STAGE_ID} — output file present and non-empty"

    # Check 3 (WARN only): Required sections present
    # Sections with missing content are reported as WARNs, not FAILs.
    # The confidence-gate.sh script applies the fractional threshold check.
    if [ -n "$REQUIRED_SECTIONS_RAW" ] && command -v python3 &>/dev/null; then
      python3 - "$ABS_OUTPUT" "$REQUIRED_SECTIONS_RAW" "$STAGE_ID" << 'PYEOF'
import sys

output_file = sys.argv[1]
sections_raw = sys.argv[2]
stage_id = sys.argv[3]

required = [s for s in sections_raw.split('\x1f') if s]

with open(output_file) as f:
    content = f.read()

missing = []
for section in required:
    if section not in content:
        missing.append(section)

if missing:
    for m in missing:
        print(f"WARN: {stage_id} — section absent (confidence-gate will evaluate): '{m}'")
    # Exit 0: sections are advisory here; confidence-gate.sh handles the threshold decision
    sys.exit(0)
else:
    print(f"PASS: {stage_id} — all {len(required)} required sections present")
    sys.exit(0)
PYEOF
    fi
  fi
fi

# S7 special case: also verify S7-v6-scope.txt was written
if [ "${STAGE_ID}" = "S7" ] && [ $FAIL -eq 0 ]; then
  V6_SCOPE="${STAGES_DIR}/S7-v6-scope.txt"
  if [ ! -f "$V6_SCOPE" ]; then
    echo "FAIL: S7 — S7-v6-scope.txt not found (required for OSP V6 verbatim carve-out and T3)"
    FAIL=1
  elif [ ! -s "$V6_SCOPE" ]; then
    echo "FAIL: S7 — S7-v6-scope.txt exists but is empty"
    FAIL=1
  else
    echo "PASS: S7 — S7-v6-scope.txt present and non-empty"
  fi
fi

if [ $FAIL -ne 0 ]; then
  echo "- FAIL  ${STAGE_ID}  ${TIMESTAMP}" >> "${LOG_FILE}"
  exit 1
fi
echo "- PASS  ${STAGE_ID}  ${TIMESTAMP}" >> "${LOG_FILE}"
exit 0
