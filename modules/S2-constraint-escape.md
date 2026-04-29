---
stage_id: S2
stage_name: Constraint Escape
module_version: 1.1.0
type: core
scale_gates: [STANDARD, DEEP]
wave: 2
phase: ideation
activation:
  - always
kb_sources:
  - domain-catalog.md
  - blend-template.md
  - debono-techniques.md
input_dependencies:
  - stages/00-processed-input.md
output_file: stages/S2-constraint-escape.md
xml_element: constraint_escape
context_budget_lines: 1200
required_output_sections:
  - "Named constraint"
  - "Domain candidates surveyed"
  - "Domain mappings (5)"
  - "Activation provenance"
  - "Constraint-escape path"
raises_signals: []
---

## CONTEXT LOADING

1. Read the 3 files in kb_sources under KB_BASE (`~/.claude/skills/epiphany-cogenius/kb/`).
2. Read `stages/00-processed-input.md`. If missing:
   HALT: `[HALT] S2 Constraint Escape: dependency stages/00-processed-input.md not found. Input router (STEP 3) should have written this.`

## MACHINE ADVANTAGE

**Exploited:** Parallel domain survey across 20+ domains simultaneously.
**Instruction:** Generate all 5 domain mappings in a single pass, not sequentially. Enumerate candidate domains in parallel — each candidate is an independent evaluation; combine via parallel reasoning.
**Bypasses:** Humans search domains sequentially and only from domains they already know.

## GENIUS PERSPECTIVES

### Archimedes
Mechanism: Name the binding constraint before searching for solutions.
Used in: Step 1.

### Newton
Mechanism: Transfer structural relationships (not surface features) across domains.
Used in: Steps 3 and 5.

### Da Vinci
Mechanism: Describe phenomena in domain-agnostic terms to enable cross-domain matching.
Used in: Step 2.

## PROTOCOL

1. **Name the constraint.** Read `00-processed-input.md`. Identify the single binding constraint. Write it verbatim. (Archimedes: name before searching.)
   *Failure guard:* If multiple constraints equally binding, name all; mark for V6.

2. **Survey ≥20 candidate domains in parallel.** Read `domain-catalog.md`. Describe the constraint in domain-agnostic terms (Da Vinci), then match against catalog entries. For each viable domain, note the domain-agnostic occurrence.
   *Failure guard:* If fewer than 5 viable candidates emerge, continue to Step 8.

3. **Produce 5 structurally-distinct domain mappings.** For each:
   source domain → target domain → structural analog → what solves it in source.
   (Newton: transfer structural relationships, not surface features.)
   *Failure guard:* Mappings must share NO surface features; if they do, re-generate.

4. **Activation provenance.** For each candidate concept encountered: mark single-source or multi-source-convergent (activated from ≥2 independent chains in Step 2).
   *Failure guard:* If no concept has multi-source provenance, widen Step 2 and retry.

5. **Select the constraint-escape path.** Rank mappings by convergence × structural fit. Select top path. (Newton analogical transfer.)
   *Failure guard:* On ties, emit both.

6. **Verify before writing:**
   - Systematicity: 5 mappings structurally distinct?
   - Provenance: every candidate has provenance declared?
   - Blend-worthiness: does ≥1 mapping produce emergent structure (features in the blend that exist in neither source alone)? If yes → proceed to Step 7.
   If systematicity or provenance fails, regenerate affected mappings.

7. **[Optional — fires when Step 6 tags blend-worthy]** Four-space conceptual blend (Fauconnier & Turner). Read `blend-template.md` for the 4-space structure. Identify Input Space 1 (source domain), Input Space 2 (target / original problem), Generic Space (shared skeleton), and Blend (selective projection + elaboration). Tag emergent features.
   Write under `<conceptual_blend>` sub-element.
   *Failure guard:* No emergent features → skip blend section; don't fabricate.

8. **[Fallback — fires when Step 6 shows <3 viable mappings]** De Bono lateral library. Read `debono-techniques.md` — apply all three techniques (provocation, random-entry, reversal) to produce ≥5 structurally distinct candidates. Each candidate must declare which technique produced it and why it is structurally distinct from the mappings in Step 3.
   Emit under `<fallback_library>` sub-element.

## OUTPUT REQUIREMENTS

**XML element:** `<constraint_escape>` with sub-elements `<named_constraint>`, `<domain_candidates>`, `<domain_mappings>` (5 `<mapping>` children), `<activation_provenance>`, `<conceptual_blend>` (only if Step 7 fired), `<fallback_library>` (only if Step 8 fired), `<escape_path>`.

**Section header rule:** Each required_output_sections string must appear verbatim as a `##` markdown header in the output. The validator performs case-sensitive exact-string matching. Use XML sub-elements for structure AND `##` headers inside each element:
- `## Named constraint` — first line inside `<named_constraint>`
- `## Domain candidates surveyed` — first line inside `<domain_candidates>`
- `## Domain mappings (5)` — first line inside `<domain_mappings>`
- `## Activation provenance` — first line inside `<activation_provenance>`
- `## Constraint-escape path` — first line inside `<escape_path>`

**Required output sections:** as listed in frontmatter.

**Empty marker policy:**
- At MINIMAL: emit `<constraint_escape/>` (scale gate; not run).
- If genuinely binding (no viable escape in any surveyed domain AND Step 8 fallback produced nothing): emit `*(Stage S2 ran, no content found — reason: constraint binding in all 20+ domains; fallback produced no candidates.)*` in distilled output.

**This is NOT a failure case; pipeline CONTINUES.**

## SIGNALS

None emitted. (S2 thin/empty shows in status; no downstream conditional gate is named for it in v1.1.0.)
