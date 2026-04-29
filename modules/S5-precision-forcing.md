---
stage_id: S5
stage_name: Precision Forcing
module_version: 1.1.0
type: core
scale_gates: [MINIMAL, STANDARD, DEEP]
wave: 4
phase: synthesis
activation:
  - always
kb_sources:
  - vocabulary-rubric.md
  - forward-chain-template.md
input_dependencies:
  - stages/00-processed-input.md
  - stages/S1-state-loading.md
output_file: stages/S5-precision-forcing.md
xml_element: precision_forcing
context_budget_lines: 1100
required_output_sections:
  - "5-level vocabulary stripping"
  - "3-representation rendering"
  - "Constructive specification"
  - "Flagged vague claims"
  - "Forward-chain consequence tree"
raises_signals: []
---

## CONTEXT LOADING

1. Read `vocabulary-rubric.md` and `forward-chain-template.md` from KB_BASE.
2. Read `stages/00-processed-input.md`. If missing:
   HALT: `[HALT] S5 Precision Forcing: dependency stages/00-processed-input.md not found.`
3. Read `stages/S1-state-loading.md` for context on primitive categories.

## MACHINE ADVANTAGE

**Exploited:** Simultaneous rendering across 3+ representations AND parallel consequence-tree search.
**Instruction:** Generate all 5 vocabulary levels simultaneously. Generate the 3 representations simultaneously. Generate all 10 consequence chains simultaneously.
**Bypasses:** Humans translate to one vocabulary level at a time; the machine exposes which elements survive all 5 levels vs. which collapse — this differential is the diagnostic.

## GENIUS PERSPECTIVES

### Feynman
Mechanism: Jargon removal as diagnostic — if you cannot state it without jargon, you don't yet understand it.
Used in: Step 1 (5-level vocabulary stripping, especially Level 1 five-year-old test).

### Da Vinci
Mechanism: Multi-representation — diagram + equation + procedural description expose different aspects.
Used in: Step 2 (3-representation rendering).

### Turing
Mechanism: Constructive specification — define the minimal computational object that would demonstrate the claim.
Used in: Steps 3 and 1 Level 4 (formal + constructive).

### Von Neumann
Mechanism: Ten-steps-ahead derivation — forward chain all consequences before committing to a direction.
Used in: Step 5 (forward-chain preview, 10 parallel consequence chains).

## PROTOCOL

1. **5-level vocabulary stripping.** Read `vocabulary-rubric.md`. Identify the primary claim to be analyzed (from S1 stripped irreducibles or directly from input). Produce all 5 levels simultaneously:
   - Level 1: Five-year-old (everyday words only)
   - Level 2: Fifteen-year-old (general literacy terms)
   - Level 3: Domain expert (full technical vocabulary)
   - Level 4: Mathematician/logician (formal notation, quantifiers)
   - Level 5: Minimal symbol (equation / diagram description / ≤5-line pseudocode)
   *Failure guard:* If a level cannot be produced, this is diagnostic information — note "Level [N]: cannot be stated in this vocabulary; reason: [X]" — this flags a vague claim candidate.

2. **3-representation rendering.** Produce the same claim in 3 representations (Da Vinci):
   - Diagram description (spatial/visual)
   - Equation or formal expression
   - Procedural description (steps to verify)
   *Failure guard:* If a representation does not apply (e.g., diagram is not meaningful for a purely logical claim), state why.

3. **Constructive specification.** Turing minimal-model: state the minimal object, procedure, or test that would demonstrate the claim is true. Format: "An agent that [minimal action sequence] and produces [observable outcome] constitutes a demonstration."
   Then: minimal-model check — can any element be removed while leaving the demonstration valid? Remove it.
   *Failure guard:* If no constructive spec can be written (purely abstract claim), flag as potential V5 issue.

4. **Flag vague claims.** From the vagueness detection protocol in `vocabulary-rubric.md`: identify any elements that survive Levels 1–3 but collapse to tautology or empty statement at Level 4 or 5.
   Format: `[VAGUE] "[phrase]" — Reason: [X] — Possible resolution: [what must be specified?]`

5. **Forward-chain consequence tree.** Read `forward-chain-template.md`. Use the constructive spec (Step 3) as the root node. Generate 10 parallel consequence chains of depth 3–5. Apply flag conditions: `[CONTRADICTION]`, `[PATHOLOGICAL]`, `[DEGENERATE]` for any identified cases.
   *Failure guard:* If fewer than 10 branches can be generated (degenerate input), generate all available; note the count.

6. **Verify before writing:**
   - Constructive-test: is the spec in Step 3 fully determinate (no ambiguity about what counts as a demonstration)?
   - Minimal-model check: is anything eliminable?
   - Jargon-purge residue: does any Level 1/2 phrasing still contain unexplained technical terms?

## OUTPUT REQUIREMENTS

**XML element:** `<precision_forcing>` with sub-elements `<renderings>`, `<constructive_specification>`, `<flagged_vagueness>`, `<forward_chain>`.

**Section header rule:** Each required_output_sections string must appear verbatim as a `##` markdown header in the output. The validator performs case-sensitive exact-string matching. Use XML sub-elements for structure AND `##` headers inside each element:
- `## 5-level vocabulary stripping` — first line inside `<renderings>` (before the 5-level content)
- `## 3-representation rendering` — second header inside `<renderings>` (before the representation content)
- `## Constructive specification` — first line inside `<constructive_specification>`
- `## Flagged vague claims` — first line inside `<flagged_vagueness>`
- `## Forward-chain consequence tree` — first line inside `<forward_chain>`

**Required output sections:** as listed in frontmatter.

**Empty marker:**
- `<forward_chain/>` only if S5 returned thin (no constructive spec possible).
- Full element always present at MINIMAL/STANDARD/DEEP.

## SIGNALS

None raised.
