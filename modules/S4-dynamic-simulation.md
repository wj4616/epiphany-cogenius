---
stage_id: S4
stage_name: Dynamic Simulation
module_version: 1.1.0
type: core
scale_gates: [DEEP]
wave: 3
phase: ideation
activation:
  - scale:DEEP
kb_sources:
  - observer-frames.md
  - simulation-checklist.md
input_dependencies:
  - stages/S1-state-loading.md
  - stages/00-processed-input.md
output_file: stages/S4-dynamic-simulation.md
xml_element: dynamic_simulation
context_budget_lines: 900
required_output_sections:
  - "System model"
  - "Observer frame analyses"
  - "Imbalances"
  - "Singularities"
  - "Limit cases"
  - "Theory collisions"
raises_signals: []
---

## CONTEXT LOADING

1. Read `observer-frames.md` and `simulation-checklist.md` from KB_BASE.
2. Read `stages/S1-state-loading.md`. If missing:
   HALT: `[HALT] S4 Dynamic Simulation: dependency stages/S1-state-loading.md not found. S1 should have written this.`
3. Read `stages/00-processed-input.md`. If missing:
   HALT: `[HALT] S4 Dynamic Simulation: dependency stages/00-processed-input.md not found.`

## MACHINE ADVANTAGE

**Exploited:** Full simultaneous embedding in multiple observer frames — all three frames operate in parallel, not sequentially.
**Instruction:** Construct all three observer frame analyses simultaneously. Do not complete Frame 1 before starting Frame 2.
**Bypasses:** Humans can hold one observer frame at a time; switching frame erases the prior frame's analysis. The machine maintains all frames in parallel and compares them directly.

## GENIUS PERSPECTIVES

### Tesla
Mechanism: Visualize the complete system operating; search for failure points before physical execution.
Used in: Steps 3–4 (simulation checklist — advance state, flag imbalances, singularities, limit cases).

### Einstein
Mechanism: Observer frame embedding — embed yourself in the system from multiple positions to reveal structure invisible from any single position.
Used in: Step 2 (≥3 observer frames applied).

## PROTOCOL

1. **Construct system model.** From S1 primitives: identify components, their initial states, driving forces, coupling between components, and nominal operating condition. State explicitly what "working correctly" means.
   *Failure guard:* If S1 primitives are too sparse to construct a system model, note this and construct a minimal model from the input alone.

2. **Embed in ≥3 observer frames.** Read `observer-frames.md`. Apply all three frames (Insider, Outsider, Measurement-Instrument) to the system model simultaneously. For each frame:
   - Narrative of what is visible from that position
   - At least one limit case for that frame
   - Cross-frame conflicts: where do two frames predict different behavior?
   *Failure guard:* If a frame produces nothing distinctive (everything is the same as another frame), document this as "frames X and Y produce identical analyses — possible indicator of over-abstraction."

3. **Run Tesla simulation.** Read `simulation-checklist.md`. Apply all four checklist categories in sequence:
   - Energy/resource imbalances
   - Singularities
   - Limit cases
   - Theory collisions
   Flag every occurrence using the `[IMBALANCE]`, `[SINGULARITY]`, `[LIMIT-CASE]`, `[COLLISION]` format from the checklist.
   *Failure guard:* If no flags are raised in any category, document "simulation: no structural failures found — either the system is well-designed or the model is underspecified."

4. **Collect theory collisions.** For each `[COLLISION]` flagged: produce the discriminating condition — the specific experimental or observational setup that would reveal which claim governs.
   *Failure guard:* If fewer than 2 theory collisions found at DEEP scale, this is a finding (input may be internally consistent) — note it and CONTINUE.
   *Deduplication:* Before writing, review all collected collisions. If two collisions share substantially identical discriminating conditions (same observable, same experimental setup), merge them into a single entry: retain both primitive source references but write one combined collision. Deduplication preserves evidentiary richness while eliminating redundant output.

5. **Verify:** Imbalance genuineness check from `simulation-checklist.md` for each flagged item:
   - Is the failure structural (inherent to the design) or incidental (artifact of framing)?
   - Downgrade incidental failures to advisory.

## OUTPUT REQUIREMENTS

**XML element:** `<dynamic_simulation>` with sub-elements `<system_model>`, `<observer_frames>`, `<imbalances>`, `<singularities>`, `<limit_cases>`, `<theory_collisions>`.

**Section header rule:** Each required_output_sections string must appear verbatim as a `##` markdown header in the output. The validator performs case-sensitive exact-string matching. Use XML sub-elements for structure AND `##` headers inside each element:
- `## System model` — first line inside `<system_model>`
- `## Observer frame analyses` — first line inside `<observer_frames>`
- `## Imbalances` — first line inside `<imbalances>`
- `## Singularities` — first line inside `<singularities>`
- `## Limit cases` — first line inside `<limit_cases>`
- `## Theory collisions` — first line inside `<theory_collisions>`

**Required output sections:** as listed in frontmatter.

**Empty marker:**
- At MINIMAL/STANDARD: `<dynamic_simulation/>` — and in distilled output: `*(Stage S4 skipped at STANDARD scale — run DEEP for this section.)*`
- If ran but found nothing structural: `*(Stage S4 ran, no content found — reason: no structural failures found; system model may be underspecified.)*`

## SIGNALS

None raised. S4 output is consumed by S7.
