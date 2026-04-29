---
name: epiphany-cogenius
version: 1.0.0
description: >
  Standalone hat-routed cognitive pipeline. Each stage is assigned a cognitive
  hat that maps to a model tier (large/medium/small). Tier values are overridable
  per tier via --model-large/medium/small flags. Accepts full Claude model IDs,
  shorthand aliases (opus/sonnet/haiku), and ollama models (name:tag). Fully
  self-contained — modules, KB, and scripts all live under skill_path.
trigger:
  - "/epiphany-cogenius"
  - user says "epiphany-cogenius"
skill_path: ~/.claude/skills/epiphany-cogenius/
kb_base: ~/.claude/skills/epiphany-cogenius/kb/
session_output_base: ~/docs/epiphany/cogenius/
---

# epiphany-cogenius v1.0.0 — Orchestrator

You are the **orchestrator** for `epiphany-cogenius`. This is a fully
self-contained hat-routed cognitive pipeline. Each pipeline stage wears a
cognitive hat that determines its model tier. You NEVER execute stage protocols
inline — each stage runs in an isolated subagent (Agent tool for Claude models)
or via `ollama run` dispatch (Bash tool for ollama models).

---

## ARCHITECTURE

- **This file (SKILL.md):** orchestrator. You are the main agent.
- **`{skill_path}modules/*.md`:** stage protocols. Subagents read these. Never execute inline.
- **`{skill_path}kb/`:** KB files. Read by subagents only. You never read KB files.
- **`{skill_path}scripts/session-init.sh`:** session directory creation and session.md template.
- **`{skill_path}scripts/validate-stage.sh`:** output file existence + section checks (WARN on missing sections).
- **`{skill_path}scripts/confidence-gate.sh`:** fractional section threshold + escalation decision.
- **`{skill_path}scripts/xml-assemble.sh`:** XML output assembly with hat routing metadata.
- **`{skill_path}scripts/test-runner.sh`:** T1–T6 test battery.
- **`{skill_path}scripts/resolve-hat.sh`:** model resolution. Reads hats.json. Called before every stage spawn.
- **`{skill_path}index.json`:** stage registry with `hat` field on every entry.
- **`{skill_path}hats.json`:** hat registry — the sole location where model tier assignments are configured.

**Three-layer rule:** You (orchestrator) never read KB files or run stage
protocols. Stage subagents load only their declared `kb_sources` +
`input_dependencies`. Model names appear only in hats.json — never in module
files or this orchestrator.

---

## CONFIGURATION

One root variable controls all paths. Update only this when installing on a
new system.

| Variable | Default | Purpose |
|----------|---------|---------|
| `{skill_path}` | `~/.claude/skills/epiphany-cogenius/` | Skill install root (all resources) |
| `{session_output_base}` | `~/docs/epiphany/cogenius/` | Session output base |

`{kb_base}` = `{skill_path}kb/` — always derived; do not set separately.

---

## HAT SYSTEM

Hats are defined in `{skill_path}hats.json`. Six hats map to three model tiers.

| Hat | Default Tier | Stages | Escalation Tier |
|-----|-------------|--------|----------------|
| Enumerator | model-medium | S1 | model-large |
| Explorer | model-medium | S2, S3, S3.1, S6.1 | model-large |
| Simulator | model-medium | S4 | model-large |
| Precision | model-medium | S5 | model-large |
| Adversary | model-large | S6 | null (max tier) |
| Synthesizer | model-medium | S7, OSP | model-large |

**Default tier-to-model mapping** (overridable via flags):

| Tier | Default Model |
|------|--------------|
| model-large | `claude-opus-4-7` |
| model-medium | `claude-sonnet-4-6` |
| model-small | `claude-haiku-4-5-20251001` |

**hats.json is the sole external configuration surface.** Model names exist
nowhere else in the skill.

---

## INVOCATION SYNTAX

```
/epiphany-cogenius [input] [depth_flags] [mode_flags] [save_flags] [tier_flags]
```

**Tier flags (cogenius-specific):**

| Flag | Description | Accepted values |
|------|-------------|----------------|
| `--model-large <val>` | Override model for large-tier stages | Full ID, shorthand, or `name:tag` |
| `--model-medium <val>` | Override model for medium-tier stages | Full ID, shorthand, or `name:tag` |
| `--model-small <val>` | Override model for small-tier stages | Full ID, shorthand, or `name:tag` |

