---
stage_id: S7
stage_name: Integration & Verification
module_version: 1.1.0
type: core
scale_gates: [MINIMAL, STANDARD, DEEP]
wave: 5
phase: synthesis
activation:
  - always
kb_sources:
  - verification-gates.md
  - boden-types.md
  - scope-template.md
  - representation-frames.md
  - elegance-rubric.md
input_dependencies:
  - stages/00-processed-input.md
  - stages/S1-state-loading.md
optional_dependencies:
  - stages/S5-precision-forcing.md
  - stages/S2-constraint-escape.md
  - stages/S3-peripheral-exploration.md
  - stages/S3-1-defixation.md
  - stages/S4-dynamic-simulation.md
  - stages/S6-falsification.md
  - stages/S6-1-conjecture.md
output_file: stages/S7-integration.md
xml_element: integration
context_budget_lines: 1500
required_output_sections:
  - "Convergence signals"
  - "Primary conclusion"
  - "Confidence band"
  - "Creativity type"
  - "Generalization check"
  - "Verification report (V1-V7)"
raises_signals: []
---

## CONTEXT LOADING

1. Read all 5 KB files from kb_sources under KB_BASE.
2. Read `stages/00-processed-input.md`. If missing:
   HALT: `[HALT] S7 Integration & Verification: dependency stages/00-processed-input.md not found.`
3. Read `stages/S1-state-loading.md`. If missing:
   HALT: `[HALT] S7 Integration & Verification: dependency stages/S1-state-loading.md not found.`
4. Read `stages/S5-precision-forcing.md`. If missing:
   HALT: `[HALT] S7 Integration & Verification: dependency stages/S5-precision-forcing.md not found.`
5. Read all other stage output files present in the session directory. Note which stages ran (for V4 completeness check).

## MACHINE ADVANTAGE

**Exploited:** Integrate convergence signals across all prior stages in one pass; apply V1–V7 battery as explicit separate gates — no compression across stages.
**Instruction:** Read ALL prior stage outputs before drawing any conclusion. Do not form the primary conclusion until after reading every available stage. V1–V7 gates are applied AFTER conclusion formation, not during.
**Bypasses:** Humans integrate information sequentially and anchor on early conclusions. The machine reads all sources simultaneously before forming the synthesis.

## GENIUS PERSPECTIVES

### Feynman
Mechanism: Error-seeking — actively look for what is wrong with the conclusion; symmetric scrutiny (V3).
Used in: Steps 5–6 (verification battery, especially V2 cargo-cult and V3 symmetric scrutiny).

### Newton
Mechanism: Generalization-first — does the conclusion generalize, or is it a one-off?
Used in: Step 4 (generalization-first check).

### Ramanujan
Mechanism: Structural coherence — unexpected symmetries strengthen the claim.
Used in: Step 3 (elegance scoring applied to primary conclusion).

### Von Neumann
Mechanism: Systematic integration across all prior reasoning states.
Used in: Step 1 (convergence signal collection from all stages).

## PROTOCOL

1. **Collect convergence signals.** Read all prior stage outputs. For each stage that ran: identify the key claim, finding, or bridge it contributed. Identify convergence signals — claims or patterns that appear independently in ≥2 stage outputs. Identify divergence points — places where two stages predict different things.
   *Failure guard:* If fewer than 2 stages ran (MINIMAL), convergence signals are limited — note this and continue with available signals.

2. **Construct primary conclusion.** From convergence signals: build the primary conclusion as the claim best supported by independent confirmation across stages. Divergence points become limitations (feed to V6).
   *Failure guard:* If no convergence signals exist (all stages returned thin), construct best-available conclusion from S1 primitives alone; note confidence = LOW.

3. **Boden creativity type + structural coherence weighting.** Read `boden-types.md` and `elegance-rubric.md`. Tag the primary conclusion as Combinatorial / Exploratory / Transformational. Apply elegance scoring. If cross-domain recurrence (Symmetry ≥ 0.7): note as strength. If Transformational: apply aggressive V6 scope narrowing.

