---
stage_id: S3.1
stage_name: Representational Change (de-fixation)
module_version: 1.1.0
type: conditional
scale_gates: [STANDARD, DEEP]
wave: "Nb"
phase: ideation
activation:
  - condition:S3_thin_or_empty
  - condition:S6_no_alternatives
kb_sources:
  - ohlsson-defixation.md
input_dependencies:
  - stages/S3-peripheral-exploration.md
  - stages/00-processed-input.md
output_file: stages/S3-1-defixation.md
xml_element: representational_change
context_budget_lines: 700
required_output_sections:
  - "Constraint relaxations"
  - "Chunk decompositions"
  - "Re-encodings"
  - "Selected breakthrough candidate"
  - "Residual fixation signals"
raises_signals: []
---

## TRIGGER SEMANTICS

S3.1 activates on one of two distinct signals — the protocol below runs
identically for both, but the **interpretation** of residual fixation and
the downstream consumer differ:

| Trigger | Raised by | Fires at | Meaning | Primary consumer |
|---------|-----------|----------|---------|------------------|
| `S3_thin_or_empty` | S3 | STEP 5 (inline conditional, wave N.b) | Spreading-activation found <2 convergent nodes. S3.1 attempts to unblock peripheral exploration. | S6 (uses new material for alternative hypotheses) and S7 (Representational Signals). |
| `S6_no_alternatives` | S6 | STEP 6 Path B (V4 retry) | Falsification engine produced 0 alternative hypotheses. S3.1 attempts to break the hypothesis-space fixation. | S6 (re-run with S3.1 input) and S7 (re-run with new S6). |

**If both triggers occur in the same session:** S3.1 runs only once (inline,
from `S3_thin_or_empty`). STEP 6 Path B detects S3.1 has already run and
skips the retry — see SKILL.md STEP 6.

**Interpretation difference:**
- Trigger A (S3_thin): primary goal is to produce convergent nodes S3 missed.
  Residual fixation means "S3's activation map was too narrow" and S3.1 output
  acts as a supplementary exploration layer.
- Trigger B (S6_no_alternatives): primary goal is to reframe the problem so
  that alternative hypotheses become visible. Residual fixation means "the
  hypothesis frame itself is Einstellung-locked" — a stronger de-fixation
  signal that downstream consumers should treat as a scope-limit indicator.

## CONTEXT LOADING

1. Read `ohlsson-defixation.md` from KB_BASE.
2. Read `stages/S3-peripheral-exploration.md`. If missing:
   HALT: `[HALT] S3.1 Representational Change: dependency stages/S3-peripheral-exploration.md not found. S3 should have written this.`
3. Read `stages/00-processed-input.md`. If missing:
   HALT: `[HALT] S3.1 Representational Change: dependency stages/00-processed-input.md not found.`
4. **If trigger was `S6_no_alternatives`**: also read `stages/S6-falsification.md`
   (best-effort; if missing, continue without). S6's raw hypothesis attempts
   help target the re-encoding step.

## MACHINE ADVANTAGE

**Exploited:** 3 de-fixation mechanisms × ≥3 candidates each = ≥9 simultaneous de-fixation attempts.
**Instruction:** Apply all three Ohlsson mechanisms in parallel. Generate all candidates before evaluating any. The anti-fixation instruction must appear at the start of each mechanism block.
**Bypasses:** Humans apply de-fixation mechanisms sequentially, anchoring on the first successful one. The machine can compare all 9+ outcomes simultaneously to select the most genuinely fixation-breaking candidate.

## GENIUS PERSPECTIVES

### Einstein (Einstellung override)
Mechanism: Explicit instruction to abandon the current approach overrides Hebbian fixation.
Used in: Anti-fixation instruction at start of each mechanism.

### Ohlsson (all three mechanisms)
Mechanism: Constraint relaxation, chunk decomposition, re-encoding — the three structural paths to insight.
Used in: Steps 1, 2, 3.

## PROTOCOL

**Anti-fixation instruction (apply before each mechanism):**
> "Set aside all previous solution attempts and representations. They are invalid for this mechanism pass. Begin from scratch."

1. **Constraint relaxation.** Read `ohlsson-defixation.md` Mechanism 1. Identify ≥3 constraints treated as absolute in the prior analysis. For each:
   - What becomes possible if this constraint is removed?
   - Rank by breakthrough-likelihood (most solutions opened → first)
   *Failure guard:* If all constraints are physically non-relaxable, document why; proceed to Step 2.

2. **Chunk decomposition.** Read `ohlsson-defixation.md` Mechanism 2. Identify ≥3 elements being treated as indivisible units. For each:
   - Decompose into constituent sub-elements
   - Identify which sub-elements can be recombined independently
   *Failure guard:* If no elements are genuinely decomposable, document; proceed to Step 3.

3. **Re-encoding.** Read `ohlsson-defixation.md` Mechanism 3. Apply ≥3 re-encodings:
   - Express the problem from the perspective of a first-time observer
   - Rephrase the goal in vocabulary from a different domain
   - Shift representation frame (see representation-frames.md if available; if not: symbolic↔spatial↔procedural↔analogical)
   *Failure guard:* If all re-encodings collapse back to the same representation, note as "representation appears canonical — re-encoding unable to shift frame."

4. **Select breakthrough candidate.** Across all 9+ candidates from Steps 1–3, select the single candidate with:
   - Highest breakthrough-likelihood
   - Most structurally distinct from the blocked approach
   State: mechanism used, target (the constraint/chunk/encoding transformed), what opens as a result.

5. **Verify:** Apply Einstellung-bias check from `ohlsson-defixation.md`:
   - Does the selected candidate genuinely break from the prior solution structure, or is it the same solution in a different surface form?
   - If fixation-residue detected: replace with next-best candidate; re-check.
   - Apply representation-coherence: is the new representation internally consistent?

## OUTPUT REQUIREMENTS

**XML element:** `<representational_change>` with sub-elements `<constraint_relaxations>`, `<chunk_decompositions>`, `<re_encodings>`, `<breakthrough_candidate>`, `<residual_fixation_signals>`.

**Section header rule:** Each required_output_sections string must appear verbatim as a `##` markdown header in the output. The validator performs case-sensitive exact-string matching. Use XML sub-elements for structure AND `##` headers inside each element:
- `## Constraint relaxations` — first line inside `<constraint_relaxations>`
- `## Chunk decompositions` — first line inside `<chunk_decompositions>`
- `## Re-encodings` — first line inside `<re_encodings>`
- `## Selected breakthrough candidate` — first line inside `<breakthrough_candidate>`
- `## Residual fixation signals` — first line inside `<residual_fixation_signals>`

**Required output sections:** Constraint relaxations (≥3) · Chunk decompositions (≥3) · Re-encodings (≥3) · Selected breakthrough candidate · Residual fixation signals.

**Empty marker:**
- If not activated: `<representational_change/>` — and in distilled output: `*(Stage S3.1 not activated — condition [S3_thin_or_empty / S6_no_alternatives] not met.)*`
- If activated but all mechanisms fail to produce non-residual candidates: emit `*(Stage S3.1 ran, no content found — reason: all candidates exhibited Einstellung residue.)*`

## SIGNALS

None raised. S3.1 does not trigger further conditional activation. Its output is consumed by S6 (if S6_no_alternatives was the trigger) and by S7/OSP (Representational Signals section).