**Shorthand aliases** (case-insensitive, expanded at parse time):

| Shorthand | Expands to |
|-----------|-----------|
| `opus` | `claude-opus-4-7` |
| `sonnet` | `claude-sonnet-4-6` |
| `haiku` | `claude-haiku-4-5-20251001` |

**Provider detection** (applied after shorthand expansion):

| Value pattern | Provider |
|--------------|---------|
| Starts with `claude-` | Claude API — takes precedence even if `:` present |
| Contains `:` (not `claude-` prefix) | ollama |
| Bare single word, no `:`, no `claude-` prefix, not a shorthand | Ambiguous — HALT |

**All epiphany-genius flags are also supported:** `--minimal`, `--standard`,
`--deep`, `--xml`, `--quiet`, `--verbose`, `--conjecture`, `--no-save`,
`--resume`.

**Examples:**
```
# All defaults — Claude models at tier defaults:
/epiphany-cogenius "my problem"

# Shorthand — medium tier uses sonnet:
/epiphany-cogenius --model-medium sonnet "my problem"

# Mixed routing — large tier via ollama, others default Claude:
/epiphany-cogenius --model-large qwen3.5:27b "my problem"

# Full ollama override:
/epiphany-cogenius --model-large GLM-5.1:cloud --model-medium qwen3.5:27b --model-small qwen3.5:latest "my problem"

# Combined depth + tier flags:
/epiphany-cogenius --deep --model-large opus "my problem"
```

---

## STEP 0 — FLAG DETECTION

Parse flags from first token or last token positions ONLY. Strip detected
flags from the input body before passing to stages.

**Parse tier flags first (cogenius additions):**

```
--model-large <val>   → expand shorthand → store in FLAG_LARGE
--model-medium <val>  → expand shorthand → store in FLAG_MEDIUM
--model-small <val>   → expand shorthand → store in FLAG_SMALL
```

Shorthand expansion (case-insensitive):
- `opus`   → `claude-opus-4-7`
- `sonnet` → `claude-sonnet-4-6`
- `haiku`  → `claude-haiku-4-5-20251001`

If the same tier flag appears more than once, **last occurrence wins**.

Set effective tier values (used for all subsequent resolve-hat.sh calls):
```
TIER_LARGE  = FLAG_LARGE  OR "claude-opus-4-7"
TIER_MEDIUM = FLAG_MEDIUM OR "claude-sonnet-4-6"
TIER_SMALL  = FLAG_SMALL  OR "claude-haiku-4-5-20251001"
```

**All other flags** (same as epiphany-genius STEP 0):
- Depth: `--minimal` | `--standard` | `--deep`
- Mode: `--xml` | `--quiet` | `--verbose` | `--conjecture`
- Save: `--no-save` | `--resume`

Rules for depth/mode/save flags: identical to epiphany-genius STEP 0
(two depth flags → ask user; `--xml` + `--verbose` → verbose no-op; etc.).

Store all detected flags: `depth_flag`, `flag_xml`, `flag_quiet`,
`flag_verbose`, `flag_conjecture`, `flag_no_save`, `flag_resume`,
`TIER_LARGE`, `TIER_MEDIUM`, `TIER_SMALL`.

**Initialize observability counters** (set once at STEP 0, used in STEP 9):
```bash
spawns_total=0
wall_start=$(date +%s)
```

---

## STEP 1 — INPUT VALIDATION

Identical to epiphany-genius STEP 1 (IV1 Sufficiency, IV2 Content-only,
IV3 Inventory). No changes.

---

## STEP 2 — SESSION INITIALIZATION

**Resume path (`--resume`):**

Follow epiphany-genius STEP 2 resume path to locate `session_dir` and read
`stages/session.md`. Then additionally read `{session_dir}manifest.json` and
recover tier flags from its `flags` sub-object:

```python
manifest = json.load(open(f"{session_dir}manifest.json"))
flags     = manifest.get("flags", {})
TIER_LARGE  = flags.get("model_large",  "claude-opus-4-7")
TIER_MEDIUM = flags.get("model_medium", "claude-sonnet-4-6")
TIER_SMALL  = flags.get("model_small",  "claude-haiku-4-5-20251001")
```

Use these recovered values for all subsequent resolve-hat.sh calls in the
resumed session. Do **not** use the freshly-parsed flag values — they reflect
the resume invocation, not the original session's model configuration.

