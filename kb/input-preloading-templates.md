# Input Pre-loading Templates — Operational Reference (S1)

## Usage

Detect input class from 00-processed-input.md, then apply the matching template to structure primitive enumeration. Templates define minimum categories and count requirements (≥20 per category).

---

## Class Detection

| Class | Signal |
|-------|--------|
| Algorithmic | Code snippets, pseudocode, performance/complexity language, data structure references |
| Design | Architecture decisions, trade-offs, UX/UI, system design, API surface, constraints between components |
| Proof | Mathematical notation, "prove that", "show that", logical claims, formal definitions |
| Diagnostic | "Why is X not working", error messages, unexpected behavior, debugging, root-cause |
| Other | Conceptual question, open-ended research, strategic/planning, creative synthesis |

---

## Template 1 — Algorithmic

**Primitive categories (enumerate ≥20 per category):**

1. **Facts known** — What does the code/algorithm currently do? What are its guaranteed properties?
2. **Constraints** — Time complexity bounds, space bounds, input size assumptions, ordering guarantees, data structure requirements
3. **Unknowns** — What behavior is unspecified? What edge cases are unhandled?
4. **Failed approaches** — Which implementations have been attempted and why did they fail (not just that they failed)?
5. **Performance measurements** — Specific timings, throughput numbers, bottleneck locations if known
6. **Input invariants** — What can be assumed about inputs that isn't explicitly stated?
7. **Adjacent operations** — What other operations operate on the same data? Are there ordering dependencies?

**Tesla measurement plan:** State what an observable success would measure — specific complexity class achieved, specific runtime on specific input size, specific correctness property verified.

---

## Template 2 — Design

**Primitive categories (enumerate ≥20 per category):**

1. **Components** — What are the system components? What does each do independently?
2. **Interfaces** — What are the communication contracts between components? Which are hard vs. soft?
3. **Known constraints** — Performance SLAs, team/org constraints, technology mandates, budget
4. **Quality attributes** — Scalability, maintainability, testability, security — what is actually required vs. desirable?
5. **Stakeholder requirements** — Explicit vs. implicit needs; who owns which requirements?
6. **Trade-off history** — What design decisions have been made and what was sacrificed?
7. **Failure modes** — What can go wrong in each component? What cascade failure paths exist?

**Tesla measurement plan:** State what observable success means — latency under load, adoption metrics, deployment frequency, rollback rate.

---

## Template 3 — Proof

**Primitive categories (enumerate ≥20 per category):**

1. **Definitions** — All formal definitions in use (stated verbatim, not paraphrased)
2. **Axioms/given facts** — What is assumed without proof?
3. **Target claim** — The exact statement to be proved (verbatim, then formalized)
4. **Known partial results** — What has been proven? What lemmas are available?
5. **Failed proof attempts** — Which proof strategies were tried? Where did they break down?
6. **Analogous results** — What structurally similar theorems exist in the literature?
7. **Necessary conditions** — What must be true for the claim to hold? What counterexamples might exist?

**Tesla measurement plan:** State what a complete proof must contain — each step, each lemma invoked, verifiable by checking each inference independently.

---

## Template 4 — Diagnostic

**Primitive categories (enumerate ≥20 per category):**

1. **Observed symptoms** — Exact error messages, observed behaviors, unexpected outputs (verbatim)
2. **Expected behavior** — What should happen instead? Under what conditions?
3. **Reproduction conditions** — What triggers the problem? Is it consistent or intermittent?
4. **System state** — Environment, version, configuration, recent changes
5. **Hypotheses tested** — What causes have been ruled out? How was each ruled out?
6. **Causal candidates** — What could still explain the symptom? (full list including unlikely)
7. **Interactions** — What other system components interact with the failing component?

**Tesla measurement plan:** State how the fix will be verified — specific test, specific reproduction steps that should now pass.

---

## Template 5 — Other (Conceptual / Strategic / Creative)

**Primitive categories (enumerate ≥20 per category):**

1. **Core claim/question** — What is the central thing being asked or asserted?
2. **Background facts** — What is established about the topic?
3. **Key tensions** — Where do competing considerations pull in different directions?
4. **Stakeholders** — Who is affected by the answer? What do they value?
5. **Analogous domains** — What areas have faced similar structural questions?
6. **Success criteria** — What would a good answer or solution look like?
7. **Open sub-questions** — What questions must be answered before the main question?

**Tesla measurement plan:** State what an observable outcome looks like — decision made with what properties, insight with what consequences, product with what behavior.

---

## Count Requirement

For each category: enumerate ≥20 primitives. If fewer than 20 candidates genuinely exist in the input, state the cap explicitly: "Input contains [N] [category] primitives; 20-item target not met — constraint is the input, not enumeration."

Do NOT fabricate primitives to meet the count. Honesty about the cap is a data point, not a failure.

## Simplicity-Stripping (S1 Step 3)

After enumeration, apply simplicity stripping:
1. Remove all scaffolding: framing language, transitional phrases, meta-commentary about the problem
2. Keep irreducibles: facts, constraints, unknowns that cannot be derived from others in the list
3. Mark dependencies: if primitive B follows from primitive A, strike B and note the derivation
