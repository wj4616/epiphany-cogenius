#!/usr/bin/env bash
# run-tests.sh — epiphany-cogenius test runner (three tiers)
#
# Tier 1: Static checks    — SKILL.md structure, modules, KB, scripts, hats, index
# Tier 2: Pipeline validation — runs validate-pipeline.sh (DAG, KB, activation grammar)
# Tier 3: Gold-reference session replay — runs test-runner.sh on a saved session
#
# Usage:
#   ./run-tests.sh                                           # Tier 1 + 2
#   ./run-tests.sh --replay <session_dir> [SCALE] [CONDS]   # + Tier 3
#     SCALE: MINIMAL | STANDARD | DEEP  (default: STANDARD)
#     CONDS: comma-separated conditional stage IDs, or "none"  (default: none)
#
# After a full run, find the session dir at ~/docs/epiphany/cogenius/<session_id>/
# Example: ./run-tests.sh --replay ~/docs/epiphany/cogenius/abc123 DEEP S3.1

set -u

PASS=0; FAIL=0; SKIP=0
REPLAY_MODE=0
SESSION_DIR=""
SCALE="STANDARD"
CONDS="none"

if [[ "${1:-}" == "--replay" ]]; then
    REPLAY_MODE=1
    SESSION_DIR="${2:?--replay requires a session directory path}"
    SCALE="${3:-STANDARD}"
    CONDS="${4:-none}"
fi

SKILL_DIR="$HOME/.claude/skills/epiphany-cogenius"
SKILL_MD="$SKILL_DIR/SKILL.md"
INDEX="$SKILL_DIR/index.json"
HATS="$SKILL_DIR/hats.json"
SCRIPTS="$SKILL_DIR/scripts"
MODULES="$SKILL_DIR/modules"
KB="$SKILL_DIR/kb"

G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; N=$'\033[0m'

header()     { echo; printf "${B}=== %s ===${N}\n" "$1"; }
pass_check() { printf "  ${G}✓${N} %s\n" "$1"; ((PASS++)); }
fail_check() { printf "  ${R}✗${N} %s\n" "$1"; ((FAIL++)); }
skip_check() { printf "  ${Y}○${N} %s — %s\n" "$1" "$2"; ((SKIP++)); }

check_contains() {
    local desc="$1" pattern="$2" file="$3" invert="${4:-0}"
    local matched=0
    grep -qF -- "$pattern" "$file" 2>/dev/null && matched=1
    local pass=$matched
    [[ $invert -eq 1 ]] && pass=$((1 - matched))
    if [[ $pass -eq 1 ]]; then pass_check "$desc"; else fail_check "$desc (missing: $pattern)"; fi
}

check_exists() {
    local desc="$1" path="$2"
    if [[ -e "$path" ]]; then pass_check "$desc"; else fail_check "$desc (missing: $path)"; fi
}

check_exec() {
    local desc="$1" path="$2"
    if [[ -x "$path" ]]; then pass_check "$desc"; else fail_check "$desc not executable: $path"; fi
}

# ════════════════════════════════════════════════════════════════════
# TIER 1a — SKILL.md presence & frontmatter
# ════════════════════════════════════════════════════════════════════

header "Tier 1a — SKILL.md presence & frontmatter"
check_exists   "SKILL.md exists"                               "$SKILL_MD"
check_contains "name: epiphany-cogenius"                       "name: epiphany-cogenius"    "$SKILL_MD"
check_contains "version field present"                         "version:"                   "$SKILL_MD"
check_contains "trigger: /epiphany-cogenius"                   "/epiphany-cogenius"         "$SKILL_MD"
check_contains "skill_path documented"                         "skill_path:"                "$SKILL_MD"
check_contains "kb_base documented"                            "kb_base:"                   "$SKILL_MD"
check_contains "session_output_base documented"                "session_output_base:"       "$SKILL_MD"
check_contains "hats_file documented"                          "hats.json"                  "$SKILL_MD"
# Must NOT reference the old genius path
check_contains "no genius_skill_path cross-reference"          "genius_skill_path"          "$SKILL_MD" 1

header "Tier 1b — SKILL.md orchestrator steps (STEP 0–9)"
for step in 0 1 2 3 4 5 6 7 8 9; do
    check_contains "STEP $step documented" "STEP $step" "$SKILL_MD"
done

header "Tier 1c — SKILL.md flags & modes"
for flag in --minimal --standard --deep --xml --quiet --verbose --conjecture --no-save --resume; do
    check_contains "$flag documented" "$flag" "$SKILL_MD"
