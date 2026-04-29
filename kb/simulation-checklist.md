# Tesla Simulation Checklist — Operational Reference (S4)

## Purpose

Nikola Tesla's method: visualize the complete system operating, then search systematically for points of failure before any physical construction. Applied to problem-solving: simulate the system from S1 primitives, advancing state through time and parameter space, flagging structural failures.

---

## Pre-Simulation Setup

Before running the checklist, construct a system model from S1 primitives:
1. Identify system components and their initial states
2. Identify driving forces (what causes the system to evolve)
3. Identify coupling between components
4. State the nominal operating condition (what "working correctly" looks like)

---

## Checklist Category 1 — Energy/Resource Imbalances

For each pair of coupled components:
- [ ] Does component A consume resources faster than component B can supply them? (starvation scenario)
- [ ] Does component A produce outputs faster than component B can process them? (overflow scenario)
- [ ] Is there a feedback loop that amplifies small imbalances into large ones? (runaway)
- [ ] Is there a hidden assumption that flow is symmetric in both directions when it may not be?

**Flag as imbalance:** Any yes-answer. State: `[IMBALANCE] [component A] → [component B]: [nature of imbalance]`

---

## Checklist Category 2 — Singularities (Points Where Behavior Becomes Undefined)

For each parameter in the system:
- [ ] Does the system's behavior become undefined when [parameter] → 0?
- [ ] Does the system's behavior become undefined when [parameter] → ∞?
- [ ] Is there a division or ratio in the system dynamics where the denominator can reach zero?
- [ ] Is there a threshold or switching condition that produces discontinuous behavior?

**Flag as singularity:** Any yes-answer. State: `[SINGULARITY] at [parameter = value]: [what becomes undefined]`

---

## Checklist Category 3 — Limit Cases (Boundary Regime Tests)

Test the system at each of the following boundary regimes:
- [ ] **All parameters at minimum:** Does the system still operate? What degrades?
- [ ] **All parameters at maximum:** Does the system saturate, fail, or enter unexpected state?
- [ ] **One parameter at minimum, all others nominal:** For each parameter in turn.
- [ ] **System at empty state:** No inputs, no stored state — does initialization work correctly?
- [ ] **System under rapid change:** If an input changes from min to max instantaneously, what happens?

**Flag as limit case failure:** Any case where behavior is incorrect, undefined, or qualitatively different from nominal. State: `[LIMIT-CASE] at [regime]: [observed behavior vs. expected behavior]`

---

## Checklist Category 4 — Theory Collisions (Points Where Two Claims Predict Different Outcomes)

For each pair of facts/constraints from S1:
- [ ] Does claim A predict that the system evolves in direction X?
- [ ] Does claim B predict that the system evolves in direction Y?
- [ ] If X ≠ Y: this is a theory collision. Which claim governs under what conditions?
- [ ] Is there a scenario where both claims are active simultaneously? What happens?

**Flag as theory collision:** State:
```
[COLLISION]
Claim A: [exact statement from S1]
Claim B: [exact statement from S1]
Predicted outcome A: [...]
Predicted outcome B: [...]
Discriminating condition: [what experimental/observational setup would reveal which is correct?]
```

---

## Imbalance Genuineness Check (Verification)

For each flagged imbalance, singularity, or limit-case failure:
- Is the failure structural (inherent to the system design) or incidental (artifact of how the problem was framed)?
- Is the failure robust (occurs under any instantiation of the system) or fragile (specific to one parameterization)?
- If incidental or fragile: downgrade to advisory; note the specific condition required for the failure to appear.

Only structural, robust failures are promoted to Theory Collisions in the output. Advisory failures are still recorded but marked as lower-priority.

---

## Output Format

```
## System Model
[brief description of components, states, coupling]

## Imbalances Found
[IMBALANCE] ...

## Singularities Found
[SINGULARITY] ...

## Limit-Case Failures
[LIMIT-CASE] ...

## Theory Collisions
[COLLISION]
Claim A: ...
Claim B: ...
Discriminating condition: ...

## Genuineness Assessment
[For each flagged item: structural or incidental? Keep or downgrade?]
```