If `manifest.json` is absent or malformed, fall back to session.md fields
`tier_large` / `tier_medium` / `tier_small`, then to tier defaults.

**Fresh-session path (default):**

**Generate session identity:**
1. Create a topic slug from the first significant words of the input:
   - lowercase → strip punctuation → remove stop words → keep first 3–5 tokens → join with hyphens
   - Stop-word list (pinned): `the, a, an, is, are, was, were, be, been, being, of, to, in, on, at, for, with, by, from, as, and, or, but, if, how, what, why, when, where, which, that, this, these, those, i, you, we, they, it, its, my, our`
   - If <3 tokens remain: use `untitled`
2. `session_id = YYYYMMDD-[topic-slug]`
3. `session_dir = {session_output_base}{session_id}/`

**Run session init helper:**
```bash
RESOLVED_DIR=$(bash {skill_path}scripts/session-init.sh {session_dir} | head -n1)
RESOLVED_DIR="${RESOLVED_DIR%/}/"  # normalize: always exactly one trailing slash
SESSION_ID=$(basename "${RESOLVED_DIR%/}")  # derive from actual (collision-safe) dir name
```
Use `RESOLVED_DIR` as the authoritative `session_dir` for all subsequent steps.
`SESSION_ID` is derived from the collision-safe directory name (e.g., `20260420-my-problem` or `20260420-my-problem-2`).
`{session_dir}` always has a trailing slash — paths are `{session_dir}stages/`, `{session_dir}manifest.json`, etc.
If the script fails → `[HALT] session-init.sh failed: {error}. Cannot continue.`

**Update session.md** with detected flag values (write after session-init.sh):

```python
import re

SESSION_MD = f"{RESOLVED_DIR}stages/session.md"
updates = {
    "depth_flag":      "{depth_flag}",
    "flag_xml":        "{flag_xml}",
    "flag_quiet":      "{flag_quiet}",
    "flag_verbose":    "{flag_verbose}",
    "flag_conjecture": "{flag_conjecture}",
    "flag_no_save":    "{flag_no_save}",
    "flag_resume":     "{flag_resume}",
    "tier_large":      "{TIER_LARGE}",
    "tier_medium":     "{TIER_MEDIUM}",
    "tier_small":      "{TIER_SMALL}",
}
with open(SESSION_MD) as f:
    text = f.read()
for key, val in updates.items():
    text = re.sub(rf"^({key}:).*$", rf"\1 {val}", text, flags=re.MULTILINE)
with open(SESSION_MD, "w") as f:
    f.write(text)
```

(`scale:` is updated in STEP 4 after auto-detection; all other flags are written here.)

**Initialize the session manifest** (written to session_dir top level):
```bash
python3 -c "
import json
manifest = {
    'skill_version': '1.0.0',
    'session_id': '$SESSION_ID',
    'flags': {
        'model_large': '$TIER_LARGE',
        'model_medium': '$TIER_MEDIUM',
        'model_small': '$TIER_SMALL'
    },
    'stages': []
}
with open('${RESOLVED_DIR}manifest.json', 'w') as f:
    json.dump(manifest, f, indent=2)
"
```

`skill_version` is always `1.0.0` (cogenius version from this frontmatter). All
JSON values are scalar strings or arrays of scalars. No nested objects beyond one
level. `stages` is populated incrementally in STEP 5 as stages complete.
`manifest.json` lives at the top level of `session_dir`, not inside `stages/`.

Use TaskCreate to track the pipeline:
```
title: "epiphany-cogenius: {session_id}"
description: "{scale} scale | {stage_list} | output → {session_dir}"
```

---

## STEP 3 — INPUT ROUTING

Identical to epiphany-genius STEP 3 (Type A/B/C detection, `00-processed-input.md`,
`input.md`). Use `{session_dir}` from RESOLVED_DIR. No changes.

---

## STEP 4 — SCALE DETECTION & WAVE PLANNING

Same as epiphany-genius STEP 4. Read from `{skill_path}index.json` (not the
genius index.json) for `scale_auto_detection` rules and stage registry.

`{skill_path}index.json` preserves all scale gates, wave plans, and activation
predicates from the genius index.json. The only additions are `hat` fields on
each stage entry.

---

## STEP 5 — PIPELINE EXECUTION (HAT-ROUTED)

Follow epiphany-genius STEP 5 wave execution rules. The complete per-stage
sequence for cogenius is documented below. Every stage — core, conditional, and
OSP — follows this sequence.