4. **Generalization-first check.** Does the primary conclusion generalize beyond the specific problem instance, or is it a one-off finding? State: "Generalizes to [class of problems / conditions]" or "One-off: applies only to [specific instance]." If one-off: note as limitation in V6.

5. **Confidence band assignment.** HIGH / MODERATE / LOW:
   - HIGH: ≥3 independent convergence signals, V1 logic PASS, no unresolved divergences
   - MODERATE: 1–2 convergence signals or minor logic gaps or 1 unresolved divergence
   - LOW: single-stage conclusion or multiple V1/V3 failures or major divergence unresolved

6. **V1–V7 verification battery.** Read `verification-gates.md`, `scope-template.md`, `representation-frames.md`. Apply each gate in order:

   **V1 Logic:** List every inferential step from S1 to conclusion. Check each for validity. PASS/PARTIAL/FAIL.

   **V2 Cargo-Cult:** Scan for patterns that look like rigor without being rigorous (jargon-heavy assertions, anonymous statistics, analogy-as-proof). PASS/FAIL.

   **V3 Symmetric Scrutiny:** Compare challenges applied to primary conclusion vs. challenges applied to rivals. PASS/FAIL.

   **V4 Completeness:** For each stage that ran: is it cited in the conclusion? Flag thin stages. PASS or [THIN: SN].

   **V5 Constructive:** Is the conclusion constructive — can it be demonstrated? State minimal demonstrating procedure. PASS/FAIL.

   **V6 Scope:** Read `scope-template.md`. Write `stages/S7-v6-scope.txt` with exact three-label format. Apply Boden-type narrowing. HALT if file cannot be written.
   ```
   **Applies to:** [fill]
   **Does not extend to:** [fill]
   **Claims refused:** [fill or "(none)"]
   ```

   **V7 Representational Coherence:** Read `representation-frames.md`. Identify input frame from `00-processed-input.md`. Identify conclusion frame. Document any shift. Feed shift to V6. PASS or [Shift: A→B].

7. **Open questions & next probes.** From divergence points, V4 thin stages, and V6 exclusions: generate ≥3 probes ranked by discriminating power per unit effort. Format: `[probe] — [why it matters] — [priority: high/medium/low]`

## OUTPUT REQUIREMENTS

**XML element:** `<integration>` with `<primary_conclusion>` (containing `<creativity_type>`), `<verification_report>` (containing `<v1_logic>` through `<v7_representational>`), `<open_questions>`.

**Section header rule:** Each required_output_sections string must appear verbatim as a `##` markdown header in the output. The validator performs case-sensitive exact-string matching. Use XML sub-elements for structure AND `##` headers inside each element:
- `## Convergence signals` — before the convergence signal list (inside or before `<primary_conclusion>`)
- `## Primary conclusion` — heading for the primary conclusion block
- `## Confidence band` — heading for the confidence band assignment
- `## Creativity type` — heading for the Boden type + elegance scoring block
- `## Generalization check` — heading for the generalization-first check section
- `## Verification report (V1-V7)` — heading for the full V1–V7 battery block

**Required output sections:** as listed in frontmatter.

Also writes: `stages/S7-v6-scope.txt` — verbatim scope statement (3 lines, exact labels).

**Verification summary block** (required at end of output):
```
V1 Logic: [PASS/PARTIAL/FAIL] — [notes]
V2 Cargo-Cult: [PASS/FAIL] — [notes]
V3 Symmetric Scrutiny: [PASS/FAIL] — [notes]
V4 Completeness: [PASS] or [THIN: stages] — [notes]
V5 Constructive: [PASS/FAIL] — constructive spec: [one sentence]
V6 Scope: [PASS] — wrote stages/S7-v6-scope.txt
V7 Representational: [No shift / Shift: A→B] — [notes]
Overall: [N PASS] / [M PARTIAL/FAIL] out of 7 gates
```

## SIGNALS

None raised. S7 is the final core stage. Its V4 completeness gate feeds back to the orchestrator's STEP 6 retry logic, and V7 representational shift is consumed by the OSP — but neither constitutes a named signal in the conditional-module activation grammar.
