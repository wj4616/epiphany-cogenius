#!/usr/bin/env bash
# test-resolve-hat.sh — Smoke tests for resolve-hat.sh
#
# Tests 1-2: Claude default resolution and shorthand aliases (always run, no external deps).
# Tests 3-5: Require ollama. Set SKIP_OLLAMA_TESTS=1 to skip.
# Test 6: Ollama model absent — requires ollama service running but model not pulled.
#
# Usage:
#   bash test-resolve-hat.sh
#   SKIP_OLLAMA_TESTS=1 bash test-resolve-hat.sh   # skip all ollama tests
#
# Exit 0: all active tests passed. Exit 1: one or more tests failed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVE="$SCRIPT_DIR/resolve-hat.sh"

PASS=0
FAIL=0
SKIP=0

# ---- Helpers ----

assert_stdout_exit() {
  local desc="$1"
  local expected_stdout="$2"
  local expected_exit="$3"
  shift 3

  local tmpstderr
  tmpstderr="$(mktemp)"
  local actual_stdout actual_exit
  actual_stdout="$(bash "$@" 2>"$tmpstderr")" && actual_exit=0 || actual_exit=$?
  rm -f "$tmpstderr"

  if [[ "$actual_exit" -eq "$expected_exit" && "$actual_stdout" == "$expected_stdout" ]]; then
    echo "PASS: $desc"
    ((PASS++))
  else
    echo "FAIL: $desc"
    echo "  expected exit=$expected_exit stdout='$expected_stdout'"
    echo "  actual   exit=$actual_exit stdout='$actual_stdout'"
    ((FAIL++))
  fi
}

assert_stderr_contains_exit() {
  local desc="$1"
  local needle="$2"
  local expected_exit="$3"
  shift 3

  local tmpstderr
  tmpstderr="$(mktemp)"
  local actual_stdout actual_exit stderr_content
  actual_stdout="$(bash "$@" 2>"$tmpstderr")" && actual_exit=0 || actual_exit=$?
  stderr_content="$(cat "$tmpstderr")"
  rm -f "$tmpstderr"

  if [[ "$actual_exit" -eq "$expected_exit" ]] && echo "$stderr_content" | grep -qF "$needle"; then
    echo "PASS: $desc"
    ((PASS++))
  else
    echo "FAIL: $desc"
    echo "  expected exit=$expected_exit, stderr contains '$needle'"
    echo "  actual exit=$actual_exit, stderr='$stderr_content'"
    ((FAIL++))
  fi
}

skip_test() {
  echo "SKIP: $1"
  ((SKIP++))
}

echo "=== resolve-hat.sh smoke tests ==="
echo ""

# ---- Test 1: Default resolution ----
# Adversary hat with no flags resolves to claude-opus-4-7 (large-tier default).
assert_stdout_exit \
  "Test 1 — Default resolution: Adversary → claude-opus-4-7" \
  "claude-opus-4-7" \
  0 \
  "$RESOLVE" Adversary

# ---- Test 2: Shorthand aliases ----
# Shorthand inputs expand to full Claude model IDs before provider detection.
assert_stdout_exit \
  "Test 2a — Shorthand: Synthesizer --model-medium haiku → claude-haiku-4-5-20251001" \
  "claude-haiku-4-5-20251001" \
  0 \
  "$RESOLVE" Synthesizer --model-medium haiku

assert_stdout_exit \
  "Test 2b — Shorthand: Precision --model-medium sonnet → claude-sonnet-4-6" \
  "claude-sonnet-4-6" \
  0 \
  "$RESOLVE" Precision --model-medium sonnet

assert_stdout_exit \
  "Test 2c — Shorthand: Adversary --model-large sonnet → claude-sonnet-4-6 (large tier overridden via shorthand)" \
  "claude-sonnet-4-6" \
  0 \
  "$RESOLVE" Adversary --model-large sonnet

assert_stdout_exit \
  "Test 2d — Shorthand case-insensitive: Explorer --model-medium Haiku → claude-haiku-4-5-20251001" \
  "claude-haiku-4-5-20251001" \
  0 \
  "$RESOLVE" Explorer --model-medium Haiku

# ---- Test 3: Claude full model ID override ----
assert_stdout_exit \
  "Test 3 — Full model ID: Simulator --model-medium claude-sonnet-4-6 → claude-sonnet-4-6" \
  "claude-sonnet-4-6" \
  0 \
  "$RESOLVE" Simulator --model-medium claude-sonnet-4-6

# ---- Test 4: Last-flag-wins ----
# --model-small appears twice; last value wins.
assert_stdout_exit \
  "Test 4 — Last-flag-wins: --model-small haiku --model-small sonnet → claude-sonnet-4-6" \
  "claude-sonnet-4-6" \
  0 \
  "$RESOLVE" Synthesizer --model-small haiku --model-small sonnet

# ---- Test 5: Adversary null escalation advisory ----
# --escalate on Adversary (null escalation_tier) emits advisory to stderr, exits 0, stdout empty.
assert_stderr_contains_exit \
  "Test 5 — Null escalation advisory: Adversary --escalate emits advisory, exits 0" \
  "Escalation not available" \
  0 \
  "$RESOLVE" Adversary --escalate

# ---- Ollama-dependent tests ----
if [[ "${SKIP_OLLAMA_TESTS:-0}" == "1" ]]; then
  skip_test "Test 6 — Flag override with ollama model (SKIP_OLLAMA_TESTS=1)"
  skip_test "Test 7 — Ollama model absent (SKIP_OLLAMA_TESTS=1)"
else
  # ---- Test 6: Flag override with ollama model ----
  # Requires ollama running with qwen3.5:27b pulled.
  # To mock: temporarily rename the ollama binary and replace with a stub that echoes the model.
  assert_stdout_exit \
    "Test 6 — Flag override: Adversary --model-large qwen3.5:27b → qwen3.5:27b (requires ollama)" \
    "qwen3.5:27b" \
    0 \
    "$RESOLVE" Adversary --model-large qwen3.5:27b

  # ---- Test 7: Ollama model absent ----
  # Requires ollama service running but nonexistent:model not pulled.
  assert_stderr_contains_exit \
    "Test 7 — Ollama model absent: Explorer --model-small nonexistent:model → stderr 'not found in ollama'" \
    "not found in ollama" \
    1 \
    "$RESOLVE" Explorer --model-small nonexistent:model
fi

# ---- Test 8: Ambiguous bare word on the hat's own tier ----
# Synthesizer uses model-medium, so --model-medium mistral triggers ambiguous detection.
assert_stderr_contains_exit \
  "Test 8 — Ambiguous bare word: --model-medium mistral → stderr 'ambiguous'" \
  "ambiguous" \
  1 \
  "$RESOLVE" Synthesizer --model-medium mistral

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