done
check_contains "MINIMAL scale documented"    "MINIMAL"    "$SKILL_MD"
check_contains "STANDARD scale documented"   "STANDARD"   "$SKILL_MD"
check_contains "DEEP scale documented"       "DEEP"       "$SKILL_MD"
check_contains "CONJECTURE mode documented"  "CONJECTURE" "$SKILL_MD"

header "Tier 1d — SKILL.md hat system & architecture rules"
check_contains "hat system documented"                     "hat"                        "$SKILL_MD"
check_contains "resolve-hat.sh invocation documented"      "resolve-hat.sh"             "$SKILL_MD"
check_contains "confidence-gate.sh invocation documented"  "confidence-gate.sh"         "$SKILL_MD"
check_contains "hats.json documented"                      "hats.json"                  "$SKILL_MD"
check_contains "three model tiers documented"              "tier"                       "$SKILL_MD"
check_contains "Enumerator hat documented"                 "Enumerator"                 "$SKILL_MD"
check_contains "Explorer hat documented"                   "Explorer"                   "$SKILL_MD"
check_contains "Simulator hat documented"                  "Simulator"                  "$SKILL_MD"
check_contains "Precision hat documented"                  "Precision"                  "$SKILL_MD"
check_contains "Adversary hat documented"                  "Adversary"                  "$SKILL_MD"
check_contains "Synthesizer hat documented"                "Synthesizer"                "$SKILL_MD"
check_contains "OSP documented"                            "OSP"                        "$SKILL_MD"
check_contains "V1-V7 verification documented"             "V1–V7"                      "$SKILL_MD"
check_contains "S3_thin_or_empty signal documented"        "S3_thin_or_empty"           "$SKILL_MD"
check_contains "S6_no_alternatives signal documented"      "S6_no_alternatives"         "$SKILL_MD"
check_contains "wave-based execution documented"           "wave"                       "$SKILL_MD"
check_contains "session directory layout section"          "SESSION DIRECTORY LAYOUT"   "$SKILL_MD"
check_contains "manifest atomic write documented"          "os.replace"                 "$SKILL_MD"
check_contains "test-runner.sh invocation documented"      "test-runner.sh"             "$SKILL_MD"
check_contains "xml-assemble.sh invocation documented"     "xml-assemble.sh"            "$SKILL_MD"
# Improvement 8: xml-assemble.sh reads skill_version from index.json (not hardcoded)
if [[ -f "$SCRIPTS/xml-assemble.sh" ]]; then
    if grep -q 'idx.get("version"' "$SCRIPTS/xml-assemble.sh"; then
        pass_check "xml-assemble.sh reads version from index.json (not hardcoded)"
    else
        fail_check "xml-assemble.sh still hardcodes skill_version"
    fi
fi
check_contains "OSP spawn passes flag_verbose"             "flag_verbose"               "$SKILL_MD"
check_contains "OSP spawn passes scale"                    "scale: {scale}"             "$SKILL_MD"
check_contains "optional_dependencies in spawn prompt"     "optional_dependencies"      "$SKILL_MD"
check_contains "context_budget enforcement in spawn"       "context_budget_lines"       "$SKILL_MD"
check_contains "ollama dispatch documented"                "ollama run"                 "$SKILL_MD"
check_contains "resume flag recovery documented"           "manifest.get"               "$SKILL_MD"
check_contains "confidence-gate.sh called (not inline)"    "confidence-gate.sh"         "$SKILL_MD"
check_contains "output_mode uses distilled (not markdown)" "distilled"                  "$SKILL_MD"
# Bug 4: hat_name template var replaced with $HAT bash var in confidence-gate.sh call
check_contains "confidence-gate uses \$HAT (not {hat_name})" '$HAT'                    "$SKILL_MD"
check_contains "{hat_name} not used in gate call (bug 4)"    '{hat_name}'               "$SKILL_MD" 1
# Bug 3: session_dir always has trailing slash after normalization
check_contains "RESOLVED_DIR trailing slash normalization"  'RESOLVED_DIR="${RESOLVED_DIR%/}/"' "$SKILL_MD"
# Improvement 5: spawns_total and wall_start initialized in STEP 0
check_contains "spawns_total initialized in STEP 0"         "spawns_total=0"             "$SKILL_MD"
check_contains "wall_start initialized in STEP 0"           "wall_start=\$(date +%s)"   "$SKILL_MD"
check_contains "wall_seconds computed in STEP 9"            "wall_seconds=\$"            "$SKILL_MD"
# Improvement 6: session.md update uses re.sub pattern
check_contains "session.md update uses re.sub"              "re.sub"                     "$SKILL_MD"
# Deep audit Bug C: SESSION_ID assigned from RESOLVED_DIR, not undefined
check_contains "SESSION_ID derived from RESOLVED_DIR (bug C)"  'SESSION_ID=$(basename' "$SKILL_MD"
# Deep audit Bug J: resolved_model updated after escalation before manifest write
check_contains "resolved_model updated after escalation (bug J)"  'resolved_model="<model>"' "$SKILL_MD"
# Deep audit Bug M: Agent input_deps path documented as relative to session_dir (no double stages/)
check_contains "input_deps path relative to session_dir (bug M)"  'relative to {session_dir}' "$SKILL_MD"
# Deep audit Bug N: ollama dispatch includes optional_dependencies step
check_contains "ollama dispatch loads optional_dependencies (bug N)"  'optional_dependencies' "$SKILL_MD"
# Deep audit Bug Q: OSP spawn is guarded by flag_xml NOT set
if grep -qE 'flag_xml.*NOT.*set|skip OSP' "$SKILL_MD"; then
    pass_check "OSP spawn guarded by flag_xml not set (bug Q)"
