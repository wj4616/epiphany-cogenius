#!/usr/bin/env bash
# test-runner.sh — epiphany-cogenius v1.0.0
# Usage: test-runner.sh <session_dir> <scale> <active_conditionals_csv> <output_mode>
# Runs T1–T6 checks. Writes stages/test-report.md.
# Called by orchestrator STEP 9.
# T1: Every stage in stage_list has non-empty output file.
# T2: Every stage NOT in stage_list has canonical empty-section marker in distilled output.
# T3: S7-v6-scope.txt content appears byte-for-byte in distilled Section 8.
# T4: Structural completeness — minimum depth per section (sourced from complete stages).
# T5: If --xml: all top-level schema elements present (including <hat_routing>).
# T6: manifest.json validity — exists, valid JSON, required fields, stage array populated.

set -euo pipefail

SESSION_DIR="${1:?Usage: test-runner.sh <session_dir> <scale> <active_conditionals_csv> <output_mode>}"
SCALE="${2:-STANDARD}"
ACTIVE_CONDITIONALS="${3:-none}"
OUTPUT_MODE="${4:-distilled}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
INDEX_FILE="${SKILL_DIR}/index.json"
HATS_JSON="${SKILL_DIR}/hats.json"
STAGES_DIR="${SESSION_DIR}/stages"
MANIFEST_JSON="${SESSION_DIR}/manifest.json"

if ! command -v python3 &>/dev/null; then
  echo "WARN: python3 not found — test-runner.sh skipped"
  exit 0
fi

python3 - "$STAGES_DIR" "$SCALE" "$ACTIVE_CONDITIONALS" "$OUTPUT_MODE" \
         "$SESSION_DIR" "$INDEX_FILE" "$HATS_JSON" "$MANIFEST_JSON" << 'PYEOF'
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

stages_dir            = Path(sys.argv[1])
scale                 = sys.argv[2].upper()
active_conditionals_raw = sys.argv[3]
output_mode           = sys.argv[4]
session_dir           = sys.argv[5]
index_path            = sys.argv[6]
hats_path             = sys.argv[7]
manifest_path         = sys.argv[8]

active_conditionals = [c.strip() for c in active_conditionals_raw.split(",")
                       if c.strip() and c.strip() != "none"]

with open(index_path) as f:
    idx = json.load(f)
with open(hats_path) as f:
    hats = json.load(f)
hat_names = {h["hat_name"] for h in hats}


def read_file(path):
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        return ""


all_entries     = idx.get("stages", []) + idx.get("conditional_modules", [])
STAGE_FILE_MAP  = {}
STAGE_XML_ELEMENT = {}
STAGE_HAT_MAP   = {}
for entry in all_entries:
    sid = entry.get("stage_id", "?")
    out = entry.get("output_file", "")
    if out:
        STAGE_FILE_MAP[sid] = Path(out).name
    STAGE_XML_ELEMENT[sid] = entry.get("xml_element")
    STAGE_HAT_MAP[sid]     = entry.get("hat", "")

ALL_CORE_STAGES  = [e["stage_id"] for e in idx.get("stages", [])]
ALL_CONDITIONALS = [e["stage_id"] for e in idx.get("conditional_modules", [])]

STAGE_LIST_MAP = {
    "MINIMAL":    [sid for sid in ALL_CORE_STAGES
                   if "MINIMAL" in next((e.get("scale_gates", [])
                                         for e in idx["stages"]
                                         if e["stage_id"] == sid), [])],
    "STANDARD":   [sid for sid in ALL_CORE_STAGES
                   if "STANDARD" in next((e.get("scale_gates", [])
                                          for e in idx["stages"]
                                          if e["stage_id"] == sid), [])],
    "DEEP":       [sid for sid in ALL_CORE_STAGES
                   if "DEEP" in next((e.get("scale_gates", [])
                                      for e in idx["stages"]
                                      if e["stage_id"] == sid), [])],
    "CONJECTURE": ["S1", "S6.1", "S7"],
}

stage_list = list(STAGE_LIST_MAP.get(scale, STAGE_LIST_MAP["STANDARD"]))
for cond in active_conditionals:
    if cond not in stage_list:
        stage_list.append(cond)