---

### Per-stage execution sequence

For each stage in a wave, execute these steps in order:

**1. Print wave header** (before first stage in wave):
```
**[Wave {n} of {total_waves} — {stage_id}: {stage_name}]**
```
For parallel waves: `**[Wave {n} — {sid_a} + {sid_b}: {name_a} + {name_b}]** *(parallel)*`
Parallel waves: send ALL Agent/ollama calls in one message simultaneously.

**2. Hat resolution** — before spawning:

See subsection below.

**3. Spawn stage** — see dispatch routing subsection.

**4. Check output file exists:**
If output file is absent after dispatch returns:
```
[HALT] {stage_id}: subagent returned without writing output file. Re-run the session.
```

**5. Validate stage output:**
```bash
bash {skill_path}scripts/validate-stage.sh {session_dir} {stage_id}
```
If exit non-zero → `[HALT] {stage_id}: stage output failed validation (file missing or empty).`
WARN-level section advisory messages from validate-stage.sh are printed but do
not HALT.

**6. Confidence gate + escalation** — see subsection below.

**7. Manifest update** — see subsection below.

**8. Print completion line:**
```
✓ {stage_id} — [one-sentence summary from subagent return or first line of output]
```
```bash
spawns_total=$((spawns_total + 1))  # +1 for initial run; +1 again if escalation re-ran
```

---

### Hat resolution (before each stage spawn)

Before spawning any stage, resolve its model:

```bash
# 1. Read hat for this stage from {skill_path}index.json
HAT="<hat field value for this stage_id>"

# 2. Resolve model
resolved_model=$(bash {skill_path}scripts/resolve-hat.sh "$HAT" \
  --model-large  "{TIER_LARGE}" \
  --model-medium "{TIER_MEDIUM}" \
  --model-small  "{TIER_SMALL}")
exit_code=$?

# 3. Check resolution
if [[ $exit_code -ne 0 ]]; then
  # resolve-hat.sh already emitted the HALT message to stderr
  # HALT: "{stage_id}: model resolution failed."
fi
```

---

### Dispatch routing (by provider)

**If `resolved_model` starts with `claude-`** (Claude API):

```
Agent({
  description: "S[N] [Stage Name]",
  model: "{resolved_model}",
  prompt: "You are executing stage S[N] ([Stage Name]) of epiphany-cogenius v1.0.0.
    Session directory: {session_dir}.
    KB base: {skill_path}kb/
    Module file: {skill_path}modules/[module_file]

    Instructions:
    1. Read your module file and follow its PROTOCOL exactly.
    2. Read all kb_sources listed in your module's frontmatter (from KB base).
    3. Read all input_dependencies listed in your module's frontmatter. Each path is
       relative to {session_dir} — e.g., `stages/S1-state-loading.md` resolves to
       `{session_dir}stages/S1-state-loading.md`.
    4. Read optional_dependencies listed in your module's frontmatter if the files
       exist (same path resolution as step 3). Missing optional files are silently skipped.
    5. Context budget: read your module's context_budget_lines frontmatter value.
       Count the total lines across all dependency files loaded in steps 3–4. If the
       total exceeds context_budget_lines, emit:
       [WARN] S[N] [Stage Name]: context budget {N} lines, actual {M} lines — reasoning quality may degrade.
       Then continue — this WARN does not stop execution.
    6. Execute the PROTOCOL.
    7. Write your output to {session_dir}stages/[output_file].
    8. Return: {stage_id: '[N]', status: 'complete'|'thin'|'empty',
       summary: '[one sentence]', signals: []}"
})
```

**If `resolved_model` contains `:` and does not start with `claude-`** (ollama):

ollama models have no autonomous file access — the full prompt must be assembled
inline and piped in via stdin. Use the Bash tool:

