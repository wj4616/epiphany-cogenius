# Boden Creativity Types — Operational Reference (S7)

## Overview

Margaret Boden's three creativity types classify how a conclusion relates to its conceptual space. The type determines scope-narrowing aggressiveness (V6) and interpretation of the claim's novelty.

---

## Type 1 — Combinatorial Creativity

**Definition:** Preexisting ideas are merged in novel ways. No constraint of the conceptual space is violated. The novel result comes from placing existing elements in new proximity or relation.

**Structural signature:**
- Conclusion draws elements from ≥2 known domains or idea-sets
- No foundational constraint of either domain is negated
- The insight is the *combination*, not a new rule or boundary

**Distinguishing examples:**
- Bohr's atomic model: atoms as solar systems (merges known physics structures)
- Darwin's natural selection: competition + variation + inheritance (combines existing biological observations)
- Pegasus: horse + wings (combination of known features)

**V6 scope treatment:** Moderate narrowing. The claim applies to problems sharing the combined structure. Does not extend to: cases where one source domain's constraints don't hold.

**S7 structural coherence note:** Elegance symmetry score reflects quality of the combination — look for cross-domain recurrence of the combined structure.

---

## Type 2 — Exploratory Creativity

**Definition:** Creativity arising from exploration within an established conceptual space. The space's rules are preserved; the creative act is finding a previously unvisited region.

**Structural signature:**
- Conclusion is theoretically possible within the current constraint set
- The insight is that this specific region of the possibility space was unexplored
- All foundational rules remain intact

**Distinguishing examples:**
- A chess player discovering an unusual combination theoretically possible under the rules
- Dickens using multiple adjectives before a noun — grammatically permitted but not previously done at that density
- A mathematician finding a proof using only methods that already exist but combining them unexpectedly

**V6 scope treatment:** Conservative narrowing. The claim applies to problems within the same conceptual space. State the space's defining constraints explicitly in "Applies to."

**Distinguishing test from Combinatorial:** If the conclusion could have been stated as "I found a way to combine X and Y," it's Combinatorial. If it's "I found a corner of the possibility space that no one had visited," it's Exploratory.

---

## Type 3 — Transformational Creativity

**Definition:** Creativity arising when foundational rules of a conceptual space are altered. Creates genuinely new possibilities that could not have existed before.

**Structural signature:**
- A constitutive constraint (one that defines the space itself, not merely an incidental restriction) is identified and negated
- After negation, new possibilities exist that were strictly impossible before
- The insight is the new space, not just a new point within the old one

**Distinguishing examples:**
- Schoenberg: negated the home-key constraint → atonal composition (new music conceptual space)
- Lobachevsky: negated Euclid's fifth axiom → non-Euclidean geometry (new geometry)
- Kekulé: negated "molecular chains must be open" → ring-shaped organic molecules (benzene ring)

**V6 scope treatment:** Aggressive narrowing required. The claim applies *only within the new space* defined by the negated constraint. "Does not extend to" must name the original space. "Claims refused" must include all inferences that presuppose the old constraint remains valid.

**Distinguishing test:** Ask: "Was this conclusion strictly impossible before, or just unexplored?" If strictly impossible → Transformational. If unexplored → Exploratory.

**S7 warning:** Transformational conclusions are the most powerful and the most likely to overreach scope. Apply V6 most aggressively here.

---

## Structural Coherence Weighting (S7 Step 3)

After typing the conclusion:
- Unexpected symmetries (elegance-rubric.md) that hold across the new space **strengthen** the claim
- For Transformational: if the new space lacks internal structural coherence (its rules contradict each other), the negation may be ill-formed — flag in V1 Logic check

## Creativity Type Line (OSP Output)

Always emit: `**Creativity type:** [Combinatorial | Exploratory | Transformational]`

Place this line directly after the Headline Insight confidence band.
