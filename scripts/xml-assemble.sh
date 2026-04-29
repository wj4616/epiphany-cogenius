#!/usr/bin/env bash
# xml-assemble.sh — epiphany-cogenius v1.0.0
# Usage: xml-assemble.sh <session_dir>
# Assembles stages/output.xml from stage output files, driven by cogenius index.json.
# Adds hat routing metadata from manifest.json to the <meta> block.
# Stages not run → empty self-closing elements.
# Called by orchestrator STEP 7 when --xml flag is set.

set -euo pipefail

SESSION_DIR="${1:?Usage: xml-assemble.sh <session_dir>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
INDEX_FILE="${SKILL_DIR}/index.json"
STAGES_DIR="${SESSION_DIR}/stages"
OUTPUT_XML="${STAGES_DIR}/output.xml"
MANIFEST_JSON="${SESSION_DIR}/manifest.json"

if ! command -v python3 &>/dev/null; then
  echo "FAIL: python3 required for xml-assemble.sh"
  exit 1
fi

if [ ! -f "$INDEX_FILE" ]; then
  echo "FAIL: index.json not found at ${INDEX_FILE}"
  exit 1
fi

python3 - "$STAGES_DIR" "$OUTPUT_XML" "$INDEX_FILE" "$MANIFEST_JSON" << 'PYEOF'
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

stages_dir   = Path(sys.argv[1])
output_xml   = sys.argv[2]
index_path   = sys.argv[3]
manifest_path = sys.argv[4]

with open(index_path) as f:
    idx = json.load(f)

manifest = {}
if Path(manifest_path).exists():
    try:
        with open(manifest_path) as f:
            manifest = json.load(f)
    except json.JSONDecodeError:
        pass


def read_file_safe(path):
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        return ""


