# Scope Template — Operational Reference (S7, V6)

## Purpose

V6 writes `stages/S7-v6-scope.txt` — the definitive, verbatim scope statement that the OSP reads byte-for-byte. This file specifies the required format.

---

## Required Format (exact labels, no substitution)

```
**Applies to:** [fill here]
**Does not extend to:** [fill here]
**Claims refused:** [fill here or "(none)"]
```

---

## Filling Each Field

### `Applies to:`

State the specific classes of problem, conditions, and domains where the conclusion holds. Be specific — not "many cases" or "most situations."

**Requirements:**
- Name the domain explicitly (not "problems like this")
- State the conditions that must hold (e.g., "when [parameter] is [range]")
- If the Boden type is Transformational: name the new conceptual space defined by the negated constraint

**Examples:**
- Good: "Applies to: scheduling problems where task durations are known in advance and resources are homogeneous"
- Bad: "Applies to: similar optimization problems"

---

### `Does not extend to:`

Enumerate what the conclusion explicitly does NOT cover. This is not hedging — it is domain-boundary-refusal, which makes the conclusion stronger by being honest about its scope.

**Requirements:**
- List ≥2 specific exclusions (not "edge cases" — name the class)
- If V7 detected a representational frame shift: "Does not extend to: conclusions stated in [original frame] — conclusion was derived in [new frame]"
- If V6 scope is Transformational: "Does not extend to: problems within the original [name of old space], which presupposes [negated constraint]"

**Examples:**
- Good: "Does not extend to: real-time scheduling (task durations not known); multi-resource problems (resources not homogeneous); stochastic settings (task completion times variable)"
- Bad: "Does not extend to: other types of problems"

---

### `Claims refused:`

State any inference that was attempted but is not supported by the evidence base. "(none)" is a valid and complete entry if no such inference was attempted.

**Requirements:**
- List each refused claim as: "[claim] — refused because [specific reason, e.g., insufficient evidence / out of scope / V1 logic gap]"
- Do not silently omit refused claims — a claim raised in the input and not addressed must appear here

**Examples:**
- "Claims that this approach achieves better-than-linear time complexity — refused: no complexity analysis performed"
- "(none)"

---

## Writing Protocol (S7 Step 6, V6)

1. First, determine Boden type from S7 Step 3
2. Apply scope-narrowing aggressiveness per Boden type (see boden-types.md)
3. If V7 detected a frame shift: note the shift in both "Applies to" and "Does not extend to"
4. Write the three fields in the exact format above
5. Write file `stages/S7-v6-scope.txt` with exactly those three lines — no additional content

---

## OSP Verbatim-Copy Requirement

The OSP reads `stages/S7-v6-scope.txt` byte-for-byte and inserts it into Section 8 of the distilled output. The OSP must NOT re-derive, paraphrase, or reword this content. If the file is missing → OSP halts.

The scope statement in the distilled output must match the file exactly — T3 checks this character-by-character.