all_possible   = ALL_CORE_STAGES + ALL_CONDITIONALS
stages_not_run = [s for s in all_possible if s not in stage_list]

T4_MINIMUMS = {
    "Headline Insight":           r".{100,}",
    "Scope Limits":               r"\*\*Applies to:\*\*.*\*\*Does not extend to:\*\*.*\*\*Claims refused:\*\*",
    "Open Questions & Next Probes": r"(?:probe|question|priority).{20,}",
    "Theory Collisions":          r"(?:collision|conflict|contradiction|discriminat).{30,}",
    "Alternative Hypotheses":     r"H-[A-Z0-9]+.{20,}",
    "Coherence Signals":          r"(?:PASS|FAIL|coherent|incoherent|contradiction|signal).{20,}",
}

results   = []
advisories = []
failures  = []

session_md = read_file(stages_dir / "session.md")
session_id_m = re.search(r"session_id:\s*(\S+)", session_md)
session_id = session_id_m.group(1) if session_id_m else "unknown"

# ========================
# T1: Every stage in stage_list has non-empty output file
# ========================
t1_pass = True
t1_details = []
for stage in stage_list:
    if stage == "OSP":
        continue
    filename = STAGE_FILE_MAP.get(stage)
    if not filename:
        continue
    filepath = stages_dir / filename
    if not filepath.exists():
        t1_pass = False
        t1_details.append(f"FAIL T1: {stage} output missing: {filename}")
        failures.append(f"FAIL T1: {stage} output missing or empty")
    elif filepath.stat().st_size == 0:
        t1_pass = False
        t1_details.append(f"FAIL T1: {stage} output empty: {filename}")
        failures.append(f"FAIL T1: {stage} output missing or empty")

if t1_pass:
    results.append("PASS T1: All active stage output files present and non-empty")
else:
    results.extend(t1_details)

# ========================
# T2: Skipped stages have empty markers in distilled output
# ========================
t2_pass = True
if output_mode == "distilled":
    distilled_path = stages_dir / "output-distilled.md"
    distilled_content = read_file(distilled_path)
    if not distilled_content:
        t2_pass = False
        failures.append("FAIL T2: output-distilled.md missing")
    else:
        for stage in stages_not_run:
            stage_ref = stage.replace(".", r"\.")
            stage_specific_patterns = [
                rf"\*\(Stage {stage_ref} skipped at \w+ scale",
                rf"\*\(Stage {stage_ref} ran, no content found",
                rf"\*\(Stage {stage_ref} not reached",
                rf"\*\(Stage {stage_ref} not activated",
                rf"{stage_ref}.*(?:skipped|not activated|not reached)",
            ]
            found_marker = any(
                re.search(p, distilled_content, re.IGNORECASE)
                for p in stage_specific_patterns
            )
            if not found_marker:
                advisories.append(
                    f"ADVISORY T2: {stage} — no canonical empty marker in distilled output")

if t2_pass and output_mode == "distilled":
    results.append("PASS T2: Skipped-stage markers present in distilled output")
elif output_mode != "distilled":
    results.append("PASS T2: N/A (XML mode)")

# ========================
# T3: V6 scope in distilled Section 8 or XML <v6_scope>
# ========================
t3_pass = True
v6_scope_content = read_file(stages_dir / "S7-v6-scope.txt")

if output_mode == "distilled":
    distilled_content = read_file(stages_dir / "output-distilled.md")
    if not v6_scope_content:
        t3_pass = False
        failures.append("FAIL T3: S7-v6-scope.txt not found")
    elif not distilled_content:
        t3_pass = False
        failures.append("FAIL T3: output-distilled.md not found")
    elif v6_scope_content.strip() not in distilled_content:
        t3_pass = False
        failures.append("FAIL T3: V6 scope mismatch — content not found verbatim in distilled Section 8")
    else:
        results.append("PASS T3: V6 scope content matches verbatim in distilled output")
else:
    xml_content = read_file(stages_dir / "output.xml")
    if not v6_scope_content:
        t3_pass = False
        failures.append("FAIL T3: S7-v6-scope.txt not found")
    elif not xml_content:
        t3_pass = False
        failures.append("FAIL T3: output.xml not found")
    elif v6_scope_content.strip() not in xml_content:
        t3_pass = False
        failures.append("FAIL T3: V6 scope not found verbatim in <v6_scope> element")
    else:
        results.append("PASS T3: V6 scope content matches verbatim in XML output")

