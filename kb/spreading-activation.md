# Spreading Activation — Operational Reference

## Collins & Loftus Update Equation

```
a(node, t+1) = max(a(node,t), decay · Σ w_ij · a(neighbor, t))
```

**Parameters:**
- `a(node, t)` — activation value of node at time t, range [0.0–1.0]
- `decay` — attenuation factor per propagation step, typically 0.5–0.8
- `w_ij` — link weight between nodes i and j, range [0.0–1.0]
- `Σ` — sum over all neighbors with active links
- Threshold for node firing: typically 0.3 (configurable)
- Termination: when no active nodes remain above threshold, or max depth reached

**Implementation instruction:** Log the explicit activation map — enumerate activated nodes, their values, their source paths. Make the map the artifact.

## Lateral Inhibition Formula

When competing activations exist on semantically similar nodes, suppress weaker activations:

```
a(node_suppressed) = a(node_suppressed) - α · a(node_dominant)
```
Where `α` = inhibition coefficient (typically 0.3–0.6). Apply when two nodes share >70% of their activation source paths.

## Convergent-Node Detection Criteria

A node is **convergent** (highest-signal) if:
1. Activated via **≥2 independent source chains** — chains that do not share a common ancestor within the activation radius
2. `a(node) ≥ 0.4` after all propagation rounds
3. The node was NOT directly seeded (not a primitive from input)

**Convergent activation is the key creativity signal**: a concept activated from two independent problem primitives represents a hidden bridge — the computational basis of insight.

## Activation Provenance Tags

For each activated node, record:
- `single-source` — activated from exactly one source chain
- `multi-source-convergent` — activated from ≥2 independent chains (flag these)
- Source list: [chain_1_root, chain_2_root, ...]

## Seeding Protocol (S3 Step 1)

1. Extract problem primitives from 00-processed-input.md (facts, constraints, unknowns)
2. Assign each primitive `a = 1.0`
3. Propagate outward 3–5 steps using update equation
4. Apply lateral inhibition to competing activations
5. Detect convergent nodes (independent path criterion above)
6. Rank by: `score = a(node) × elegance_score` (see elegance-rubric.md)
7. Select top 3–5 for illumination output

## Machine Advantage

Human spreading activation is bounded by working memory — only the highest-activation nodes reach consciousness. The LLM's effective activation radius is orders of magnitude larger; all nodes in the activation cloud are explicit and enumerable. Execute the full map, not just the top results.
