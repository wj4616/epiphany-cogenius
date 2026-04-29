#!/usr/bin/env bash
# validate-pipeline.sh — epiphany-cogenius v1.0.0
# Usage: validate-pipeline.sh
# Dev/CI only. Verifies DAG integrity, activation grammar,
# KB file existence, and output file uniqueness from index.json.
# Exit 0 = all checks pass, Exit 1 = one or more failures.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
INDEX_FILE="${SKILL_DIR}/index.json"
KB_DIR="${SKILL_DIR}/kb"

if [ ! -f "$INDEX_FILE" ]; then
  echo "FAIL: index.json not found at ${INDEX_FILE}"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo "FAIL: python3 required for validate-pipeline.sh"
  exit 1
fi

python3 - "$INDEX_FILE" "$KB_DIR" << 'PYEOF'
import json
import sys
import os
from pathlib import Path

index_path = sys.argv[1]
kb_dir = sys.argv[2]

with open(index_path) as f:
    idx = json.load(f)

VALID_ACTIVATION_TYPES = {"always", "scale:MINIMAL", "scale:STANDARD", "scale:DEEP",
                           "flag:--xml", "flag:--quiet", "flag:--verbose", "flag:--conjecture",
                           "flag:--minimal", "flag:--standard", "flag:--deep",
                           "flag:--no-save", "flag:--resume",
                           "condition:S3_thin_or_empty", "condition:S6_no_alternatives"}

VALID_SIGNALS = {"S3_thin_or_empty", "S6_no_alternatives"}

REQUIRED_TOP_LEVEL_KEYS = {"version", "kb_base", "session_output_base",
                            "mode_shift_after", "stages", "conditional_modules",
                            "output_synthesis_pass", "signals", "scale_auto_detection"}

failures = []
warnings = []

# Check 0: Required top-level keys present
print("=== Check 0: index.json schema ===")
missing_keys = REQUIRED_TOP_LEVEL_KEYS - set(idx.keys())
if missing_keys:
    for k in sorted(missing_keys):
        failures.append(f"FAIL: index.json missing required top-level key '{k}'")
print("  Done.")

stages = idx.get("stages", [])
conditionals = idx.get("conditional_modules", [])
osp = idx.get("output_synthesis_pass", {})
all_entries = stages + conditionals

# Build wave map: stage_id -> wave number (for numeric waves only)
wave_map = {}
for entry in all_entries:
    w = entry.get("wave")
    if isinstance(w, int):
        wave_map[entry["stage_id"]] = w

# Build output file registry for uniqueness check
output_files = {}

# Check 1: Every activation predicate uses valid types
print("=== Check 1: Activation grammar ===")
for entry in all_entries:
    sid = entry.get("stage_id", "?")
    for act in entry.get("activation", []):
        if act not in VALID_ACTIVATION_TYPES and not act.startswith("condition:"):
            failures.append(f"FAIL: {sid} — invalid activation predicate: '{act}'")
        elif act.startswith("condition:"):
            signal = act[len("condition:"):]
            if signal not in VALID_SIGNALS:
                failures.append(f"FAIL: {sid} — unknown signal in activation: '{signal}'")
print("  Done.")

# Check 2: Every kb_sources path exists under kb_base
print("=== Check 2: KB file existence ===")
for entry in all_entries:
    sid = entry.get("stage_id", "?")
    for kb_file in entry.get("kb_sources", []):
        kb_path = os.path.join(kb_dir, kb_file)
        if not os.path.isfile(kb_path):
            failures.append(f"FAIL: {sid} — KB file not found: {kb_path}")
print("  Done.")

# Check 3: Every output_file is distinct
print("=== Check 3: Output file uniqueness ===")
for entry in all_entries:
    sid = entry.get("stage_id", "?")
    outfile = entry.get("output_file", "")
    if outfile in output_files:
        failures.append(f"FAIL: {sid} — output_file '{outfile}' already claimed by {output_files[outfile]}")
    else:
        output_files[outfile] = sid
print("  Done.")

# Check 4: DAG dependency ordering (input_dependencies must come from earlier waves)
print("=== Check 4: DAG wave ordering ===")
# Build stage -> output_file map
output_map = {}
for entry in all_entries:
    output_map[entry.get("output_file", "")] = entry.get("stage_id", "?")

for entry in all_entries:
    sid = entry.get("stage_id", "?")
    entry_wave = entry.get("wave")
    if not isinstance(entry_wave, int):
        continue  # skip conditional modules with "Nb" wave
    for dep in entry.get("input_dependencies", []):
        # Find which stage produces this dependency
        dep_producer = output_map.get(dep)
        if dep_producer and dep_producer in wave_map:
            dep_wave = wave_map[dep_producer]
            if dep_wave >= entry_wave:
                failures.append(
                    f"FAIL: {sid} (wave {entry_wave}) — depends on {dep} from {dep_producer} "
                    f"(wave {dep_wave}), which is NOT earlier"
                )
