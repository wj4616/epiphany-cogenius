#!/usr/bin/env bash
# confidence-gate.sh — epiphany-cogenius v1.0.0
# Usage: confidence-gate.sh <session_dir> <stage_id> <hat_name> \
#          [--model-large <val>] [--model-medium <val>] [--model-small <val>]
#
# Evaluates the confidence fraction for a completed stage and returns the routing decision.
#
# Algorithm:
#   1. Read required_output_sections for stage_id from index.json
#   2. Read confidence_threshold for hat_name from hats.json
#   3. For each required section: check it appears as a heading in the output file
#      AND has at least one non-whitespace line following it
#   4. fraction = present_count / total_required_sections
#   5. If fraction >= threshold → PASS
#      Else → call resolve-hat.sh --escalate to get escalation model
#      If escalation model available → ESCALATE with that model
#      If no escalation (null tier) → ADVISORY
#
# Stdout (one line):
#   PASS <fraction>                   — gate passed, no action needed
#   ESCALATE <fraction> <model>       — re-run stage with <model>
#   ADVISORY <fraction>               — below threshold, no escalation available; accept output
#
# Exit 0: always (decision communicated via stdout).
# Exit 1: configuration error (script halts with message to stderr).

set -euo pipefail

SESSION_DIR="${1:?Usage: confidence-gate.sh <session_dir> <stage_id> <hat_name> [--model-large v] [--model-medium v] [--model-small v]}"
STAGE_ID="${2:?}"
HAT_NAME="${3:?}"
shift 3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
INDEX_FILE="${SKILL_DIR}/index.json"
HATS_JSON="${SKILL_DIR}/hats.json"
STAGES_DIR="${SESSION_DIR}/stages"

# Collect tier flags to forward to resolve-hat.sh
TIER_FLAGS=("$@")

# ---- Sanity checks ----
[[ ! -f "$INDEX_FILE" ]] && { echo "[HALT] confidence-gate.sh: index.json not found at $INDEX_FILE" >&2; exit 1; }
[[ ! -f "$HATS_JSON" ]]  && { echo "[HALT] confidence-gate.sh: hats.json not found at $HATS_JSON" >&2; exit 1; }
command -v python3 &>/dev/null || { echo "[HALT] confidence-gate.sh: python3 required" >&2; exit 1; }

