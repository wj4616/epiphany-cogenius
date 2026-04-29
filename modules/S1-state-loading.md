---
stage_id: S1
stage_name: State Loading
module_version: 1.1.0
type: core
scale_gates: [MINIMAL, STANDARD, DEEP]
wave: 1
phase: ideation
activation:
  - always
kb_sources:
  - input-preloading-templates.md
input_dependencies:
  - stages/00-processed-input.md
output_file: stages/S1-state-loading.md
xml_element: state_loading
context_budget_lines: 800
required_output_sections:
  - "Input class"
  - "Primitives"
  - "Simplicity-stripped irreducibles"
  - "Tesla measurement plan"
  - "Verification"
raises_signals: []
---

## CONTEXT LOADING

1. Read `input-preloading-templates.md` from KB_BASE (`~/.claude/skills/epiphany-cogenius/kb/`).
2. Read `stages/00-processed-input.md`. If missing:
   HALT: `[HALT] S1 State Loading: dependency stages/00-processed-input.md not found. Input router (STEP 3) should have written this.`

## MACHINE ADVANTAGE

**Exploited:** Unbounded working memory — enumerate all primitives in parallel with no compression, no omission.
**Instruction:** Generate ALL primitive categories simultaneously. Do not sequentially build — produce the complete enumeration in a single pass. Mark dependencies as you enumerate, not afterward.
**Bypasses:** Humans enumerate primitives sequentially, compress after a few items, and unconsciously omit primitives that don't immediately seem relevant. The machine can hold the full set without compression.

## GENIUS PERSPECTIVES

### Einstein
Mechanism: Reduce the problem to its irreducible primitives before attempting any solution.
Used in: Steps 3 (simplicity stripping) and 2 (full enumeration before filtering).

### Feynman
Mechanism: The first test of understanding is whether you can state what you know without jargon.
Used in: Step 2 (enumeration forces explicit statement of each primitive).

### Turing
Mechanism: Constructive specification — state what an observable success would produce.
Used in: Step 4 (Tesla measurement plan).

### Tesla
Mechanism: Pre-sketch the complete system behavior before physical execution; identify measurable success.
Used in: Step 4 (measurement plan).

### Von Neumann
Mechanism: Working memory exploitation — hold more than the human limit simultaneously.
Used in: Step 2 (≥20 per category, parallel enumeration).

### Darwin
Mechanism: Evidence accumulation — systematic collection of facts before hypothesis generation.
Used in: Step 2 (enumeration precedes all later ideation).

## PROTOCOL

1. **Detect input class.** Read `00-processed-input.md`. Determine which of the 5 classes applies: algorithmic / design / proof / diagnostic / other. If ambiguous: pick the dominant class, note the ambiguity.
   *Failure guard:* If truly unclassifiable, use Template 5 (Other) and note "class detection uncertain."

2. **Enumerate primitives.** Read the matching template from `input-preloading-templates.md`. For each category in the template, enumerate ≥20 primitives from the input. If fewer than 20 genuinely exist, state the cap explicitly: "Input contains [N] [category] primitives; 20-item target not reached — constraint is the input."
   Do NOT fabricate primitives to meet the count.
   *Failure guard:* If a category yields 0 items, record "category [X]: no content found in input" — this is a valid finding.

3. **Simplicity stripping.** Apply the simplicity-stripping protocol from the template:
   - Remove all scaffolding: framing language, transitional phrases, meta-commentary
   - Keep irreducibles: facts, constraints, unknowns that cannot be derived from other listed primitives
   - Mark dependency chains: if primitive B follows from primitive A, strike B and note "B derives from A"
   *Failure guard:* If all primitives survive stripping (no dependencies found), note "no derivation chains found — all primitives irreducible."

4. **Tesla measurement plan.** State what an observable success would measure — specific, concrete, verifiable. Use the measurement plan format from the template:
   "Success is observable when [agent/process] performs [specific action] and produces [specific measurable outcome]."
   *Failure guard:* If no measurable outcome can be specified, write "Tesla measurement: no concrete observable identified — input may be purely conceptual; note as V5 constructive-test risk."

5. **Verify before writing:**
   - Preparation-gate: every primitive listed is either cited to the input or declared an assumption
   - Tesla constructive-test: the measurement plan specifies a concrete observable
   - Count check: ≥20 per category or explicit count-cap declared
   If any gate fails: revise the relevant section before writing output.

## OUTPUT REQUIREMENTS

**XML element:** `<state_loading>` with sub-elements `<input_class>`, `<primitives>` (categories with items), `<stripped_irreducibles>`, `<tesla_measurement_plan>`, `<verification_block>`.

**Section header rule:** Each required_output_sections string must appear verbatim as a `##` markdown header in the output. The validator performs case-sensitive exact-string matching. Use XML sub-elements for structure AND `##` headers inside each element:
- `## Input class` — first line inside `<input_class>`
- `## Primitives` — first line inside `<primitives>`
- `## Simplicity-stripped irreducibles` — first line inside `<stripped_irreducibles>`
- `## Tesla measurement plan` — first line inside `<tesla_measurement_plan>`
- `## Verification` — first line inside `<verification_block>`

**Required output sections:** Input class · Primitives (by category, ≥20 each or count-cap declared) · Simplicity-stripped irreducibles · Tesla measurement plan · Verification.

**Empty marker:** `<state_loading/>` only if S1 was not run (should not occur — S1 runs at all scales).

**Thin-output rule:** If the input contains so little content that enumeration cannot exceed 5 items per category: emit the exact string `ran, content minimal — [N] primitives extracted across all categories` as a note (the test runner greps for this phrase to emit the S1 low-confidence advisory in T3 reports), and CONTINUE.

Downstream consequences of thin S1:
- test-runner.sh emits `ADVISORY: S1 detected minimal input content — confidence should be read as LOW regardless of S7 band; downstream reasoning has limited evidentiary base.`
- S7's V5 constructive gate will not receive enough primitives for strong constructability — this is expected, not a bug.
- OSP confidence band should be read against the advisory, not in isolation.

## SIGNALS

None raised. S1 is the first stage in every pipeline; it has no downstream conditional it can activate directly. Thin/empty status is noted in return status but does not trigger a conditional module — downstream awareness is conveyed via the thin-output note (which test-runner.sh surfaces as an advisory in STEP 9).
