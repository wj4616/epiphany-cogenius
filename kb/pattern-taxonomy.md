# Pattern Taxonomy — Operational Reference (S6.1 — Conjecture Mode)

## Purpose

Ramanujan's method: detect mathematical patterns across instances, generate conjectures about the underlying generalization, then verify on additional test cases. S6.1 applies this to any structured input.

---

## Pattern Type Taxonomy

### Type 1 — Cross-Domain Structural Matches

**Definition:** The same abstract structure appears in ≥2 independent domains with no known causal connection between them.

**Detection criteria:**
- The relationship between elements in Domain A can be mapped isomorphically to a relationship between elements in Domain B
- The mapping is structural (about roles and relations), not superficial (not just shared vocabulary)
- The two domains do not normally interact

**Examples:**
- Power laws appear in: earthquake magnitudes, word frequencies, wealth distribution, neuron firing rates, city sizes — structurally identical despite no mechanism connecting them
- Fibonacci sequences appear in: spiral galaxy arms, plant leaf arrangements, financial markets — same ratio, different substrate

**Format:**
```
Pattern: [abstract description of the structural relationship]
Appears in Domain A: [how it manifests]
Appears in Domain B: [how it manifests]
Structural invariant: [the abstract relationship that holds in both]
Conjecture: [what generalization does this suggest?]
```

### Type 2 — Recurrence Relations

**Definition:** A quantity or structure at step N is determined by values at earlier steps N-1, N-2, ... — a self-referential dependency.

**Detection criteria:**
- Same formula or proportion appears across time steps or scales
- The structure reproduces itself at different levels (self-similar, fractal)
- A growth rate or decay rate remains constant across different quantities

**Format:**
```
Recurrence: [f(N) = expression involving f(N-1), f(N-2), ...]
Observed instances: [where does this hold?]
Conjecture: [what would this recurrence predict at scale N+k?]
Verification test: [what observable would confirm or deny?]
```

### Type 3 — Symmetry Groups

**Definition:** A set of transformations that leave a structure invariant — the structure looks the same after the transformation as before.

**Detection criteria:**
- Swapping two elements produces an equivalent result
- Rotating, reflecting, or permuting elements leaves the essential structure unchanged
- Removing an element still satisfies some property (closure under deletion)

**Examples:**
- Palindromes: symmetry under reversal
- Conservation laws: symmetry under time-translation (Noether's theorem)
- Fair voting systems: symmetry under permutation of voters

**Format:**
```
Symmetry: [the transformation that leaves the structure unchanged]
Structure: [what remains invariant]
Conjecture: [what new symmetry might exist that has not been checked?]
Breaking condition: [when/where does the symmetry fail?]
```

---

## Novelty Rubric

For each pattern detected, score novelty (0.0–1.0):

| Score | Meaning |
|-------|---------|
| 1.0 | Pattern not previously identified in literature; cross-domain occurrence is entirely new |
| 0.7 | Pattern known within one domain; cross-domain transfer is novel |
| 0.4 | Pattern known across multiple domains; conjecture extends scope or precision |
| 0.1 | Pattern is well-established; conjecture adds minor detail |

---

## Elegance Floor Criteria

A conjecture must meet ALL of the following to be included in S6.1 output:

1. **Non-trivial vs. S1:** The conjecture is not already stated or clearly implied by the S1 primitives
2. **Testable:** The conjecture specifies conditions under which it would be falsified
3. **Elegance ≥ 1.5** on elegance-rubric.md scoring

Below-floor conjectures: log as "detected, below elegance floor, excluded" — do not fabricate to hit count.

---

## Conjecture Output Format

```
## Conjectures (≥3 required)

### Conjecture 1
Pattern type: [Cross-domain / Recurrence / Symmetry]
Pattern: [abstract description]
Evidence: [instances where it appears]
Conjecture: "[formal statement of the generalization]"
Novelty score: [0.0–1.0]
Elegance score: [0.0–3.0]
Verification: [≥2 test instances where this holds / fails]
Falsification condition: [what observable would defeat this conjecture?]

### Conjecture 2
...

### Conjecture 3
...
```

**Verification requirement:** Each conjecture must hold on ≥2 test instances drawn from the input or from well-established external facts. Test instances must be independent from the instances that generated the pattern.