# ========================
# T4: Structural completeness (distilled only)
# ========================
t4_pass = True
t4_details = []
if output_mode == "distilled":
    distilled_content = read_file(stages_dir / "output-distilled.md")
    if distilled_content:
        for section_name, min_pattern in T4_MINIMUMS.items():
            section_pattern = rf"##?\s*{re.escape(section_name)}\s*\n(.*?)(?=\n##|\Z)"
            section_m = re.search(section_pattern, distilled_content, re.DOTALL | re.IGNORECASE)
            if section_m:
                section_content = section_m.group(1)
                if not re.search(min_pattern, section_content, re.DOTALL | re.IGNORECASE):
                    has_empty = re.search(
                        r"\*\(Stage S\d+(?:\.\d+)?.*?(?:skipped|ran, no content|not reached|not activated)",
                        section_content, re.IGNORECASE)
                    if not has_empty:
                        t4_pass = False
                        t4_details.append(f"FAIL T4: Section '{section_name}' below minimum depth")
                        failures.append(f"FAIL T4: Section '{section_name}' below minimum depth")

if t4_pass and output_mode == "distilled":
    results.append("PASS T4: Structural completeness — all checked sections meet minimum depth")
elif output_mode != "distilled":
    results.append("PASS T4: N/A (XML mode)")
else:
    results.extend(t4_details)

# ========================
# T5: XML schema completeness
# ========================
t5_pass = True
t5_details = []
REQUIRED_XML_ELEMENTS = {"meta", "input_inventory", "verification_report",
                         "downstream_handoff", "schema_note", "hat_routing"}
for sid, xe in STAGE_XML_ELEMENT.items():
    if xe:
        REQUIRED_XML_ELEMENTS.add(xe)

if output_mode == "xml":
    xml_path = stages_dir / "output.xml"
    xml_content = read_file(xml_path)
    if not xml_content:
        t5_pass = False
        failures.append("FAIL T5: output.xml not found")
    else:
        for element in sorted(REQUIRED_XML_ELEMENTS):
            if not re.search(rf"<{re.escape(element)}[\s/>]", xml_content):
                t5_pass = False
                t5_details.append(f"FAIL T5: XML output missing element <{element}>")
                failures.append(f"FAIL T5: XML output missing element <{element}>")

if output_mode == "xml":
    if t5_pass:
        results.append(f"PASS T5: All {len(REQUIRED_XML_ELEMENTS)} required XML schema elements present")
    else:
        results.extend(t5_details)
else:
    results.append("PASS T5: N/A (distilled mode)")

# ========================
# T6: manifest.json validity (cogenius-specific)
# ========================
t6_pass = True
t6_details = []
manifest_path_obj = Path(manifest_path)

if not manifest_path_obj.exists():
    t6_pass = False
    t6_details.append("FAIL T6: manifest.json not found")
    failures.append("FAIL T6: manifest.json not found")