# ---- Read stage info and hat threshold in one python3 call ----
gate_info=$(INDEX_PATH="$INDEX_FILE" HATS_PATH="$HATS_JSON" python3 - "$STAGE_ID" "$HAT_NAME" "$STAGES_DIR" << 'PYEOF'
import json, os, re, sys
from pathlib import Path

stage_id   = sys.argv[1]
hat_name   = sys.argv[2]
stages_dir = Path(sys.argv[3])

with open(os.environ['INDEX_PATH']) as f:
    idx = json.load(f)
with open(os.environ['HATS_PATH']) as f:
    hats = json.load(f)

# --- Resolve stage entry ---
all_entries = idx.get("stages", []) + idx.get("conditional_modules", [])

if stage_id.lower() == "osp":
    osp = idx.get("output_synthesis_pass", {})
    output_file = osp.get("output_file", "stages/output-distilled.md")
    required_sections = osp.get("required_output_sections", [])
else:
    entry = next((e for e in all_entries if e.get("stage_id") == stage_id), None)
    if entry is None:
        print(f"ERROR=Stage {stage_id} not found in index.json")
        sys.exit(1)
    output_file = entry.get("output_file", "")
    required_sections = entry.get("required_output_sections", [])

# --- Resolve hat threshold ---
hat = next((h for h in hats if h["hat_name"] == hat_name), None)
if hat is None:
    print(f"ERROR=Hat {hat_name} not found in hats.json")
    sys.exit(1)

threshold = hat.get("confidence_threshold", 0.80)

# --- Read output file ---
# output_file is relative to session root (e.g., "stages/S1-state-loading.md")
abs_output = Path(stages_dir).parent / output_file
if not abs_output.exists():
    print(f"ERROR=Output file not found: {abs_output}")
    sys.exit(1)

content = abs_output.read_text()

# --- Count sections present and non-empty ---
# A section is "present" if its string appears as a heading at any # level
# AND at least one non-whitespace line follows it before the next heading or EOF.
total = len(required_sections)
if total == 0:
    # No sections required — gate passes trivially
    print(f"FRACTION=1.0")
    print(f"THRESHOLD={threshold}")
    print(f"PRESENT={0}")
    print(f"TOTAL={0}")
    sys.exit(0)

present = 0
for section in required_sections:
    # Match section as a markdown heading at any level (1-6 #)
    # Escaped for regex; case-insensitive
    pattern = r'^#{1,6}\s+' + re.escape(section) + r'\s*$'
    match = re.search(pattern, content, re.MULTILINE | re.IGNORECASE)
    if not match:
        # Narrower fallback: accept bold label at start of line (**Section** or *Section*)
        # optionally followed by colon, with non-whitespace content within 500 chars.
        # Avoids false positives from the section name appearing anywhere as prose.
        label_pattern = r'^\*{1,2}' + re.escape(section) + r'\*{1,2}\s*:?\s*'
        label_match = re.search(label_pattern, content, re.MULTILINE | re.IGNORECASE)
        if label_match:
            remainder = content[label_match.end():]
            if re.search(r'\S', remainder[:500]):
                present += 1
        # Section genuinely absent
        continue
    else:
        # Heading found — check for non-whitespace content following it
        end_of_heading = match.end()
        # Find the next heading or EOF
        next_heading = re.search(r'^#{1,6}\s', content[end_of_heading:], re.MULTILINE)
        if next_heading:
            section_body = content[end_of_heading : end_of_heading + next_heading.start()]
        else:
            section_body = content[end_of_heading:]
        if re.search(r'\S', section_body):
            present += 1

fraction = present / total

print(f"FRACTION={fraction:.4f}")
print(f"THRESHOLD={threshold}")
print(f"PRESENT={present}")
print(f"TOTAL={total}")
PYEOF
) || {
  err=$(echo "$gate_info" | grep '^ERROR=' | cut -d= -f2- || true)
  echo "[HALT] confidence-gate.sh: $err" >&2
  exit 1
}

# ---- Parse python output ----
if echo "$gate_info" | grep -q "^ERROR="; then
  err=$(echo "$gate_info" | grep '^ERROR=' | cut -d= -f2-)
  echo "[HALT] confidence-gate.sh: $err" >&2
  exit 1
fi

FRACTION=$(echo "$gate_info" | grep '^FRACTION=' | cut -d= -f2-)
THRESHOLD=$(echo "$gate_info" | grep '^THRESHOLD=' | cut -d= -f2-)

# ---- Compare fraction to threshold using python3 ----
passes=$(python3 -c "import sys; sys.exit(0 if float('$FRACTION') >= float('$THRESHOLD') else 1)") && GATE_RESULT=pass || GATE_RESULT=fail

if [[ "$GATE_RESULT" == "pass" ]]; then
  echo "PASS $FRACTION"
  exit 0
fi

# ---- Gate failed: attempt escalation ----
RESOLVE="${SCRIPT_DIR}/resolve-hat.sh"
[[ ! -f "$RESOLVE" ]] && { echo "[HALT] confidence-gate.sh: resolve-hat.sh not found at $RESOLVE" >&2; exit 1; }

# Forward tier flags to resolve-hat.sh
escalation_model=$(bash "$RESOLVE" "$HAT_NAME" --escalate "${TIER_FLAGS[@]+"${TIER_FLAGS[@]}"}" 2>/dev/null) || {
  esc_exit=$?
  # resolve-hat.sh already emitted HALT to stderr
  exit "$esc_exit"
}

if [[ -n "$escalation_model" ]]; then
  echo "ESCALATE $FRACTION $escalation_model"
else
  # Null escalation — advisory only
  echo "ADVISORY $FRACTION"
fi
exit 0
