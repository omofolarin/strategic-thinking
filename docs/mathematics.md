# Mathematics of the JGDL Toolkit

Five distinct pieces of mathematics underpin the toolkit. This document explains each
one precisely, with the formulas that appear in the implementation.

---

## 1. The game — expected utility and equilibrium

Every player solves the same problem: choose the action that maximises expected payoff.

### Simultaneous games

Player *i* chooses action *aᵢ* to maximise:

```
Uᵢ(aᵢ, a₋ᵢ)
```

where *a₋ᵢ* is the joint action of all other players. The problem is circular: each
player's best choice depends on what they believe others will do, which depends on what
others believe about them.

**Nash equilibrium** resolves this as a fixed point. A strategy profile *(a₁\*, ..., aₙ\*)*
is a Nash equilibrium iff no player can improve by unilaterally deviating:

```
Uᵢ(aᵢ*, a₋ᵢ*) ≥ Uᵢ(aᵢ, a₋ᵢ*)   for all aᵢ, for all i
```

Implemented by: `solve(world, BackwardInduction())` for simultaneous games (best-response
enumeration), `solve(world, IteratedDominance())` for dominance-solvable games.

### Sequential games — backward induction

Start at the last decision node. The last mover picks their best action. Step back one
level: the previous mover now knows what the last mover will do, so they pick their best
response. Repeat to the root.

The result is the **subgame-perfect equilibrium (SPE)**: a Nash equilibrium that remains
rational at every decision point, not just the starting state.

```
V(node) = max_{a ∈ actions(node)} U(a, V(children(node)))
```

Implemented by: `_solve_sequential` in `solvers/forward/backward_induction.jl`.

### Iterated dominance

Action *a* **strictly dominates** action *b* for player *i* if:

```
Uᵢ(a, s₋ᵢ) > Uᵢ(b, s₋ᵢ)   for all opponent strategy profiles s₋ᵢ
```

Iterated elimination removes dominated actions, then repeats on the reduced game until
no further eliminations are possible. The surviving actions are the **rationalizable set**.

Implemented by: `solve(world, IteratedDominance())` in `solvers/forward/dominance.jl`.

---

## 2. The inverse solver — Bayesian inference with quantal response

Given observations of behaviour, which game are the players most likely playing?

### Bayesian update

You have hypothesis worlds *W₁, ..., Wₙ* with prior probabilities *P(Wᵢ)*. After
observing action *a* by player *p*, Bayes' rule gives the posterior:

```
P(Wᵢ | a) = P(a | Wᵢ) × P(Wᵢ) / Σⱼ P(a | Wⱼ) × P(Wⱼ)
```

After *n* independent observations:

```
P(Wᵢ | a₁, ..., aₙ) ∝ P(Wᵢ) × ∏ₜ P(aₜ | Wᵢ)
```

In log space (used in the implementation for numerical stability):

```
log P(Wᵢ | observations) = log P(Wᵢ) + Σₜ log P(aₜ | Wᵢ) − log Z
```

where *log Z* is the log-normalisation constant computed via log-sum-exp.

### Quantal response likelihood

A fully rational player always picks the best action. Real players pick better actions
more often but not always. The **quantal response** model gives:

```
P(a | W, p, λ) = exp(λ × U(a)) / Σₐ' exp(λ × U(a'))
```

This is a softmax over expected payoffs. *λ* (lambda) is the rationality parameter:

| λ | Behaviour |
|---|---|
| λ → ∞ | Fully rational — always picks the best action |
| λ = 1 | Default — moderate rationality |
| λ = 0 | Completely random — uniform over all actions |

In log space:

```
log P(a | W, p, λ) = λ × U(a) − log Σₐ' exp(λ × U(a'))
```

The denominator is computed as:

```
log-sum-exp(x) = max(x) + log Σᵢ exp(xᵢ − max(x))
```

This avoids numerical overflow when payoffs are large.

Implemented by: `infer_from_observations` in `solvers/inverse/bayesian_inference.jl`.

---

## 3. Structural break detection — log-likelihood ratio test

Given a sequence of observations, has the player's behaviour changed at some point?

