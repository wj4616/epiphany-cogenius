# Theorem-of-Thought Parallel Inference Templates — Operational Reference (S6)

## Architecture

S6 spawns 3 parallel sub-subagents (one per inference mode) plus 1 consolidator. This file provides the protocol for each. Based on Theorem-of-Thought (Abdaljalil et al., arXiv:2506.07106): three parallel agents using abductive, deductive, and inductive modes, consolidated via Bayesian belief propagation guided by NLI confidence.

---

## Mode 1 — Abductive Inference (Inference-to-Best-Explanation)

**Peirce's formulation:** The surprising fact C is observed. If A were true, C would be a matter of course. Hence, there is reason to suspect A is true.

**Template for S6 Abductive sub-subagent:**

```
Input: Read stages/00-processed-input.md and stages/S1-state-loading.md.

Step A1 — Identify the anomaly: What is the most surprising, unexpected, or hard-to-explain 
element of this problem? State it precisely in one sentence.

Step A2 — Generate candidate explanations (≥5): For each candidate:
  "IF [hypothesis H] were true, THEN the anomaly would follow because [mechanism]"
  The hypothesis must be distinct from any solution already identified.

Step A3 — Score each candidate on:
  (a) Parsimony: how few additional assumptions does it require? [0.0–1.0]
  (b) Explanatory power: what fraction of the problem does it explain? [0.0–1.0]
  (c) Uberty (Peirce): if true, how many other open questions does it simultaneously resolve? [0.0–1.0]
  (d) Testability: can it be disproven? State the falsification condition.

Step A4 — Select top 3 candidates ranked by combined score.
Step A5 — Return: {mode: "abductive", candidates: [{hypothesis, score, falsification_condition}...]}
```

---

## Mode 2 — Deductive Inference (Logical-Consequence Testing)

**Mechanism:** From premises that are established (S1 facts + S5 constructive spec), derive what MUST follow by valid reasoning. Test each derived consequence for compatibility with the observed problem.

**Template for S6 Deductive sub-subagent:**

```
Input: Read stages/00-processed-input.md, stages/S1-state-loading.md, stages/S5-precision-forcing.md.

Step D1 — Collect premises: List all claims from S1 facts and S5 constructive spec that can serve 
as premises (well-established, not hypothetical).

Step D2 — Derive consequences: Apply modus ponens, modus tollens, and transitivity systematically.
For each inference:
  Premise A: [...]
  Premise B: [...]
  Therefore: [...] — validity check: does this actually follow?

Step D3 — Test each consequence against the problem:
  Does [consequence] hold in the observed problem? [YES / NO / UNKNOWN]
  If NO: the premise set contains an error → flag which premise is likely wrong.

Step D4 — Collect alternative hypotheses from consequence testing:
  Each "premise likely wrong" finding generates a hypothesis: "The premise [X] may be false; 
  if so, [alternative consequence] would hold instead."

Step D5 — Return: {mode: "deductive", consequences: [...], flagged_premises: [...], 
alternative_hypotheses: [{hypothesis, premise_challenged}...]}
```

---

## Mode 3 — Inductive Inference (Generalization Testing)

**Mechanism:** From observed instances and patterns in the problem, generalize to a principle. Test whether the generalization holds or breaks at boundary cases.

**Template for S6 Inductive sub-subagent:**

```
Input: Read stages/00-processed-input.md, stages/S1-state-loading.md, stages/S3-peripheral-exploration.md (if present).

Step I1 — Identify instances: What specific cases, examples, or observations are present in 
the problem? List all (minimum 3 for induction to proceed).

Step I2 — Generate generalizations (≥3): For each generalization:
  "Across all observed instances, the pattern [P] appears because [mechanism]"
  The generalization must extend beyond the observed cases.

Step I3 — Test boundary cases: For each generalization, find at least one case where it 
might NOT hold:
  "Generalization [P] would fail at [boundary condition X] because [reason]"
  → If the generalization survives: mark ROBUST
  → If the generalization fails at boundary: mark LIMITED TO [scope]

Step I4 — Generate alternative hypotheses from failed generalizations:
  Each boundary failure produces a hypothesis: "The true pattern may be [restricted form] 
  rather than [full generalization]"

Step I5 — Return: {mode: "inductive", generalizations: [{pattern, robustness, scope}...], 
alternative_hypotheses: [{hypothesis, bounded_by}...]}
```

---

## Consolidator Sub-Subagent Template

**Input:** Outputs from all three mode sub-subagents (JSON structures above).

```
Step C1 — Collect all alternative hypotheses from abductive + deductive + inductive.
Step C2 — Deduplicate: merge hypotheses that are structurally equivalent.
Step C3 — Cross-mode validation: a hypothesis supported by ≥2 modes receives higher confidence.
Step C4 — Assign NLI confidence scores (0.0–1.0) to each distinct hypothesis.
Step C5 — Produce final ranked list of ≥3 distinct alternative hypotheses.
Step C6 — For each: state [hypothesis, confidence, supporting_modes, falsification_condition].
Return: {mode: "consolidated", hypotheses: [{...}...], count: N}
```

**Signal:** If count == 0 after consolidation → emit `S6_no_alternatives` in return status.

---

## S6 Output Format

```
## Abductive Mode — Candidates
1. [hypothesis] (parsimony: X, explanatory: Y, uberty: Z) | falsification: [condition]
...

## Deductive Mode — Consequences and Flagged Premises
[consequence 1]: holds / contradicts
Flagged premise: [X]
...

## Inductive Mode — Generalizations
[generalization 1]: ROBUST | LIMITED TO [scope]
...

## Consolidated Hypotheses (≥3)
1. [hypothesis] | confidence: [0.0–1.0] | modes: [A/D/I] | falsification: [condition]
2. ...
3. ...
```
