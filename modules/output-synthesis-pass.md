---
stage_id: OSP
stage_name: Output Synthesis Pass
module_version: 1.1.0
type: core
scale_gates: [MINIMAL, STANDARD, DEEP]
wave: 6
phase: synthesis
activation:
  - always
kb_sources: []
input_dependencies:
  - stages/S7-integration.md
  - stages/S7-v6-scope.txt
  - stages/S1-state-loading.md
  - stages/S5-precision-forcing.md
  - stages/00-processed-input.md
optional_dependencies:
  - stages/S2-constraint-escape.md
  - stages/S3-peripheral-exploration.md
  - stages/S3-1-defixation.md
  - stages/S4-dynamic-simulation.md
  - stages/S6-falsification.md
  - stages/S6-1-conjecture.md
output_file: stages/output-distilled.md
xml_element: null
context_budget_lines: 2000
required_output_sections:
  - "Pipeline Status Header"
  - "Headline Insight"
  - "Theory Collisions"
  - "Discovery vs. Proof"
  - "Independence-Verified Bridges"
  - "Alternative Hypotheses"
  - "Density-Checked Falsification"
  - "Scope Limits"
  - "Coherence Signals"
  - "Generalization Checks"
  - "Open Questions & Next Probes"
raises_signals: []
---

## CONTEXT LOADING

1. Read `stages/S7-integration.md`. If missing:
   HALT: `[HALT] OSP: dependency stages/S7-integration.md not found. S7 should have written this.`
2. Read `stages/S7-v6-scope.txt`. If missing:
   HALT: `[HALT] OSP: dependency stages/S7-v6-scope.txt not found. S7 V6 gate should have written this.`
3. Read all required input_dependencies. Note which optional files are present.
4. KB files: none — OSP reads only stage outputs.

## PROTOCOL

1. **Load-bearing claim selection.** Read all stage output files present. For each of the 11 always-present output sections, identify which stage output is the source and which fragments are load-bearing (minimum-depth claims, not scaffolding). Tag each fragment with its source stage. Do not discard at this step — all tagged fragments must appear in output or be explicitly marked as omitted with reason.

2. **Assembly.** Write the distilled document in order (items 1–12, or 1–13 if verbose). Each section separated by `---`. For each section whose source stage didn't run or isn't present: emit the correct canonical empty-section marker (see §10.4 of spec — canonical forms only, no substitution).

3. **v1.1.0 additions:**
   - Under Headline Insight (Item 2): append `**Creativity type:** [Combinatorial | Exploratory | Transformational]` (source: S7).
   - If S3.1 ran OR V7 detected a frame shift: insert **Representational Signals** section after Item 10:
     ```
     ## Representational Signals
     [If S3.1 ran: state which of Ohlsson's 3 mechanisms broke the fixation and what it opened]
     [If V7 flagged: state the representational shift from input to conclusion]
     ```
   If neither S3.1 ran nor V7 flagged a shift: omit this section entirely.

4. **V6 verbatim carve-out.** Item 8 (Scope Limits) content = read `stages/S7-v6-scope.txt` byte-for-byte. Write exactly that content under the Scope Limits section. Do NOT re-derive, paraphrase, summarize, or reword. If the file content differs from what V6 intended: that is the correct content — write it verbatim.

5. **Self-verify (3 checks, all must pass):**
   - (a) Every fragment tagged in Step 1 appears in output OR is explicitly marked "omitted: [reason]".
   - (b) Every claim in the output traces to a stage output file — no hallucinated additions.
   - (c) Item 8 Scope Limits content matches `stages/S7-v6-scope.txt` byte-for-byte. Read the file again and compare character-by-character.
   
   On self-verify SUCCESS: proceed without writing anything. Self-verify is a silent-pass process — do not append any self-verify notes, status markers, or verification summaries to the output document.

   On self-verify failure (any check): retry assembly once. If still fails after one retry: emit `<distillation_warning>[description of failing check]</distillation_warning>` as the absolute first line of the document — before the Pipeline Status Header, before any other content. Then continue writing the full output normally. Never silently fail, never block.

6. **Length review (advisory).** Compare against targets: MINIMAL ~600 / STANDARD ~1500 / DEEP ~2500 words. `--verbose` ~2x. If over: compress scaffolding and transitions only. NEVER trim: quoted claims, named mechanisms, V6 verbatim content, minimum-depth items.