else
    fail_check "OSP spawn guarded by flag_xml not set (bug Q) — SKILL.md missing gate"
fi
# Deep audit Bug Y: confidence-gate.sh fallback uses narrow bold-label pattern (not broad substring)
if [[ -f "$SCRIPTS/confidence-gate.sh" ]]; then
    if grep -q 'label_pattern' "$SCRIPTS/confidence-gate.sh"; then
        pass_check "confidence-gate.sh fallback uses narrow label_pattern (bug Y)"
    else
        fail_check "confidence-gate.sh fallback still uses broad 'section in content' (bug Y)"
    fi
fi
# Deep audit Bug AA: test-runner.sh T6 validates wall_seconds + spawns_total
if [[ -f "$SCRIPTS/test-runner.sh" ]]; then
    if grep -q '"wall_seconds"' "$SCRIPTS/test-runner.sh" && grep -q '"spawns_total"' "$SCRIPTS/test-runner.sh"; then
        pass_check "test-runner.sh T6 checks wall_seconds and spawns_total (bug AA)"
    else
        fail_check "test-runner.sh T6 missing wall_seconds/spawns_total validation (bug AA)"
    fi
fi

# ════════════════════════════════════════════════════════════════════
# TIER 1e — Module files
# ════════════════════════════════════════════════════════════════════

header "Tier 1e — Module files"
for mod in \
    S1-state-loading.md \
    S2-constraint-escape.md \
    S3-peripheral-exploration.md \
    S3-1-defixation.md \
    S4-dynamic-simulation.md \
    S5-precision-forcing.md \
    S6-falsification.md \
    S6-1-conjecture.md \
    S7-integration-verification.md \
    output-synthesis-pass.md; do
    check_exists "modules/$mod" "$MODULES/$mod"
done

header "Tier 1f — Module required_output_sections (from index.json)"
if command -v python3 &>/dev/null && [[ -f "$INDEX" ]]; then
    python3 - "$INDEX" "$MODULES" << 'PYEOF'
import json, sys
from pathlib import Path

index_path, modules_dir = sys.argv[1], sys.argv[2]
with open(index_path) as f:
    idx = json.load(f)

entries = idx.get("stages", []) + idx.get("conditional_modules", [])
fail = 0

for entry in entries:
    sid = entry["stage_id"]
    module_file = Path(modules_dir) / Path(entry["module_file"]).name
    sections = entry.get("required_output_sections", [])
    if not module_file.exists():
        print(f"  \033[31m✗\033[0m {sid}: module file missing — {module_file}")
        fail += 1
        continue
    content = module_file.read_text()
    for section in sections:
        if section.lower() in content.lower():
            print(f"  \033[32m✓\033[0m {sid}: section '{section}'")
        else:
            print(f"  \033[31m✗\033[0m {sid}: section '{section}' not found in {module_file.name}")
            fail += 1

sys.exit(fail)
PYEOF
    if [[ $? -eq 0 ]]; then ((PASS++)); else ((FAIL++)); fi
else
    skip_check "Module required sections" "python3 or index.json not available"
fi

# ════════════════════════════════════════════════════════════════════
# TIER 1g — KB files
# ════════════════════════════════════════════════════════════════════

header "Tier 1g — KB files"
for kb_file in \
    blend-template.md \
    boden-types.md \
    debono-techniques.md \
    domain-catalog.md \
    elegance-rubric.md \
    falsification-checklists.md \
    forward-chain-template.md \
    input-preloading-templates.md \
    observer-frames.md \
    ohlsson-defixation.md \
    pattern-taxonomy.md \
    representation-frames.md \
    scope-template.md \
    simulation-checklist.md \
    spreading-activation.md \
    tot-templates.md \
    verification-gates.md \
    vocabulary-rubric.md; do
    check_exists "kb/$kb_file" "$KB/$kb_file"