### Frequency models

Split observations into an early window (first half) and a late window (second half).
Estimate the action frequency distribution from each:

```
P_early(a | p) = count(a in early obs for player p) / total early obs for p
P_late(a | p)  = count(a in late obs for player p)  / total late obs for p
```

### Cumulative log-likelihood ratio

For each candidate break point *t*, compute:

```
LLR(t) = Σᵢ₌₁ᵗ [ log P_early(aᵢ) − log P_late(aᵢ) ]
```

This measures how much better the early model explains the first *t* observations
compared to the late model.

- If behaviour is consistent throughout: LLR stays near zero
- If there is a structural break: LLR grows large in magnitude at the break point

A break is flagged at round *t+1* when `|LLR(t)| > threshold`. The threshold is a free
parameter — higher values require stronger evidence.

When a break is detected, the hypothesis `objective_function_changed` is raised: the
player's payoff structure likely shifted at that point.

Implemented by: `detect_structural_break` in `solvers/inverse/structural_break.jl`.

---

## 4. Content addressing — SHA-256

Every `world.id` is a cryptographic hash of the world's content:

```
world.id = "sha256:" + hex(SHA256(canonical_json(world \ {id})))
```

SHA-256 maps any input to a 256-bit (64 hex character) digest with two properties:

- **Deterministic**: same content → same hash, always, on any machine
- **Collision-resistant**: different content → different hash (with probability 1 − 2⁻²⁵⁶)

This is how the toolkit achieves reproducibility across Julia, Rust, and TypeScript: if
all three produce the same canonical JSON for the same world, they produce the same hash.
The hash is also the storage key for `Strategic.save` / `Strategic.load`.

Two worlds with the same `id` are guaranteed to have the same content. Two worlds with
the same content but different `traits` ordering have different `id`s — composition order
is semantically significant and the hash captures it.

Implemented by: `world_id` in `jgdl/serialize.jl`; `SHA.sha256` from the SHA.jl stdlib.

---

## 5. Payoff elicitation — additive decomposition

The simplest mathematics in the system. A payoff is the sum of five layer estimates:

```
payoff(player, outcome) = Σ_{layer ∈ {material, social, temporal, identity, uncertainty}} point_estimate(layer)
```

Mean confidence is the arithmetic mean across layers:

```
mean_confidence = (1/n) × Σᵢ confidenceᵢ
```

No fixed weighting between layers is imposed. The weights are implicit in the estimates:
if social payoff matters more in a given context, the elicitor (LLM or human) assigns a
larger social estimate. This keeps the framework culturally neutral — the mathematics
does not privilege any layer.

`mean_confidence` below 0.5 signals the world should be treated as a weak prior and
corrected aggressively by the inverse solver as observations arrive.

Implemented by: `ElicitedOutcomePayoff`, `build_world_from_elicitation` in
`elicitation/payoff_elicitation.jl`.

---

## Summary

| Component | Mathematics | Implementation |
|---|---|---|
| Forward solver (simultaneous) | Nash equilibrium, best-response enumeration | `backward_induction.jl` |
| Forward solver (sequential) | Backward induction, SPE | `backward_induction.jl` |
| Forward solver (dominance) | Iterated elimination of dominated strategies | `dominance.jl` |
| Inverse solver | Bayesian posterior update, quantal response softmax, log-sum-exp | `bayesian_inference.jl` |
| Structural break | Cumulative log-likelihood ratio test | `structural_break.jl` |
| Content addressing | SHA-256 cryptographic hash | `serialize.jl` |
| Payoff elicitation | Additive decomposition, arithmetic mean | `payoff_elicitation.jl` |

---

## References

- Nash, *Non-Cooperative Games* (1951) — Nash equilibrium
- Selten, *Reexamination of the Perfectness Concept* (1975) — subgame perfection
- McKelvey & Palfrey, *Quantal Response Equilibria* (1995) — quantal response model
- Dixit & Nalebuff, *Thinking Strategically* (1991) — the textbook this toolkit operationalises
- NIST FIPS 180-4 — SHA-256 specification