## OUTPUT STRUCTURE (11 always-present + 2 conditional)

**Section header rule:** Each required_output_sections string must appear verbatim as a `##` markdown header in the output. The validator performs case-sensitive exact-string matching. Every section below must be preceded by its `##` heading — section numbers and bold labels alone do not satisfy validation:
- `## Pipeline Status Header` — heading above the blockquote
- `## Headline Insight` — heading above the primary conclusion block
- `## Theory Collisions` — heading above the collision list
- `## Discovery vs. Proof` — heading above the two-column block
- `## Independence-Verified Bridges` — heading above the bridge list
- `## Alternative Hypotheses` — heading above the hypothesis list
- `## Density-Checked Falsification` — heading above the density entries
- `## Scope Limits` — heading above the V6 verbatim carve-out
- `## Coherence Signals` — heading above the coherence signal list
- `## Generalization Checks` — heading above the generalization check block
- `## Open Questions & Next Probes` — heading above the probe list

All sections separated by `---`. Section numbers are for reference; do not print them.

**1. Pipeline Status Header**
```
> v1.1.0 · Scale: [SCALE] · Pipeline: complete at N of N planned [| truncated at stage X of Y] · Active conditionals: [S3.1 / S6.1 / none] · For raw state, re-invoke with --xml
```

**2. Headline Insight**
[From S7 primary conclusion] Confidence: HIGH / MODERATE / LOW.
**Creativity type:** [Combinatorial | Exploratory | Transformational]

**3. Theory Collisions**
[From S4 theory collisions. If S4 not run: `*(Stage S4 skipped at [SCALE] scale — run DEEP for this section.)*`]
Each collision: competing claims + discriminating condition.

**4. Discovery vs. Proof**
[From S2 constraint escape / S6.1 conjecture mode. If not run: canonical empty marker.] Format: two columns — Discovery (S2 domain mappings) vs. Proof (S5 constructive spec + S7 verification).

**5. Independence-Verified Bridges**
[From S3 convergent nodes. Includes emergent-structure bridges from S2 Step 7 blend if present.] Each bridge: source concept → target insight, structural invariant, disanalogy limit. If not run: canonical empty marker.

**6. Alternative Hypotheses**
[From S6 consolidated hypotheses / S6.1 conjectures.] Each: hypothesis + confidence + supporting modes + falsification condition. Never fabricate rivals to hit a count. If not run: canonical empty marker.

**7. Density-Checked Falsification**
[From S6 density report.] Per entry: `N vectors attempted — density [low|high] — residual uncertainty [high|low]`. If not run: canonical empty marker.

**8. Scope Limits**
[V6 verbatim from `stages/S7-v6-scope.txt` — byte-for-byte copy:]
```
**Applies to:** [...]
**Does not extend to:** [...]
**Claims refused:** [..., or "(none)"]
```

**9. Coherence Signals**
[From S7 structural-coherence weighting + unexpected-symmetry signals.] Each signal: name, cross-domain recurrence note.

**10. Generalization Checks**
[From S7 generalization-first check.] Format: "holds at [condition]" / "breaks at [condition]" for each tested scope.

**11. Representational Signals** (CONDITIONAL — only if S3.1 ran or V7 flagged shift)
[S3.1 mechanism named; V7 shift documented]

**12. Open Questions & Next Probes**
[From S6 + S7, ranked by discriminating power per unit effort.] ≥3 probes with priority ranking.

**13. Genius Mind Attributions** (`--verbose` only, inserted BEFORE item 12)
One line per key insight: [insight] → [genius name] + [mechanism cited].

## CANONICAL EMPTY-SECTION MARKERS (no substitution permitted)

| Kind | Form |
|------|------|
| Skipped at scale | `*(Stage SX skipped at [SCALE] scale — run [higher scales] for this section.)*` |
| Ran, thin | `*(Stage SX ran, no content found — reason: [why].)*` |
| Not reached | `*(Stage SX not reached — pipeline truncated at stage N of 7.)*` |
| Conditional not activated | `*(Stage SX.Y not activated — condition [cond] not met.)*` |

Scale-aware "run X" clause: at MINIMAL → "run STANDARD or DEEP"; at STANDARD → "run DEEP".