done

# ════════════════════════════════════════════════════════════════════
# TIER 1h — Scripts present & executable
# ════════════════════════════════════════════════════════════════════

header "Tier 1h — Scripts present & executable"
for script in \
    resolve-hat.sh \
    confidence-gate.sh \
    session-init.sh \
    test-resolve-hat.sh \
    test-runner.sh \
    validate-pipeline.sh \
    validate-stage.sh \
    xml-assemble.sh; do
    check_exists "$script exists"       "$SCRIPTS/$script"
    check_exec   "$script executable"   "$SCRIPTS/$script"
done

# ════════════════════════════════════════════════════════════════════
# TIER 1i — index.json validity & structure
# ════════════════════════════════════════════════════════════════════

header "Tier 1i — index.json validity"
check_exists "index.json exists" "$INDEX"
if [[ -f "$INDEX" ]]; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$INDEX" 2>/dev/null; then
        pass_check "index.json is valid JSON"
    else
        fail_check "index.json is not valid JSON"
    fi

    idx_version=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['version'])" "$INDEX" 2>/dev/null)
    if grep -qF -- "$idx_version" "$SKILL_MD"; then
        pass_check "index.json version ($idx_version) referenced in SKILL.md"
    else
        fail_check "index.json version ($idx_version) not found in SKILL.md"
    fi

    python3 - "$INDEX" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f: idx = json.load(f)
required = {"version","kb_base","session_output_base","mode_shift_after",
            "stages","conditional_modules","output_synthesis_pass","signals","scale_auto_detection"}
missing = required - set(idx.keys())
if missing:
    print(f"  \033[31m✗\033[0m index.json missing keys: {', '.join(sorted(missing))}")
    sys.exit(1)
else:
    print(f"  \033[32m✓\033[0m index.json has all required top-level keys")
PYEOF
    if [[ $? -eq 0 ]]; then ((PASS++)); else ((FAIL++)); fi

    # kb_base must point to cogenius, not genius
    kb_base=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['kb_base'])" "$INDEX" 2>/dev/null)
    if echo "$kb_base" | grep -q "epiphany-cogenius"; then
        pass_check "index.json kb_base points to cogenius ($kb_base)"
    else
        fail_check "index.json kb_base does not point to cogenius: $kb_base"
    fi

    # Every stage must have a hat field
    python3 - "$INDEX" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f: idx = json.load(f)
entries = idx.get("stages", []) + idx.get("conditional_modules", [])
missing_hat = [e["stage_id"] for e in entries if not e.get("hat")]
if missing_hat:
    print(f"  \033[31m✗\033[0m stages missing hat field: {', '.join(missing_hat)}")
    sys.exit(1)
else:
    print(f"  \033[32m✓\033[0m all stages have hat field ({len(entries)} stages)")
PYEOF
    if [[ $? -eq 0 ]]; then ((PASS++)); else ((FAIL++)); fi

    # Improvement 7: OSP required_output_sections in index.json (not hardcoded in scripts)
    python3 - "$INDEX" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f: idx = json.load(f)
osp = idx.get("output_synthesis_pass", {})
sections = osp.get("required_output_sections", [])
if len(sections) >= 5:
    print(f"  \033[32m✓\033[0m output_synthesis_pass has required_output_sections ({len(sections)} sections)")
else:
    print(f"  \033[31m✗\033[0m output_synthesis_pass missing required_output_sections (found {len(sections)})")
    sys.exit(1)
PYEOF
    if [[ $? -eq 0 ]]; then ((PASS++)); else ((FAIL++)); fi
fi

# ════════════════════════════════════════════════════════════════════
# TIER 1j — hats.json validity & cross-reference
# ════════════════════════════════════════════════════════════════════

header "Tier 1j — hats.json validity & cross-reference"
check_exists "hats.json exists" "$HATS"
if [[ -f "$HATS" ]]; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$HATS" 2>/dev/null; then
        pass_check "hats.json is valid JSON"
    else
        fail_check "hats.json is not valid JSON"
    fi

    # All 6 hats present with required fields
    python3 - "$HATS" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f: hats = json.load(f)