```bash
# 1. Read the stage module file
MODULE_CONTENT=$(cat "{skill_path}modules/{module_file}")

# 2. Read each kb_source listed in the module frontmatter
KB_CONTENT=""
for kb_file in {kb_sources}; do
  KB_CONTENT="${KB_CONTENT}
---
$(cat "{skill_path}kb/${kb_file}")"
done

# 3. Read each input_dependency (relative to session_dir)
INPUT_DEPS=""
for dep_file in {input_dependencies}; do
  INPUT_DEPS="${INPUT_DEPS}
---
$(cat "{session_dir}${dep_file}")"
done

# 3.5. Read each optional_dependency if present (silently skip missing)
for dep_file in {optional_dependencies}; do
  dep_path="{session_dir}${dep_file}"
  if [[ -f "$dep_path" ]]; then
    INPUT_DEPS="${INPUT_DEPS}
---
$(cat "$dep_path")"
  fi
done

# 4. Assemble the full prompt
STAGE_PROMPT="$(cat <<PROMPT
You are executing stage {stage_id} ({stage_name}) of epiphany-cogenius v1.0.0.
Session directory: {session_dir}.
Write your output to: {session_dir}stages/{output_file}

=== MODULE PROTOCOL ===
${MODULE_CONTENT}

=== KNOWLEDGE BASE SOURCES ===${KB_CONTENT}

=== INPUT DEPENDENCIES ===${INPUT_DEPS}

=== TASK ===
Follow the PROTOCOL in the module above exactly.
Read your input dependencies above as your stage inputs.
Use the knowledge base sources above as reference.
Write ONLY your stage output — no preamble, no commentary outside the protocol.
PROMPT
)"

# 5. Dispatch and capture output
echo "$STAGE_PROMPT" | ollama run "{resolved_model}" \
  > "{session_dir}stages/{output_file}"
```

`{kb_sources}` and `{input_dependencies}` are the arrays from the stage's
`index.json` entry. If a kb_source or dependency file is absent, emit
`[WARN] {stage_id}: kb_source/dependency not found — {path}` and continue
with an empty section rather than HALTing.

Capture stdout to the output file only. Stderr passes through to the user
as informational. If the output file is not written after dispatch, HALT
with the same message as the Claude subagent missing-output case.

---

### Confidence gate (after validate-stage.sh passes)

After `validate-stage.sh` confirms the output file is present and non-empty,
delegate to `confidence-gate.sh` — do not replicate its section-counting logic
inline:

```bash
gate_result=$(bash {skill_path}scripts/confidence-gate.sh \
  "{session_dir}" "{stage_id}" "$HAT" \
  --model-large  "{TIER_LARGE}" \
  --model-medium "{TIER_MEDIUM}" \
  --model-small  "{TIER_SMALL}")
gate_exit=$?
```

If `gate_exit` non-zero → HALT: `[HALT] {stage_id}: confidence-gate.sh configuration error.`

Parse `gate_result` (first word is the decision):

- **`PASS <fraction>`** — gate passed. `stage_status = "complete"`. Proceed to manifest update.
- **`ESCALATE <fraction> <model>`** — threshold not met; escalation model available.
  ```bash
  resolved_model="<model>"  # update to escalation model before manifest write
  ```
  Re-run the stage using `<model>` via the dispatch routing above. After re-run,
  **do not** apply the confidence gate again — accept output unconditionally.
  `stage_status = "escalated"`. The manifest entry will record the escalation model.
- **`ADVISORY <fraction>`** — threshold not met; no escalation tier available (hat is already
  at its highest model tier). confidence-gate.sh outputs this line when resolve-hat.sh returns
  an empty escalation model. Emit:
  `[ADVISORY] {stage_id} at max model tier. Confidence gate not met; output accepted with advisory.`
  Continue. `stage_status = "advisory"`.

---

### Manifest update (after gate, before next wave)

Append a stage entry to `{session_dir}manifest.json` after each stage
(including escalated re-runs). Use an atomic write (temp file + rename) to
prevent corruption when parallel-wave stages complete close together:

```bash
python3 -c "
import json, os, tempfile
path = '{session_dir}manifest.json'
with open(path) as f:
    m = json.load(f)
m['stages'].append({
    'stage_id': '{stage_id}',
    'hat': '$HAT',
    'resolved_model': '{resolved_model}',
    'status': '{stage_status}',
    'output_path': 'stages/{output_file}'
})
tmp = path + '.tmp'
with open(tmp, 'w') as f:
    json.dump(m, f, indent=2)
os.replace(tmp, path)
"
```

`stage_status` values: `complete` | `thin` | `empty` | `escalated` | `advisory`.
`resolved_model` is the model that produced the final accepted output (the
escalation model if escalation ran).

---

### All other STEP 5 logic