def xml_escape_attr(text):
    return (str(text)
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;"))


def cdata_wrap(text):
    if not text:
        return ""
    safe = text.replace("]]>", "]]]]><![CDATA[>")
    return f"<![CDATA[{safe}]]>"


def extract_session_field(session_md, field, default="unknown"):
    m = re.search(rf"^{field}:\s*(.+)$", session_md, re.MULTILINE)
    return m.group(1).strip() if m else default


# Read session metadata
session_md    = read_file_safe(stages_dir / "session.md")
session_id    = extract_session_field(session_md, "session_id",
                                      datetime.now().strftime("%Y%m%d-%H%M%S"))
scale         = extract_session_field(session_md, "scale", "STANDARD")
input_type    = extract_session_field(session_md, "input_type", "raw")
flag_xml      = extract_session_field(session_md, "flag_xml", "false")
flag_quiet    = extract_session_field(session_md, "flag_quiet", "false")
flag_verbose  = extract_session_field(session_md, "flag_verbose", "false")
flag_conjecture = extract_session_field(session_md, "flag_conjecture", "false")
signals       = extract_session_field(session_md, "signals", "[]")
tier_large    = extract_session_field(session_md, "tier_large", "claude-opus-4-7")
tier_medium   = extract_session_field(session_md, "tier_medium", "claude-sonnet-4-6")
tier_small    = extract_session_field(session_md, "tier_small", "claude-haiku-4-5-20251001")

# Build per-stage hat routing from manifest.json stages array
stage_routing = {}
for entry in manifest.get("stages", []):
    sid = entry.get("stage_id", "")
    if sid:
        stage_routing[sid] = {
            "hat": entry.get("hat", ""),
            "resolved_model": entry.get("resolved_model", ""),
            "status": entry.get("status", "")
        }

all_stages = idx.get("stages", []) + idx.get("conditional_modules", [])

# Active conditionals derived from file presence
active_conditionals = []
for entry in idx.get("conditional_modules", []):
    of = entry.get("output_file", "")
    if of and (stages_dir / Path(of).name).exists():
        active_conditionals.append(entry.get("stage_id", ""))
active_cond_str = ", ".join(c for c in active_conditionals if c) or "none"

processed_input = read_file_safe(stages_dir / "00-processed-input.md")
v6_scope = read_file_safe(stages_dir / "S7-v6-scope.txt")

# --- Build XML ---
lines = []
lines.append('<?xml version="1.0" encoding="UTF-8"?>')
lines.append('<cognitive_output_v1>')

lines.append('  <schema_note>')
lines.append('    Envelope model: each stage element wraps the stage\'s full markdown output')
lines.append('    in CDATA. Parse markdown content per stage. Only <meta>, <v6_scope>,')
lines.append('    <active_conditionals>, <signals>, and <hat_routing> are structured.')
lines.append('  </schema_note>')

skill_version = idx.get("version", "1.0.0")

lines.append('  <meta>')
lines.append(f'    <skill_version>{xml_escape_attr(skill_version)}</skill_version>')
lines.append(f'    <skill_name>epiphany-cogenius</skill_name>')
lines.append(f'    <session_id>{xml_escape_attr(session_id)}</session_id>')
lines.append(f'    <scale>{xml_escape_attr(scale)}</scale>')
lines.append(f'    <input_type>{xml_escape_attr(input_type)}</input_type>')
lines.append(f'    <flag_xml>{xml_escape_attr(flag_xml)}</flag_xml>')
lines.append(f'    <flag_verbose>{xml_escape_attr(flag_verbose)}</flag_verbose>')
lines.append(f'    <flag_quiet>{xml_escape_attr(flag_quiet)}</flag_quiet>')
lines.append(f'    <flag_conjecture>{xml_escape_attr(flag_conjecture)}</flag_conjecture>')
lines.append(f'    <active_conditionals>{xml_escape_attr(active_cond_str)}</active_conditionals>')
lines.append(f'    <signals>{xml_escape_attr(signals)}</signals>')
lines.append('  </meta>')

# Hat routing block — documents which model ran each stage
lines.append('  <hat_routing>')
lines.append(f'    <tier_large>{xml_escape_attr(tier_large)}</tier_large>')
lines.append(f'    <tier_medium>{xml_escape_attr(tier_medium)}</tier_medium>')
lines.append(f'    <tier_small>{xml_escape_attr(tier_small)}</tier_small>')
for sid, routing in stage_routing.items():
    lines.append(f'    <stage id="{xml_escape_attr(sid)}" '
                 f'hat="{xml_escape_attr(routing["hat"])}" '
                 f'model="{xml_escape_attr(routing["resolved_model"])}" '
                 f'status="{xml_escape_attr(routing["status"])}"/>')
lines.append('  </hat_routing>')

if processed_input.strip():
    lines.append(f'  <input_inventory>{cdata_wrap(processed_input.strip())}</input_inventory>')
else:
    lines.append('  <input_inventory/>')

stage_presence = {}
for entry in all_stages:
    xml_element = entry.get("xml_element")
    stage_id = entry.get("stage_id", "?")
    output_file = entry.get("output_file", "")
    if not xml_element:
        continue

    filename = Path(output_file).name if output_file else ""
    content = read_file_safe(stages_dir / filename) if filename else ""
    stage_presence[stage_id] = bool(content.strip())

    if content.strip():
        lines.append(f'  <{xml_element}>{cdata_wrap(content.strip())}</{xml_element}>')
    else:
        lines.append(f'  <{xml_element}/>')

if stage_presence.get("S7"):
    lines.append('  <verification_report>')
    if v6_scope.strip():
        lines.append(f'    <v6_scope>{cdata_wrap(v6_scope.strip())}</v6_scope>')
    else:
        lines.append('    <v6_scope/>')
    lines.append('    <note>V1-V5 and V7 results are inline in &lt;integration&gt; content.</note>')
    lines.append('  </verification_report>')
else:
    lines.append('  <verification_report/>')

lines.append('  <downstream_handoff/>')
lines.append('</cognitive_output_v1>')

output_content = "\n".join(lines) + "\n"
with open(output_xml, "w") as f:
    f.write(output_content)

print(f"XML assembled: {output_xml}")
present = [sid for sid, p in stage_presence.items() if p]
absent  = [sid for sid, p in stage_presence.items() if not p]
print(f"  Stages present: {', '.join(present) if present else 'none'}")
print(f"  Stages absent:  {', '.join(absent) if absent else 'none'}")
print(f"  Active conditionals: {active_cond_str}")
hat_summary = ', '.join(f"{sid}:{r['hat']}" for sid, r in stage_routing.items()) or 'none'
print(f"  Hat routing: {hat_summary}")
PYEOF
