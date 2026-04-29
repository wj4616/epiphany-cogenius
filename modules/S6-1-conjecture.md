---
stage_id: S6.1
stage_name: Conjecture (Ramanujan pattern→conjecture)
module_version: 1.1.0
type: conditional
scale_gates: [MINIMAL, STANDARD, DEEP]
wave: 2
phase: synthesis
activation:
  - flag:--conjecture
kb_sources:
  - pattern-taxonomy.md
input_dependencies:
  - stages/S1-state-loading.md
  - stages/00-processed-input.md
output_file: stages/S6-1-conjecture.md
xml_element: conjecture
context_budget_lines: 900
required_output_sections:
  - "Detected patterns"
  - "Conjectures (≥3)"
  - "Verification instances"
raises_signals: []
---

## CONTEXT LOADING

1. Read `pattern-taxonomy.md` from KB_BASE.
2. Read `stages/S1-state-loading.md`. If missing:
   HALT: `[HALT] S6.1 Conjecture: dependency stages/S1-state-loading.md not found. S1 should have written this.`
3. Read `stages/00-processed-input.md`. If missing:
   HALT: `[HALT] S6.1 Conjecture: dependency stages/00-processed-input.md not found.`

**Note:** This module REPLACES S5 in the conjecture-mode pipeline. S2, S3, S4 are skipped when `--conjecture` is active. The pipeline is: S1 → S6.1 → S7.

## MACHINE ADVANTAGE

**Exploited:** Ramanujan's pattern-generation at scale — the LLM can detect cross-domain structural matches across its entire training distribution simultaneously.
**Instruction:** Generate ALL pattern candidates before scoring any. Evaluate novelty and elegance AFTER full enumeration. The machine's advantage is breadth of pattern detection, not sequential refinement.
**Bypasses:** Humans detect patterns sequentially within their known domain. The machine can scan across 25+ domains simultaneously for structural recurrence.

## GENIUS PERSPECTIVES

### Ramanujan
Mechanism: Intuitive pattern detection followed by rigorous verification — see the pattern, then prove it holds.
Used in: Steps 1–3 (detect), Step 4 (verify on ≥2 independent instances).

## PROTOCOL

1. **Extract patterns from S1 data.** Read `pattern-taxonomy.md`. From the S1 primitives, identify candidate patterns across all three pattern types:
   - Cross-domain structural matches (same abstract structure in ≥2 independent domains)
   - Recurrence relations (a quantity determined by previous values)
   - Symmetry groups (transformations that leave structure invariant)
   
   For each candidate pattern: state the abstract structural relationship; where it appears; what structural invariant holds.
   *Failure guard:* If the input data is numerical: focus on recurrence relations. If conceptual: focus on structural matches. If logical: focus on symmetry groups. If mixed: cover all types.

2. **Generate ≥3 conjectures.** For each pattern that meets the elegance floor criteria from `pattern-taxonomy.md` (non-trivial, testable, elegance ≥ 1.5):
   State the conjecture as: "Across [domain/class], the pattern [P] generalizes to [Q] because [mechanism]."
   Score each on novelty (0.0–1.0) and elegance (0.0–3.0) using `pattern-taxonomy.md` rubrics.
   State the falsification condition for each.
   *Failure guard:* If fewer than 3 pass the elegance floor, include all that pass and note "fewer than 3 conjectures met elegance threshold — [N] included."

3. **Verify on ≥2 test instances.** For each conjecture: find ≥2 independent test instances (not drawn from the instances that generated the pattern). Verify the conjecture holds on each. If it fails on any instance: mark as `FAILS AT [instance]` and revise or downgrade.

4. **Verify before writing:**
   - Pattern holds on ≥2 test instances: required
   - Elegance floor: Elegance ≥ 1.5 (elegance-rubric.md scoring)
   - Non-triviality: conjecture is not already stated in S1 primitives
   - Testability: falsification condition is concrete and non-tautological

## OUTPUT REQUIREMENTS

**XML element:** `<conjecture>` with sub-elements `<detected_patterns>`, `<conjectures>` (each with novelty, elegance, falsification_condition, verification_instances), `<conjecture_count>`.

**Section header rule:** Each required_output_sections string must appear verbatim as a `##` markdown header in the output. The validator performs case-sensitive exact-string matching. Use XML sub-elements for structure AND `##` headers inside each element:
- `## Detected patterns` — first line inside `<detected_patterns>`
- `## Conjectures (≥3)` — first line inside `<conjectures>`
- `## Verification instances` — inside `<conjectures>`, after the individual conjecture entries (summarizing test-instance results across all conjectures)

**Required output sections:** as listed in frontmatter.

**Empty marker:**
- If not activated (`--conjecture` not set): `<conjecture/>` — distilled output: `*(Stage S6.1 not activated — condition flag:--conjecture not met.)*`
- If activated but no patterns meet elegance floor: `*(Stage S6.1 ran, no content found — reason: no patterns above elegance floor found.)*`

**Note re: `--conjecture` + non-data input:** If input lacks concrete instances for pattern detection, S6.1 Verifier step will flag thin pattern extraction; record count as 0 in `<conjecture_count>`; emit advisory.

## SIGNALS

None raised. Output consumed by S7.
