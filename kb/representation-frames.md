# Representation Frames — Operational Reference (S7, V7)

## Purpose

V7 detects whether the primary conclusion is expressed in the same representational frame as the original input. If different, the conclusion is a re-representation — and the scope must reflect that.

---

## Frame Taxonomy

### Frame 1 — Symbolic

**Definition:** The content is expressed as formal notation — mathematical symbols, logical formulae, code, formal grammars, algebraic expressions.

**Detection markers:** Equations, operators (∀, ∃, →, ↔), variable names, formal definitions, type signatures, syntax rules.

**Shift examples:** Input is a verbal description of a physical process → conclusion is expressed as a differential equation.

---

### Frame 2 — Spatial

**Definition:** The content is expressed in terms of geometry, topology, position, shape, or visual arrangement.

**Detection markers:** Diagrams (described or referenced), coordinates, "above/below/inside/outside," graph layouts, physical regions, distance metrics.

**Shift examples:** Input is a list of logical conditions → conclusion is expressed as a decision boundary in feature space.

---

### Frame 3 — Procedural

**Definition:** The content is expressed as a sequence of steps, operations, or actions to be performed.

**Detection markers:** Imperative verbs ("compute," "check," "apply," "iterate"), numbered steps, algorithms, pseudocode, process descriptions, if-then instructions.

**Shift examples:** Input asks "what is X" → conclusion describes "how to compute X."

---

### Frame 4 — Declarative

**Definition:** The content is expressed as statements about what is true — facts, properties, relationships — without specifying how to determine or compute them.

**Detection markers:** "X is Y," "all X have property P," "if condition C then D holds," existence statements, universal claims.

**Shift examples:** Input describes a procedure → conclusion states a property that the procedure always satisfies.

---

### Frame 5 — Analogical

**Definition:** The content is expressed primarily through comparison to another domain, using the source domain's vocabulary and structure.

**Detection markers:** "Like," "analogous to," "similar to," "as X is to Y," source domain vocabulary used to describe target domain.

**Shift examples:** Input is a mathematical proof → conclusion is "this is like the free-rider problem in economics."

---

### Frame 6 — Narrative

**Definition:** The content is expressed as a story, case, or sequence of events with causal or temporal structure and human-readable flow.

**Detection markers:** Time words ("first," "then," "finally"), agents with intentions, causal narrative chains, example scenarios.

**Shift examples:** Input is a formal specification → conclusion is expressed as a user scenario.

---

## Shift Detection Protocol (V7)

1. **Identify input frame:** Read `stages/00-processed-input.md`. Which frame (1–6) best describes how the problem was expressed? If multiple frames are present, identify the dominant one.

2. **Identify conclusion frame:** Read the primary conclusion in S7. Which frame does it use?

3. **Compare:** Same frame → V7 passes, no shift. Different frame → shift detected.

4. **Name the shift:** `[input_frame] → [conclusion_frame]`

5. **Consequence:** The conclusion does not directly answer the question as originally posed — it re-represents it. This is valid and often valuable; it must be disclosed.

6. **Feed to V6:** Add to "Does not extend to" the statement that the conclusion is in [conclusion_frame] and does not directly apply to [input_frame] contexts without translation.

---

## Shift Significance Scale

| Shift | Significance |
|-------|-------------|
| Declarative → Symbolic | Low — formalization is expected |
| Symbolic → Procedural | Moderate — changed from "what is" to "how to compute" |
| Narrative → Symbolic | High — stripped human context; scope must narrow |
| Symbolic → Analogical | High — analogy is not a proof; scope must narrow significantly |
| Any → Procedural | Moderate — the answer is now a method, not a fact |
| Same frame | None — no scope impact from V7 |

Higher significance → narrower V6 scope, more aggressive exclusion in "Does not extend to."
