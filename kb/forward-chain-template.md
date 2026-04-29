# Forward-Chain Template — Operational Reference (S5)

## Purpose

Von Neumann's ten-steps-ahead derivation: starting from a constructive specification, generate all consequences to depth 3–5, working in parallel across multiple branches. Exposes contradictions, pathological states, and degenerate behaviors before they emerge in practice.

---

## Tree Structure

```
Root Node: [Constructive specification from S5 Step 3]
  │
  ├── Branch A: [Consequence if context condition A holds]
  │   ├── A.1: [Second-order consequence]
  │   │   └── A.1.1: [Third-order consequence]
  │   └── A.2: [Second-order consequence]
  │       ├── A.2.1: [Third-order consequence — flag if contradiction]
  │       └── A.2.2: [Third-order consequence — flag if degenerate]
  │
  ├── Branch B: [Consequence if context condition B holds]
  │   └── ...
  │
  └── Branch C: [Consequence if context condition C holds]
      └── ...
```

---

## Building the Tree

**Step 1 — Root:** The constructive spec is the root node (single sentence).

**Step 2 — First-order branches (parallel):** Generate 10 independent consequence chains from the root. Each chain represents a different context, condition, or application scenario. Generate all 10 simultaneously — do not filter before generating.

**Condition types for branching:**
- Time conditions: "when the system has been running for [period]"
- Scale conditions: "when [parameter] is at minimum / maximum"
- Adversarial conditions: "when an agent is actively optimizing against the claim"
- Composition conditions: "when combined with [other system/claim]"
- Resource conditions: "when resources are constrained / abundant"

**Step 3 — Second and third order:** For each first-order branch, derive 2–3 second-order consequences. For each second-order consequence, derive 1–2 third-order consequences. Depth minimum: 3. Depth maximum: 5 (stop if consequences become purely definitional).

**Step 4 — Flag-and-continue:** For each leaf node or mid-tree node that meets a flag condition, apply the appropriate flag and CONTINUE — do not stop the tree.

---

## Flag Conditions

### Flag 1: Contradiction

A consequence at any depth produces a statement that directly contradicts:
- A known fact from S1 primitives
- A constraint from S5 Level 3/4 rendering
- Another branch of the consequence tree

**Format:** `[CONTRADICTION] Branch [X.Y]: "[consequence statement]" contradicts "[prior claim/fact]". Discriminating condition: [what would resolve which claim is wrong?]`

### Flag 2: Pathological State

A consequence at any depth produces a state that is:
- Operationally undefined (division by zero, empty set where non-empty required)
- Computationally intractable (exponential blowup, halting problem analog)
- Physically impossible (violates conserved quantity, violates known laws)

**Format:** `[PATHOLOGICAL] Branch [X.Y]: "[consequence statement]" is [undefined/intractable/impossible] because [reason]`

### Flag 3: Degenerate Behavior

A consequence at any depth produces behavior that is:
- A trivial special case that makes the claim vacuously true
- A fixpoint where all dynamics stop (system freezes in a useless state)
- A boundary case that was silently excluded from the original claim's scope

**Format:** `[DEGENERATE] Branch [X.Y]: "[consequence statement]" is degenerate — [why trivial/frozen/excluded]`

---

## Output Requirements

```
## Consequence Tree
Root: [constructive spec]

Branch A — [condition]:
  A.1: [consequence]
    A.1.1: [consequence]
  A.2: [consequence] [FLAG if applicable]

[... all 10 first-order branches ...]

## Flags Summary
[CONTRADICTION] Branch X.Y: ...
[PATHOLOGICAL] Branch X.Y: ...
[DEGENERATE] Branch X.Y: ...

## Tree Statistics
Branches generated: [N]
Flags raised: [N contradiction / N pathological / N degenerate]
```

Minimum: 10 first-order branches, ≥3 levels deep. Maximum: 50 total nodes (prune at that point; note pruning).