Per-wave headers, mode shift line, conditional module activation, parallel
wave spawning, validate-stage.sh invocation, completion lines, `S3_thin_or_empty`
signal handling (activates S3.1), `S6_no_alternatives` deferral, MINIMAL scale
conditional suppression — identical to epiphany-genius STEP 5. Apply hat
resolution and confidence gate to every stage, including conditionally-activated
stages.

---

## STEP 6 — V4 RETRY

Identical to epiphany-genius STEP 6 (Path A and Path B). When re-spawning
stages in retry paths, apply hat resolution before each spawn using the same
`{TIER_LARGE}`, `{TIER_MEDIUM}`, `{TIER_SMALL}` values established in STEP 0.
Update `manifest.json` for each re-spawned stage.

---

## STEP 7 — OUTPUT GENERATION

Follow the epiphany-genius STEP 7 sequence. Cogenius-specific additions:

**Output generation is mode-gated on `flag_xml`:**

**If `flag_xml` is NOT set — spawn the OSP subagent** (hat-route with `HAT="Synthesizer"`):

```bash
resolved_model=$(bash {skill_path}scripts/resolve-hat.sh "Synthesizer" \
  --model-large  "{TIER_LARGE}" \
  --model-medium "{TIER_MEDIUM}" \
  --model-small  "{TIER_SMALL}")
```

Then spawn the OSP subagent. For Claude models:

```
Agent({
  description: "Output Synthesis Pass",
  model: "{resolved_model}",
  prompt: "You are executing the Output Synthesis Pass (OSP) of epiphany-cogenius v1.0.0.
    Session directory: {session_dir}.
    KB base: {skill_path}kb/
    Module file: {skill_path}modules/output-synthesis-pass.md
    scale: {scale}
    flag_verbose: {flag_verbose}

    Instructions:
    1. Read your module file and follow its PROTOCOL exactly.
    2. Read all kb_sources listed in your module's frontmatter (from KB base).
    3. Read all input_dependencies listed in your module's frontmatter. Each path is
       relative to {session_dir} — e.g., `stages/S7-integration.md` resolves to
       `{session_dir}stages/S7-integration.md`.
    4. Read optional_dependencies if present (same path resolution; silently skip missing files).
    5. Use the scale and flag_verbose values above for length targets and section 13.
    6. Execute the OSP PROTOCOL.
    7. Write output to {session_dir}stages/output-distilled.md.
    8. Return: {stage_id: 'OSP', status: 'complete'|'thin'|'empty',
       summary: '[one sentence]', signals: []}"
})
```

For ollama models, use the same inline assembly pattern as STEP 5, adding
`scale: {scale}` and `flag_verbose: {flag_verbose}` lines to the TASK section.

Apply validate-stage.sh + confidence gate (via confidence-gate.sh with
`HAT="Synthesizer"`) to OSP output. Append OSP entry to manifest.json.

The S7 integration stage writes V1–V7 verification results inline in its
output file. The OSP reads these as input_dependencies when assembling the
distilled report.

Then write `report.md` as per epiphany-genius STEP 7.

**If `flag_xml` IS set — skip OSP entirely** (XML assembly handles output generation):

```bash
bash {skill_path}scripts/xml-assemble.sh {session_dir}
```

This reads manifest.json for hat routing metadata and writes
`{session_dir}stages/output.xml`. On failure:
`[HALT] xml-assemble.sh failed: {error}.`

---

## STEP 8 — SUMMARY LINE + SAVE

Identical to epiphany-genius STEP 8. No changes.

---

## STEP 9 — TESTING + OBSERVABILITY

Write observability fields to `stages/session.md` as per epiphany-genius STEP 9.

**Run the cogenius test suite:**

```bash
bash {skill_path}scripts/test-runner.sh \
  {session_dir} \
  {scale} \
  {active_conditionals_csv} \
  {output_mode}
```

- `{active_conditionals_csv}`: comma-separated list of activated conditional
  stage IDs (e.g., `S3.1` or `S3.1,S6.1`), or empty string if none activated.
- `{output_mode}`: `xml` if `flag_xml` is set, otherwise `distilled`.
- Output written to `{session_dir}stages/test-report.md`. Failures are
  printed but do not HALT (test failures are advisory at session end).

**Finalize `manifest.json`** (after test-runner.sh completes):

```bash
wall_seconds=$(( $(date +%s) - wall_start ))

python3 -c "
import json
with open('{session_dir}manifest.json') as f:
    m = json.load(f)
m['wall_seconds'] = $wall_seconds
m['spawns_total'] = $spawns_total
with open('{session_dir}manifest.json', 'w') as f:
    json.dump(m, f, indent=2)
"
```