EXPECTED = {"Enumerator", "Explorer", "Simulator", "Precision", "Adversary", "Synthesizer"}
REQUIRED_FIELDS = {"hat_name", "default_tier", "confidence_threshold", "description"}
fail = 0
found = set()
for h in hats:
    name = h.get("hat_name", "?")
    found.add(name)
    missing = REQUIRED_FIELDS - set(h.keys())
    if missing:
        print(f"  \033[31m✗\033[0m {name}: missing fields: {', '.join(sorted(missing))}")
        fail += 1
    else:
        print(f"  \033[32m✓\033[0m {name}: all required fields present")
missing_hats = EXPECTED - found
for mh in sorted(missing_hats):
    print(f"  \033[31m✗\033[0m missing hat: {mh}")
    fail += 1
sys.exit(fail)
PYEOF
    if [[ $? -eq 0 ]]; then ((PASS++)); else ((FAIL++)); fi

    # Stage hat values reference known hats
    if [[ -f "$INDEX" ]]; then
        python3 - "$INDEX" "$HATS" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f: idx = json.load(f)
with open(sys.argv[2]) as f: hats_list = json.load(f)
known_hats = {h["hat_name"] for h in hats_list}
entries = idx.get("stages", []) + idx.get("conditional_modules", [])
fail = 0
for e in entries:
    hat = e.get("hat", "")
    if hat and hat not in known_hats:
        print(f"  \033[31m✗\033[0m {e['stage_id']}: hat '{hat}' not in hats.json")
        fail += 1
if fail == 0:
    print(f"  \033[32m✓\033[0m all stage hat values reference known hats")
sys.exit(fail)
PYEOF
        if [[ $? -eq 0 ]]; then ((PASS++)); else ((FAIL++)); fi
    fi
fi

# ════════════════════════════════════════════════════════════════════
# TIER 2 — PIPELINE VALIDATION
# ════════════════════════════════════════════════════════════════════

header "Tier 2 — Pipeline validation (DAG, KB files, activation grammar)"
if [[ -x "$SCRIPTS/validate-pipeline.sh" ]]; then
    pipeline_out=$("$SCRIPTS/validate-pipeline.sh" 2>&1)
    pipeline_exit=$?
    echo "$pipeline_out" | sed 's/^/  /'
    if [[ $pipeline_exit -eq 0 ]]; then
        pass_check "validate-pipeline.sh: all checks passed"
    else
        fail_check "validate-pipeline.sh: one or more checks failed"
    fi
else
    fail_check "validate-pipeline.sh not executable — cannot run pipeline validation"
fi

# ════════════════════════════════════════════════════════════════════
# TIER 3 — GOLD-REFERENCE REPLAY
# ════════════════════════════════════════════════════════════════════

if [[ $REPLAY_MODE -eq 1 ]]; then
    header "Tier 3 — Gold-reference replay: $SESSION_DIR (scale=$SCALE, conds=$CONDS)"

    if [[ ! -d "$SESSION_DIR" ]]; then
        fail_check "Session directory not found: $SESSION_DIR"
    elif [[ ! -x "$SCRIPTS/test-runner.sh" ]]; then
        fail_check "test-runner.sh not executable — cannot replay"
    else
        replay_out=$("$SCRIPTS/test-runner.sh" "$SESSION_DIR" "$SCALE" "$CONDS" "distilled" 2>&1)
        replay_exit=$?
        echo "$replay_out" | sed 's/^/  /'
        if [[ $replay_exit -eq 0 ]]; then
            pass_check "test-runner.sh T1-T5: all checks passed"
        else
            fail_check "test-runner.sh T1-T5: one or more checks failed"
        fi

        if [[ -f "$SESSION_DIR/stages/output.xml" ]]; then
            replay_xml=$("$SCRIPTS/test-runner.sh" "$SESSION_DIR" "$SCALE" "$CONDS" "xml" 2>&1)
            xml_exit=$?
            echo "$replay_xml" | sed 's/^/  /'
            if [[ $xml_exit -eq 0 ]]; then
                pass_check "test-runner.sh T5 (xml mode): all checks passed"
            else
                fail_check "test-runner.sh T5 (xml mode): one or more checks failed"
            fi
        else
            skip_check "T5 xml mode" "output.xml not found in session (run with --xml to generate)"
        fi
    fi
else
    echo
    printf "  ${Y}○${N} Tier 3 skipped — no --replay session provided\n"
    printf "    After a full run, replay with:\n"
    printf "    %s --replay ~/docs/epiphany/cogenius/<session_id> [SCALE] [CONDS]\n" "$0"
    ((SKIP++))
fi

# ── Summary ─────────────────────────────────────────────────────────
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  ${G}PASS${N}: %-3d  ${R}FAIL${N}: %-3d  ${Y}SKIP${N}: %-3d\n" "$PASS" "$FAIL" "$SKIP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ $FAIL -eq 0 ]]
