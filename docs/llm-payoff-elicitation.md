# LLM-Assisted Payoff Elicitation

## The problem this solves

The toolkit is a reasoning engine that needs numbers. Humans think in words, stories,
and context. Converting "my supplier has been reliable for 10 years and I'd feel bad
cheating them" into a payoff matrix is not a natural human task.

LLM-assisted elicitation bridges this gap: the LLM converts qualitative descriptions
into structured payoff estimates; the solver reasons over those estimates; the inverse
solver corrects them when observations arrive.

---

## Architecture

```
User describes situation in words
        ↓
LLM elicitation layer
(structured prompting against the 5-layer framework)
        ↓
ElicitedPayoffMatrix
(point estimates + confidence + reasoning per layer)
        ↓
StrategicWorld (aggregated payoffs passed to solver)
        ↓
Forward solver → predicted equilibrium
        ↓
User observes actual behaviour
        ↓
Inverse solver → corrects payoffs toward what behaviour implies
        ↓
Updated world (better calibrated over time)
```

The LLM handles words → structure. The solver handles structure → prediction.
The inverse solver closes the loop: observation → correction.

---

## Why structured elicitation beats asking the LLM to "solve" the game

If you ask an LLM "what will player A do?", it pattern-matches to training data and
produces an answer with no grounding. It may be right, but you cannot verify or correct
it.

If instead the LLM produces a payoff matrix with layer-by-layer reasoning, and the
solver produces the equilibrium:

- The LLM's contribution is **auditable** — each number is justified against a specific layer
- The solver's contribution is **deterministic** — same matrix → same equilibrium
- The inverse solver can **correct** the LLM's estimates when behaviour diverges
- The **provenance chain** records everything, so explanations are grounded

The LLM becomes a structured elicitation interface, not an oracle.

---

## The elicitation prompt structure

The prompt is structured against the five layers from
[`context-driven-payoff-design.md`](./context-driven-payoff-design.md), not open-ended.
Structure prevents free hallucination — the LLM must justify each number against a
specific layer.

```
Given this situation: [user description]

For each outcome, estimate the payoff for each player across five layers:

1. Material: what concrete gain/loss occurs?
2. Social: how does this affect relationships and reputation?
3. Temporal: is this one-shot or repeated? What is the discount factor?
4. Identity: does this action align with how the player sees themselves?
5. Uncertainty: how risk-averse is this player?

For each estimate provide:
- A point estimate (number, relative to the outside option = 0)
- A confidence level (0.0–1.0)
- One sentence of reasoning
```

---

## Julia types

Defined in `src/elicitation/payoff_elicitation.jl`.

### `PayoffLayerEstimate`

A single layer's contribution to one player's payoff in one outcome.

```julia
struct PayoffLayerEstimate
    layer::Symbol          # :material | :social | :temporal | :identity | :uncertainty
    point_estimate::Float64
    confidence::Float64    # 0–1
    reasoning::String
    provenance::ProvenanceNode
end
```

### `ElicitedOutcomePayoff`

All five layers for one player in one outcome, plus the aggregated total.

```julia
struct ElicitedOutcomePayoff
    player_id::Symbol
    outcome_key::String           # e.g. "cooperate_1.cooperate_2"
    layers::Vector{PayoffLayerEstimate}
    total::Float64                # sum of point_estimates
    mean_confidence::Float64      # average confidence across layers
end
```

### `ElicitedPayoffMatrix`

The full elicitation result. `to_payoff_matrix()` extracts the aggregated numbers
for the solver; the layer breakdown stays in provenance.

```julia
struct ElicitedPayoffMatrix
    description::String                      # original natural language input
    entries::Vector{ElicitedOutcomePayoff}
    elicitation_provenance::ProvenanceNode   # records the elicitation session
end
```

### `build_world_from_elicitation`

Constructs a `StrategicWorld` from an `ElicitedPayoffMatrix`. The aggregated payoffs
go into the world's metadata; the layer breakdown is recorded in provenance so the
LLM explanation layer can cite specific reasoning.

---

## Phase 4 MCP tool

The natural tool to expose in the MCP server (Phase 4):

```
elicit_world(description: string) -> StrategicWorld
```

Workflow:
1. LLM calls `elicit_world` with a natural language description
2. Tool runs structured elicitation prompt, produces `ElicitedPayoffMatrix`
3. Tool calls `build_world_from_elicitation` → `StrategicWorld` with full provenance
4. LLM calls `solve_world` on the returned world
5. LLM calls `explain_from_provenance` — explanation cites layer reasoning, not free text

This fits the existing provenance contract: every claim in the LLM's explanation traces
to a `ProvenanceNode` that records which layer estimate produced it and why.

---

## Confidence and correction

Low-confidence estimates are not a problem — they are information. A world constructed
from low-confidence elicitation should be treated as a prior, not a ground truth.

The correction loop:
1. Elicit world from description (prior)
2. Solve → predict equilibrium
3. Observe actual behaviour
4. Run `infer_from_observations` → posterior over payoff hypotheses
5. Update the world's payoff matrix toward the posterior
6. Re-solve with updated payoffs

Over time, the elicited payoffs converge toward the true values revealed by behaviour.
The LLM's initial estimates become less important as observations accumulate.

---

## Related

- [`context-driven-payoff-design.md`](./context-driven-payoff-design.md) — the five-layer framework
- [`rationality-and-cultural-context.md`](./rationality-and-cultural-context.md) — why payoffs are the locus of cultural variation
- `src/elicitation/payoff_elicitation.jl` — Julia implementation
- `roadmap.md` Phase 4 — MCP server where `elicit_world` tool lives
