#!/usr/bin/env bash
# resolve-hat.sh — Resolve model string for a given hat name with optional tier overrides.
#
# Usage:
#   resolve-hat.sh <hat_name> [--model-large <val>] [--model-medium <val>] [--model-small <val>] [--escalate]
#
# Outputs:
#   stdout: single model string (empty if --escalate called on a null escalation_tier hat)
#   stderr: HALT messages (fatal) or ADVISORY messages (informational)
#
# Exit codes:
#   0  — success (model emitted to stdout, or advisory emitted and no escalation available)
#   1  — HALT (model unavailable, service not running, ambiguous value, hat not found)
#
# Shorthand aliases (case-insensitive):
#   opus   → claude-opus-4-7
#   sonnet → claude-sonnet-4-6
#   haiku  → claude-haiku-4-5-20251001
#
# Provider detection (applied after shorthand expansion):
#   Starts with "claude-"        → Claude API  (takes precedence even if ":" present)
#   Contains ":" (not claude-)   → ollama
#   Bare word, no ":", no prefix → ambiguous → HALT

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
HATS_JSON="$SKILL_DIR/hats.json"

DEFAULT_LARGE="claude-opus-4-7"
DEFAULT_MEDIUM="claude-sonnet-4-6"
DEFAULT_SMALL="claude-haiku-4-5-20251001"

# ---- Shorthand expansion ----
# Case-insensitive. Non-shorthand values pass through unchanged.
expand_shorthand() {
  case "${1,,}" in
    opus)   echo "claude-opus-4-7" ;;
    sonnet) echo "claude-sonnet-4-6" ;;
    haiku)  echo "claude-haiku-4-5-20251001" ;;
    *)      echo "$1" ;;
  esac
}

# ---- Tier-to-model resolver ----
# Maps tier name (model-large/medium/small) to the effective model string.
resolve_tier_model() {
  case "$1" in
    model-large)  echo "$LARGE";  return 0 ;;
    model-medium) echo "$MEDIUM"; return 0 ;;
    model-small)  echo "$SMALL";  return 0 ;;
    *)
      echo "[HALT] resolve-hat.sh: unknown tier '$1' in hats.json." >&2
      return 1 ;;
  esac
}

# ---- Provider detection ----
# Returns: claude | ollama | ambiguous
detect_provider() {
  local model="$1"
  if [[ "$model" == claude-* ]]; then
    echo "claude"
  elif [[ "$model" == *:* ]]; then
    echo "ollama"
  else
    echo "ambiguous"
  fi
}

# ---- Ollama availability check ----
# Checks service is reachable, then checks the model exists in the local registry.
check_ollama_model() {
  local model="$1"
  if ! ollama list >/dev/null 2>&1; then
    echo "[HALT] ollama service is not running. Start it with: ollama serve" >&2
    return 1
  fi
  if ! ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -qxF "$model"; then
    echo "[HALT] Model $model not found in ollama. Run: ollama pull $model" >&2
    return 1
  fi
}

# ---- Argument parsing (last-flag-wins per tier) ----
if [[ $# -lt 1 ]]; then
  echo "[HALT] resolve-hat.sh: hat_name is required as the first argument." >&2
  exit 1
fi

HAT_NAME="$1"; shift
FLAG_LARGE=""
FLAG_MEDIUM=""
FLAG_SMALL=""
ESCALATE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model-large)
      [[ $# -lt 2 ]] && { echo "[HALT] --model-large requires a value." >&2; exit 1; }
      FLAG_LARGE="$(expand_shorthand "$2")"; shift 2 ;;
    --model-medium)
      [[ $# -lt 2 ]] && { echo "[HALT] --model-medium requires a value." >&2; exit 1; }
      FLAG_MEDIUM="$(expand_shorthand "$2")"; shift 2 ;;
    --model-small)
      [[ $# -lt 2 ]] && { echo "[HALT] --model-small requires a value." >&2; exit 1; }
      FLAG_SMALL="$(expand_shorthand "$2")"; shift 2 ;;
    --escalate)
      ESCALATE=true; shift ;;
    *)
      echo "[HALT] resolve-hat.sh: unrecognized argument '$1'." >&2; exit 1 ;;
  esac
done

# Effective tier values: explicit flag overrides > global defaults
LARGE="${FLAG_LARGE:-$DEFAULT_LARGE}"
MEDIUM="${FLAG_MEDIUM:-$DEFAULT_MEDIUM}"
SMALL="${FLAG_SMALL:-$DEFAULT_SMALL}"

# ---- Hat lookup ----
if [[ ! -f "$HATS_JSON" ]]; then
  echo "[HALT] resolve-hat.sh: hats.json not found at $HATS_JSON" >&2
  exit 1
fi

hat_info=$(HATS_JSON_PATH="$HATS_JSON" python3 -c "
import json, sys, os
with open(os.environ['HATS_JSON_PATH']) as f:
    hats = json.load(f)
hat = next((h for h in hats if h['hat_name'] == sys.argv[1]), None)
if hat is None:
    sys.exit(1)
esc = hat['escalation_tier'] if hat['escalation_tier'] is not None else 'null'
print(hat['default_tier'])
print(esc)
" "$HAT_NAME" 2>/dev/null) || {
  echo "[HALT] resolve-hat.sh: hat '$HAT_NAME' not found in hats.json." >&2
  exit 1
}

hat_default_tier="$(printf '%s\n' "$hat_info" | sed -n '1p')"
hat_escalation_tier="$(printf '%s\n' "$hat_info" | sed -n '2p')"

# ---- Route: escalate vs. normal ----
if $ESCALATE; then
  # Escalation path: return the escalation model, or advisory if null
  if [[ "$hat_escalation_tier" == "null" ]]; then
    echo "[ADVISORY] Hat '$HAT_NAME' is at max model tier. Escalation not available." >&2
    # Exit 0 with empty stdout; orchestrator interprets empty stdout as no escalation available
    exit 0
  fi
  RESOLVED_MODEL="$(resolve_tier_model "$hat_escalation_tier")" || exit 1
else
  # Normal resolution: return the default-tier model
  RESOLVED_MODEL="$(resolve_tier_model "$hat_default_tier")" || exit 1
fi

# ---- Provider detection and availability check ----
PROVIDER="$(detect_provider "$RESOLVED_MODEL")"

case "$PROVIDER" in
  ambiguous)
    echo "[HALT] Flag value '$RESOLVED_MODEL' is ambiguous. Prefix with 'claude-' for Claude routing or use 'name:tag' format for ollama routing." >&2
    exit 1 ;;
  ollama)
    check_ollama_model "$RESOLVED_MODEL" || exit 1 ;;
  claude)
    # Claude API: no local availability check needed
    ;;
esac

# ---- Emit resolved model ----
echo "$RESOLVED_MODEL"
