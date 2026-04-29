---
stage_id: S3
stage_name: Peripheral Exploration
module_version: 1.1.0
type: core
scale_gates: [STANDARD, DEEP]
wave: 2
phase: ideation
activation:
  - always
kb_sources:
  - spreading-activation.md
  - elegance-rubric.md
input_dependencies:
  - stages/00-processed-input.md
output_file: stages/S3-peripheral-exploration.md
xml_element: peripheral_exploration
context_budget_lines: 1000
required_output_sections:
  - "Activation map"
  - "Convergent nodes"
  - "Selected illuminations"
  - "Verification"
raises_signals:
  - S3_thin_or_empty
---

## CONTEXT LOADING

1. Read `spreading-activation.md` and `elegance-rubric.md` from KB_BASE.
2. Read `stages/00-processed-input.md`. If missing:
   HALT: `[HALT] S3 Peripheral Exploration: dependency stages/00-processed-input.md not found.`

## MACHINE ADVANTAGE

**Exploited:** Direct and explicit spreading activation — the LLM already performs this implicitly via attention; S3 makes the activation map the explicit artifact.
**Instruction:** Do not filter or evaluate during propagation. Enumerate the full activation cloud — weak associations included. Mark convergent nodes AFTER full propagation, not during.
**Bypasses:** Human spreading activation is bounded by working memory — only the highest-activation nodes break into consciousness. The machine can traverse the full cloud including nodes that never reach human threshold.

## GENIUS PERSPECTIVES

### Poincaré
Mechanism: Incubation — remote associations form when the problem is approached indirectly.
Used in: Steps 1–3 (explicit traversal of the indirect association network).

### Darwin
Mechanism: Evidence accumulation from unexpected sources; independence of evidence paths.
Used in: Step 4 (Darwin independence check — convergent sources must be genuinely independent).

### Da Vinci
Mechanism: Cross-domain observation — patterns visible only when looking across domain boundaries.
Used in: Step 2 (the activation map crosses domain boundaries).

### Ramanujan
Mechanism: Pattern verification — a pattern is real only if it holds on multiple independent test instances.
Used in: Step 5 verification (selected patterns verified on ≥2 instances).

## PROTOCOL

1. **Seed activation.** Extract all primitives from `00-processed-input.md`. Assign each primitive `a = 1.0` (initial seed). List the seeds explicitly.
   *Failure guard:* If fewer than 3 seeds can be identified, S3 will have low-convergence output — note this; CONTINUE.

2. **Propagate via Collins & Loftus update equation.** Use the formula from `spreading-activation.md`:
   ```
   a(node, t+1) = max(a(node,t), decay · Σ w_ij · a(neighbor, t))
   ```
   Propagate for 3–5 steps. For each propagation step: enumerate newly activated nodes. Log the explicit activation map — list each activated node, its activation value, and which source(s) activated it.
   Do NOT filter for relevance during this step. Include weak and unexpected associations.
   *Failure guard:* If activation spreads only within the original domain (no cross-domain nodes), explicitly note this as a finding.

3. **Apply lateral inhibition.** Using the lateral inhibition formula from `spreading-activation.md`: suppress weaker competing activations when two nodes share >70% of activation source paths. Log any suppressed nodes.
   *Failure guard:* If no suppressions occur (all nodes have distinct activation paths), note "no lateral inhibition applied."

4. **Mark convergent nodes.** Apply convergent-node detection from `spreading-activation.md`: any node activated from ≥2 independent source chains and with `a(node) ≥ 0.4` after propagation. Mark provenance: `[multi-source-convergent: seed_A + seed_B]`.
   *Failure guard:* If <2 convergent nodes found → proceed to Step 6 and raise S3_thin_or_empty signal after writing output.

5. **Rank and select.** Score each convergent node: `score = a(node) × elegance_score` using `elegance-rubric.md`. Select top 3–5 by combined score. For each selected node, produce an "illumination": the insight or connection it represents.
   Also include any emergent-structure bridges from S2 Step 7 blend (if present in input context).
   *Failure guard:* If fewer than 3 convergent nodes available, select all that exist; note count.

6. **Verify before writing:**
   - Darwin independence check: are the 2+ source chains genuinely independent (no shared ancestor within the activation radius)?
   - Ramanujan pattern-verification: does each selected illumination pattern hold on ≥2 test instances?
   - Activation-map completeness: does the map include at least 15 distinct nodes (seeds + propagated)?

## OUTPUT REQUIREMENTS

**XML element:** `<peripheral_exploration>` with sub-elements `<activation_map>`, `<activation_provenance>`, `<convergent_nodes>`, `<selected_illuminations>`.

**Section header rule:** Each required_output_sections string must appear verbatim as a `##` markdown header in the output. The validator performs case-sensitive exact-string matching. Use XML sub-elements for structure AND `##` headers inside each element:
- `## Activation map` — first line inside `<activation_map>`
- `## Convergent nodes` — first line inside `<convergent_nodes>`
- `## Selected illuminations` — first line inside `<selected_illuminations>`
- `## Verification` — as a standalone section after the XML elements (for Darwin independence check and Ramanujan pattern-verification from Step 6)

**Required output sections:** as listed in frontmatter.

**Empty marker:**
- If genuinely no convergent nodes after full propagation: emit `*(Stage S3 ran, no content found — reason: no convergent activations found across 20+ node activation cloud.)*`

## SIGNALS

If <2 convergent nodes survive Steps 4–5 (including after lateral inhibition): emit `status: thin` in return status with signal `S3_thin_or_empty`. This activates S3.1 de-fixation module.

Note: Raise the signal AFTER writing the stage output. The output documents what was found; the signal triggers the next action.