else:
    try:
        with open(manifest_path_obj) as f:
            manifest = json.load(f)
        # Required top-level fields (wall_seconds + spawns_total added in Improvement 5)
        required_fields = ["skill_version", "session_id", "flags", "stages",
                           "wall_seconds", "spawns_total"]
        missing_fields = [f for f in required_fields if f not in manifest]
        if missing_fields:
            t6_pass = False
            for mf in missing_fields:
                t6_details.append(f"FAIL T6: manifest.json missing required field '{mf}'")
                failures.append(f"FAIL T6: manifest.json missing field '{mf}'")
        else:
            # flags sub-fields
            flags = manifest.get("flags", {})
            required_flag_fields = ["model_large", "model_medium", "model_small"]
            missing_flags = [f for f in required_flag_fields if f not in flags]
            if missing_flags:
                t6_pass = False
                for mf in missing_flags:
                    t6_details.append(f"FAIL T6: manifest.json flags missing '{mf}'")
                    failures.append(f"FAIL T6: manifest.json flags missing '{mf}'")
            # stages must be a list
            stages_arr = manifest.get("stages", [])
            if not isinstance(stages_arr, list):
                t6_pass = False
                t6_details.append("FAIL T6: manifest.json 'stages' is not an array")
                failures.append("FAIL T6: manifest.json 'stages' is not an array")
            else:
                # Validate each stage entry has required fields
                entry_required = ["stage_id", "hat", "resolved_model", "status", "output_path"]
                for i, entry in enumerate(stages_arr):
                    for ef in entry_required:
                        if ef not in entry:
                            t6_pass = False
                            t6_details.append(
                                f"FAIL T6: manifest.json stages[{i}] missing field '{ef}'")
                            failures.append(
                                f"FAIL T6: manifest.json stages[{i}] missing '{ef}'")
                # Hat names must match hats.json
                for i, entry in enumerate(stages_arr):
                    hat = entry.get("hat", "")
                    if hat and hat not in hat_names:
                        advisories.append(
                            f"ADVISORY T6: stages[{i}] hat '{hat}' not in hats.json")
                # stages array must be non-empty (at least one stage ran)
                if len(stages_arr) == 0:
                    advisories.append(
                        "ADVISORY T6: manifest.json stages array is empty — no stages recorded")
        if t6_pass:
            results.append(
                f"PASS T6: manifest.json valid — {len(manifest.get('stages', []))} stage entries")
        else:
            results.extend(t6_details)
    except json.JSONDecodeError as e:
        t6_pass = False
        failures.append(f"FAIL T6: manifest.json is not valid JSON: {e}")

# ========================
# S6 advisory (scale-aware)
# ========================
s6_content = read_file(stages_dir / "S6-falsification.md")
if s6_content and "S6" in stage_list:
    alt_count_m = re.search(r"(\d+)\s+alternative", s6_content, re.IGNORECASE)
    if alt_count_m:
        alt_count = int(alt_count_m.group(1))
        if alt_count < 3:
            if scale == "DEEP":
                advisories.append(
                    f"ADVISORY: S6 produced {alt_count}/3 alternative hypotheses — "
                    "re-run with --xml to inspect full S6 raw state for coverage gaps.")
            else:
                advisories.append(
                    f"ADVISORY: S6 produced {alt_count}/3 alternative hypotheses — "
                    "re-run with --deep for fuller coverage.")

s2_content = read_file(stages_dir / "S2-constraint-escape.md")
if s2_content and re.search(r"<fallback_library>\s*\S", s2_content):
    advisories.append("ADVISORY: S2 Step 8 detected thin analogy output; de Bono lateral fallback supplemented.")

s1_content = read_file(stages_dir / "S1-state-loading.md")
if s1_content and re.search(r"ran, content minimal", s1_content, re.IGNORECASE):
    advisories.append(
        "ADVISORY: S1 detected minimal input content — confidence should be read as LOW "
        "regardless of S7 band; downstream reasoning has limited evidentiary base.")

# ========================
# Write report
# ========================
pass_count = sum(1 for r in results if r.startswith("PASS T"))
fail_count = len(failures)

report_lines = [
    "# epiphany-cogenius Test Report",
    "",
    f"Session: {session_id} | Scale: {scale} | Mode: {output_mode}",
    f"Active conditionals: {', '.join(active_conditionals) if active_conditionals else 'none'}",
    f"PASS: {pass_count}/6 checks",
    "",
]

if failures:
    report_lines.append("## Failures")
    for f in failures:
        report_lines.append(f"- {f}")
    report_lines.append("")

if advisories:
    report_lines.append("## Advisories")
    for a in advisories:
        report_lines.append(f"- {a}")
    report_lines.append("")

report_lines.append("## Detail")
for r in results:
    report_lines.append(f"- {r}")

report_content = "\n".join(report_lines) + "\n"
with open(stages_dir / "test-report.md", "w") as f:
    f.write(report_content)

print(f"Session: {session_id} | Scale: {scale} | Mode: {output_mode}")
print(f"Active conditionals: {', '.join(active_conditionals) if active_conditionals else 'none'}")
print(f"PASS: {pass_count}/6 checks")

if failures:
    print(f"\nTest failures: {fail_count}/6 checks failed")
    for f in failures:
        print(f"  {f}")
else:
    print("All checks passed (6/6).")

if advisories:
    for a in advisories:
        print(f"  {a}")

sys.exit(1 if failures else 0)
PYEOF
