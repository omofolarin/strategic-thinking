# Context-Driven Payoff Design

A structured framework for constructing payoff matrices that reflect real human values
rather than economic abstractions.

---

## The core insight

A payoff is a number. But that number is the *output* of a value function applied to an
outcome. The question is: **what goes into that value function?**

Every payoff can be decomposed into layers:

```
payoff = material_outcome
       + social_outcome
       + temporal_discount
       + identity_cost_or_gain
       + uncertainty_adjustment
```

Each layer is weighted differently depending on context. Culture, role, and situation
shift the weights — not the structure. This means the same framework applies universally;
only the calibration changes.

---

## The five layers

### Layer 1 — Material
What the player gains or loses in concrete, measurable terms: money, resources, market
share, physical safety.

**Questions to ask:**
- What is the measurable outcome of each action combination?
- What is the outside option — what does the player get if they don't play at all?
  (This sets the zero point. All payoffs are relative to it.)

---

### Layer 2 — Social / Relational
How the outcome affects the player's standing, relationships, and obligations.

**Questions to ask:**
- Is this a repeated relationship or a one-shot interaction?
- Does the outcome affect reputation with third parties who are watching?
- Are there reciprocity obligations — gifts, debts, favours that must be returned?
- Is there shame or honour attached to specific actions, independent of material result?

**Why this layer matters most across cultures:**
A trader in a long-term market relationship may weight social payoff at 3× the material
payoff. An anonymous online transaction weights it near zero. Same game structure,
completely different equilibrium — because the payoff matrix is different, not because
one player is irrational.

---

### Layer 3 — Temporal
How much the player discounts future outcomes relative to present ones.

**Questions to ask:**
- How long is the player's planning horizon?
- Is the relationship expected to continue, and for how long?
- Is the player under immediate pressure (financial distress, crisis) that forces
  short-term thinking?

**Important distinction:** High discount rates (impatience) are often structural, not
cultural. A player in financial distress discounts the future heavily because they must,
not because they don't value it. Confusing structural constraint with cultural preference
is a common modelling error.

Maps to: `discount_factor` in `Structure` (repeated games).

---

### Layer 4 — Identity
Whether the action aligns or conflicts with how the player sees themselves.

**Questions to ask:**
- What role is the player occupying? (parent, professional, community elder, entrepreneur)
- Are there actions that are simply "not done" in this role, regardless of material payoff?
- What would the player be ashamed to admit they did?
- What actions would they be proud to have taken even if they lost materially?

**Why this is the hardest and most predictive layer:**
A player will accept a worse material outcome to preserve identity consistency. These
constraints are not irrational — they are payoffs that happen to be very large in
magnitude and attached to self-concept rather than external outcomes.

Maps to: `BurnedBridgeTrait` (removes actions entirely — identity constraints set
certain payoffs to −∞).

---

### Layer 5 — Uncertainty
How the player responds to risk and ambiguity.

**Questions to ask:**
- Is the player risk-averse (prefers a certain smaller gain) or risk-seeking?
- Is the uncertainty about probabilities (known risk) or about the rules themselves
  (ambiguity — unknown unknowns)?
- Does the player trust the other party's stated payoffs and intentions?

Maps to: `risk_aversion` in `PlayerParameters`; `lambda` in quantal response
(`infer_from_observations`).

---

## Elicitation process

Use this sequence when constructing a payoff matrix for a real context.

**Step 1 — Anchor on the material outcome**
Start with the concrete, measurable result for each action combination. This is the
baseline everyone agrees on.

**Step 2 — Ask "what else changes?"**
For each outcome: what else is affected beyond the material result? Relationships,
reputation, self-image, obligations to others.

**Step 3 — Find the outside option**
What does the player get if they don't play at all? This is the zero point. A player
will only participate if at least one outcome exceeds this.

**Step 4 — Identify the planning horizon**
One-shot or repeated? If repeated, what is the expected duration and discount factor?
This determines how much future cooperation is worth today.

**Step 5 — Probe for identity constraints**
Are there actions the player would refuse regardless of payoff? List them. These become
`BurnedBridgeTrait` entries or −∞ payoffs in the matrix.

**Step 6 — Calibrate with observed behaviour**
If you have past observations of how this player (or players in this context) behaved,
run `infer_from_observations`. Let the data reveal what the payoffs must have been to
produce that behaviour. Compare against your elicited matrix. Discrepancies are
hypotheses to investigate, not errors to discard.

---

## Mapping to the toolkit

| Layer | Toolkit mechanism |
|---|---|
| Material | Payoff matrix values |
| Social / Relational | Payoff values + `discount_factor` (repeated structure) |
| Temporal | `discount_factor` in `Structure` |
| Identity constraints | `BurnedBridgeTrait` (removes actions) |
| Risk / uncertainty | `risk_aversion` in `PlayerParameters` |
| Bounded rationality | `rationality_factor` in `PlayerParameters` |
| Noisy optimisation | `lambda` in `infer_from_observations` |
| Unknown payoffs | `infer_from_observations` — let behaviour reveal the matrix |

---

## Common modelling errors

**Assuming material payoffs dominate.**
In many contexts — family decisions, community obligations, professional honour — social
and identity payoffs dwarf material ones. A model that ignores them will predict
defection where cooperation is observed, and conclude the players are irrational.

**Confusing structural constraint with cultural preference.**
A player who discounts the future heavily may be doing so because they have no savings
and face immediate need, not because their culture is short-termist. Fix the structural
constraint in the model before attributing the behaviour to culture.

**Treating the payoff matrix as ground truth.**
The matrix is a hypothesis. It should be updated when observed behaviour contradicts it.
The inverse solver is the correction mechanism.

**Assuming common knowledge of payoffs.**
In cross-cultural interactions, players often have different beliefs about what the other
player values. This is not a failure of rationality — it is a failure of the model to
represent asymmetric information. Use `BayesianBeliefTrait` and the inverse solver to
represent this explicitly.

---

## Key principle

> Don't ask "what is the rational choice?" Ask "what does this player value, and in what
> proportion?" The solver handles the rest.

The payoff matrix is a **model of a person's values in a specific context**. Getting it
right requires careful elicitation — sometimes ethnographic work — not just economic
assumptions. The inverse solver is your correction mechanism when you get it wrong.

---

## Related documents

- [`rationality-and-cultural-context.md`](./rationality-and-cultural-context.md) —
  what rationality means in this toolkit and why payoffs are the locus of cultural
  variation
- [`docs/glossary.md`](./glossary.md) — JGDL term and type reference
- Dixit & Nalebuff, *Thinking Strategically* (1991) — Chapters 1, 9, 11
- Schelling, *The Strategy of Conflict* (1960) — Chapter 3 (focal points as
  culturally-determined payoff salience)
- Kahneman & Tversky, prospect theory — reference-point dependence as an alternative
  payoff model for Layer 1
- Axelrod, *The Evolution of Cooperation* (1984) — how repeated interaction shifts
  Layer 2 and 3 weights