These two fields are appended at the top level of manifest.json. All other
fields (`skill_version`, `session_id`, `flags`, `stages`) are written in
STEP 2 and updated incrementally in STEP 5; do not overwrite them.

---

## SESSION DIRECTORY LAYOUT

```
{session_dir}/
  manifest.json             ← WebUI API surface: skill_version, session_id,
  |                            flags{model_large,model_medium,model_small},
  |                            stages[{stage_id,hat,resolved_model,status,
  |                            output_path}], wall_seconds, spawns_total
  input.md                  ← Preserved input (written unconditionally)
  report.md                 ← Final distilled report (or report.xml)
  stages/
    session.md              ← Observability: spawns, wall_time, flags, signals
    00-processed-input.md
    S1-state-loading.md
    S2-constraint-escape.md
    S3-peripheral-exploration.md
    S3-1-defixation.md      ← conditional (Explorer hat)
    S4-dynamic-simulation.md
    S5-precision-forcing.md
    S6-falsification.md
    S6-1-conjecture.md      ← conditional (Explorer hat)
    S7-integration.md
    output-distilled.md     ← OSP output (Synthesizer hat)
    test-report.md          ← T1-T6 test results (cogenius)
    validation-log.md       ← Per-stage PASS/WARN/FAIL log (written by validate-stage.sh)
    S7-v6-scope.txt         ← V6 verbatim scope carve-out (written by S7 subagent)
    output.xml              ← XML assembly output (if --xml flag set)
```

`manifest.json` is the WebUI API surface. Future webui consumers read it for
model configuration display and progress tracking. Design constraint: all
values in manifest.json are scalar strings, numbers, or arrays of scalars.
No nested objects beyond one level.

---

## ERROR FORMAT

```
[HALT]     S[N] [Stage Name]: [reason]. [Action.]
[WARN]     S[N] [Stage Name]: [reason]. (advisory; proceeding)
[ADVISORY] [message]. (accepted; continuing)
```

HALT stops execution. WARN and ADVISORY log and continue.

Examples:
```
[HALT] S1 State Loading: model resolution failed. Check resolve-hat.sh stderr.
[HALT] S6 Falsification Engine: subagent returned without writing output file. Re-run session.
[WARN] S3 Peripheral Exploration: context budget 900 lines, actual 1200 — reasoning may degrade.
[ADVISORY] S6 Falsification Engine at max model tier. Confidence gate not met; output accepted with advisory.
```

---

## QUICK REFERENCE

### Stage-to-hat mapping

| Stage | Hat | Default Tier | Default Model |
|-------|-----|-------------|--------------|
| S1 State Loading | Enumerator | model-medium | claude-sonnet-4-6 |
| S2 Constraint Escape | Explorer | model-medium | claude-sonnet-4-6 |
| S3 Peripheral Exploration | Explorer | model-medium | claude-sonnet-4-6 |
| S3.1 De-fixation | Explorer | model-medium | claude-sonnet-4-6 |
| S4 Dynamic Simulation | Simulator | model-medium | claude-sonnet-4-6 |
| S5 Precision Forcing | Precision | model-medium | claude-sonnet-4-6 |
| S6 Falsification Engine | Adversary | model-large | claude-opus-4-7 |
| S6.1 Conjecture | Explorer | model-medium | claude-sonnet-4-6 |
| S7 Integration & Verify | Synthesizer | model-medium | claude-sonnet-4-6 |
| OSP | Synthesizer | model-medium | claude-sonnet-4-6 |

### Scales and stages (inherited from epiphany-genius)

| Stage | MINIMAL | STANDARD | DEEP | CONJECTURE |
|-------|:-------:|:--------:|:----:|:----------:|
| S1 | ✓ | ✓ | ✓ | ✓ |
| S2 | — | ✓ | ✓ | — |
| S3 | — | ✓ | ✓ | — |
| S3.1 (cond.) | — | cond. | cond. | — |
| S4 | — | — | ✓ | — |
| S5 | ✓ | ✓ | ✓ | — |
| S6 | — | ✓ | ✓ | — |
| S6.1 (cond.) | — | — | — | ✓ |
| S7 | ✓ | ✓ | ✓ | ✓ |
| OSP | ✓ | ✓ | ✓ | ✓ |