print("  Done.")

# Check 5: No obvious cycles (simple path check)
print("=== Check 5: Cycle detection ===")
# Build adjacency from output file -> dependent stages
dep_graph = {}
for entry in all_entries:
    sid = entry["stage_id"]
    dep_graph[sid] = set()
    for dep in entry.get("input_dependencies", []):
        producer = output_map.get(dep)
        if producer and producer != sid:
            dep_graph[sid].add(producer)

def has_cycle(graph, node, visited, rec_stack):
    visited.add(node)
    rec_stack.add(node)
    for neighbor in graph.get(node, []):
        if neighbor not in visited:
            if has_cycle(graph, neighbor, visited, rec_stack):
                return True
        elif neighbor in rec_stack:
            return True
    rec_stack.discard(node)
    return False

visited = set()
for node in dep_graph:
    if node not in visited:
        if has_cycle(dep_graph, node, visited, set()):
            failures.append(f"FAIL: cycle detected involving stage {node}")
print("  Done.")

# Check 6: OSP input_dependencies exist as output files of stages
print("=== Check 6: OSP dependency coverage ===")
all_output_files = set(output_files.keys())
ALLOWED_EXTERNAL_DEPS = {"stages/00-processed-input.md", "stages/S7-v6-scope.txt"}
for dep in osp.get("input_dependencies", []):
    # Allow 00-processed-input.md (written by orchestrator) and
    # S7-v6-scope.txt (written by S7 alongside its main output)
    if dep not in all_output_files and dep not in ALLOWED_EXTERNAL_DEPS:
        warnings.append(f"WARN: OSP input_dependency '{dep}' not in any stage output_file")
for dep in osp.get("optional_dependencies", []):
    if dep not in all_output_files and dep not in ALLOWED_EXTERNAL_DEPS:
        warnings.append(f"WARN: OSP optional_dependency '{dep}' not in any stage output_file")
print("  Done.")

# Check 7: xml_element uniqueness (honest XML mode relies on 1:1 mapping)
print("=== Check 7: xml_element uniqueness ===")
xml_elements = {}
for entry in all_entries:
    sid = entry.get("stage_id", "?")
    xe = entry.get("xml_element")
    if xe is None:
        continue
    if xe in xml_elements:
        failures.append(
            f"FAIL: {sid} — xml_element '{xe}' already claimed by {xml_elements[xe]}")
    else:
        xml_elements[xe] = sid
print("  Done.")

# Check 8: raises_signals values must be known signals
print("=== Check 8: raises_signals grammar ===")
for entry in all_entries:
    sid = entry.get("stage_id", "?")
    for sig in entry.get("raises_signals", []):
        if sig not in VALID_SIGNALS:
            failures.append(f"FAIL: {sid} — raises unknown signal '{sig}'")
print("  Done.")

# Check 9: optional_dependencies reference real stage output files
print("=== Check 9: optional_dependencies resolve ===")
for entry in all_entries:
    sid = entry.get("stage_id", "?")
    for dep in entry.get("optional_dependencies", []):
        if dep not in output_files and dep not in ALLOWED_EXTERNAL_DEPS:
            warnings.append(
                f"WARN: {sid} — optional_dependency '{dep}' is not a known stage output")
print("  Done.")

# Check 10: mode_shift_after values reference real stage_ids
print("=== Check 10: mode_shift_after references ===")
all_stage_ids = {e["stage_id"] for e in all_entries}
for scale, after_sid in idx.get("mode_shift_after", {}).items():
    if after_sid not in all_stage_ids:
        failures.append(
            f"FAIL: mode_shift_after[{scale}] references unknown stage_id '{after_sid}'")
print("  Done.")

# Check 11: signals map references
print("=== Check 11: signals map ===")
for sig_name, sig_info in idx.get("signals", {}).items():
    if sig_name not in VALID_SIGNALS:
        failures.append(f"FAIL: signals map contains unknown signal '{sig_name}'")
    rb = sig_info.get("raised_by")
    if rb and rb not in all_stage_ids:
        failures.append(
            f"FAIL: signal '{sig_name}'.raised_by='{rb}' is not a known stage_id")
    for act in sig_info.get("activates", []):
        if act not in all_stage_ids:
            failures.append(
                f"FAIL: signal '{sig_name}'.activates contains unknown stage_id '{act}'")
print("  Done.")

# Report
print()
print("=" * 50)
if failures:
    for f in failures:
        print(f)
if warnings:
    for w in warnings:
        print(w)

total = len(failures)
if total == 0:
    print(f"PASS: all pipeline validation checks passed (12 checks)")
    sys.exit(0)
else:
    print(f"FAIL: {total} check(s) failed")
    sys.exit(1)
PYEOF
