---
stage_id: S6
stage_name: Falsification Engine
module_version: 1.1.0
type: core
scale_gates: [STANDARD, DEEP]
wave: 4
phase: synthesis
activation:
  - always
kb_sources:
  - tot-templates.md
  - falsification-checklists.md
input_dependencies:
  - stages/S3-peripheral-exploration.md
  - stages/00-processed-input.md
  - stages/S1-state-loading.md
optional_dependencies:
  - stages/S3-1-defixation.md
output_file: stages/S6-falsification.md
xml_element: falsification
context_budget_lines: 1500
required_output_sections:
  - "Abductive mode results"
  - "Deductive mode results"
  - "Inductive mode results"
  - "Consolidated hypotheses"
  - "Extreme scenarios"
  - "Millikan assessment"
  - "Density report"
raises_signals:
  - S6_no_alternatives
---

## CONTEXT LOADING

1. Read `tot-templates.md` and `falsification-checklists.md` from KB_BASE.
2. Read `stages/S3-peripheral-exploration.md`. If missing:
   HALT: `[HALT] S6 Falsification: dependency stages/S3-peripheral-exploration.md not found. S3 should have written this.`
3. Read `stages/00-processed-input.md`. If missing:
   HALT: `[HALT] S6 Falsification: dependency stages/00-processed-input.md not found.`
4. Read `stages/S1-state-loading.md`. If missing:
   HALT: `[HALT] S6 Falsification: dependency stages/S1-state-loading.md not found. S1 should have written this.`
5. S5 note: S5 and S6 run in the same wave at all scales (Wave 4), so `stages/S5-precision-forcing.md` will never exist when S6 starts. Always use S1 primitives for the deductive mode input. Do not attempt to read S5.
6. Read `stages/S3-1-defixation.md` if present (optional — S3.1 runs before S6 when S3 was thin/empty). If present: use its breakthrough candidate as an additional seed for all three inference modes — treat it as a new problem-space representation alongside S3's concepts. Note in each inference mode output which candidate(s) derive from S3.1.

## MACHINE ADVANTAGE

**Exploited:** 3 parallel inference modes (abductive, deductive, inductive) as separate sub-subagents; Bayesian consolidation.
**Instruction:** Spawn exactly 3 sub-subagents via Agent tool in a SINGLE message (one per inference mode), then a 4th consolidator after all three complete. The three mode agents are independent — no communication between them until the consolidator step.
**Bypasses:** Humans apply one inference mode at a time and anchor to the first plausible result. The machine generates the full space of hypotheses from all three modes before selecting.

## GENIUS PERSPECTIVES

### Einstein
Mechanism: Extreme-scenario construction — test under boundary regimes.
Used in: Step 3 (extreme scenarios from falsification-checklists.md).

### Feynman
Mechanism: Differential-effort detection (Millikan test) — notice when reasoning works harder to protect one hypothesis.
Used in: Step 4.

### Darwin
Mechanism: Golden-rule disconfirming-evidence search — actively seek what would defeat the conclusion.
Used in: Step 5.

### Turing
Mechanism: Formal consequence testing — if the claim implies X, does X hold?
Used in: Deductive mode (Step 1b).

## PROTOCOL

1. **Spawn 3 parallel inference mode sub-subagents.** Read `tot-templates.md`. Using the Agent tool, send ONE message containing THREE parallel Agent calls:

   **Agent call A — Abductive mode:** Follow the Abductive Inference template from `tot-templates.md`. Produce ≥5 candidate explanations scored on parsimony, explanatory power, uberty, testability. Return top 3.

   **Agent call B — Deductive mode:** Follow the Deductive Inference template from `tot-templates.md`. Derive consequences from S1 + S5 premises. Flag contradictions. Return alternative hypotheses from flagged premises.

   **Agent call C — Inductive mode:** Follow the Inductive Inference template from `tot-templates.md`. Generate ≥3 generalizations from observed instances. Test boundary cases. Return alternatives from failed generalizations.

   Wait for all three to complete.

2. **Spawn consolidator sub-subagent.** Follow the Consolidator template from `tot-templates.md`. Collect all candidates from A, B, C. Deduplicate. Cross-mode validate. Assign NLI confidence scores. Produce final ranked list of ≥3 distinct alternatives.
   *If consolidator returns count == 0:* emit signal `S6_no_alternatives` in return status.

3. **Apply extreme scenarios.** Read `falsification-checklists.md` Checklist 1. Test the primary conclusion candidate (from consolidation or from prior stages) at ≥8 boundary regimes. Record each regime result.

4. **Apply Millikan test.** Read `falsification-checklists.md` Checklist 2. For each alternative hypothesis and the primary conclusion: measure differential effort. Flag asymmetries.

5. **Apply Darwin's golden rule.** Read `falsification-checklists.md` Checklist 3. Actively search for counter-examples, failure classes, strongest objections, mechanism gaps. Produce density report.

6. **Verify before writing:**
   - Density check: density report must be HIGH (≥5 disconfirming items) or MEDIUM (3–4). If LOW: add `ADVISORY: low disconfirmation density — search may not have been aggressive enough.`
   - Cargo-cult scan: inspect reasoning for patterns that look like falsification but don't challenge. Replace or flag.
   - Count check: ≥3 rival alternatives in consolidated output.
   *Failure guard:* If <3 alternatives: note as advisory (not failure); continue.
   - Threshold gate: in the written output, condense any candidate with combined score < 0.50 to a single line: `H-[N] — [name]: combined score [X.XX] — below development threshold, reasoning used for consolidation only.` Do NOT write full parsimony/explanatory/uberty/testability breakdown for below-threshold candidates. Their reasoning was useful for consolidation; it does not belong in the written output.

## OUTPUT REQUIREMENTS

**XML element:** `<falsification>` with sub-elements `<inference_modes>` (containing `<abductive>`, `<deductive>`, `<inductive>`), `<consolidated_hypotheses>`, `<extreme_scenarios>`, `<millikan_assessment>`, `<density_report>`.

**Section header rule:** Each required_output_sections string must appear verbatim as a `##` markdown header in the output. The validator performs case-sensitive exact-string matching. Use XML sub-elements for structure AND `##` headers inside each element:
- `## Abductive mode results` — first line inside `<abductive>`
- `## Deductive mode results` — first line inside `<deductive>`
- `## Inductive mode results` — first line inside `<inductive>`
- `## Consolidated hypotheses` — first line inside `<consolidated_hypotheses>`
- `## Extreme scenarios` — first line inside `<extreme_scenarios>`
- `## Millikan assessment` — first line inside `<millikan_assessment>`
- `## Density report` — first line inside `<density_report>`

**Scale gate in output frontmatter:** Write `scale_gate: [the scale from stages/session.md]` — read the `scale:` field from the session manifest, do NOT use this module's `scale_gates` array minimum.

**Required output sections:** as listed in frontmatter.

**Advisory (not failure):** If consolidated_hypotheses count < 3: `ADVISORY: S6 produced [N]/3 alternative hypotheses — re-run with --xml to inspect full S6 raw state for coverage gaps.`

## SIGNALS

If consolidator returns 0 alternatives after deduplication: emit `S6_no_alternatives` in return status.
This activates S3.1 (if not already run) and triggers one V4 retry loop (S3.1 → S6 re-spawn → S7 re-spawn).
