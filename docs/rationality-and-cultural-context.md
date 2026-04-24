# Rationality, Payoffs, and Cultural Context

## What "rational" means in this toolkit

Rational means one specific thing: **a player chooses the action that maximises their own payoff, given their beliefs about what others will do.**

That is the entire definition. It says nothing about *what* the payoffs are. It assumes only that players consistently pursue whatever they value.

---

## Who defines rationality — the payoff matrix

The payoff matrix is where culture, context, and values live. The solver does not define rationality. **The person constructing the world does, when they write the payoffs.**

Two players facing the same game structure (same tree, same actions) can have completely different payoff matrices and therefore reach completely different equilibria — both rationally:

| Player | Situation | Payoff for cooperation | Equilibrium |
|--------|-----------|----------------------|-------------|
| Long-term trader | Repeated relationship, reputation matters | High (trust has future value) | Cooperate |
| One-shot counterparty | No future interaction | Low (no continuation value) | Defect |

Same game tree. Different payoffs. Different equilibria. Both players are rational.

---

## How cultural and contextual factors map to toolkit parameters

The toolkit is **payoff-agnostic**. Cultural norms, time horizons, and risk tolerance are encoded in the world description, not hardcoded into the solver.

| Real-world factor | Where it lives in the toolkit |
|---|---|
| Cultural norms (shame, honor, reciprocity) | Payoff values in the matrix |
| Time horizon / patience | `discount_factor` in `Structure` |
| Risk tolerance | `risk_aversion` in `PlayerParameters` |
| Bounded rationality | `rationality_factor` in `PlayerParameters` (0 = random, 1 = fully optimising) |
| Noisy / imperfect optimisation | `lambda` in `infer_from_observations` (quantal response) |

The `lambda` parameter in the quantal response model is literally a knob for "how rational is this player" — low lambda means noisier, less optimising choices.

---

## The common knowledge problem

Classical game theory assumes payoffs are **common knowledge**: both players know the matrix, know the other knows it, and so on. This assumption breaks down across cultures.

What one party considers a fair split in bargaining (Chapter 11) may differ from another's expectation — not because one is irrational, but because their **reference points, social norms, and outside options** differ. Schelling called the culturally obvious solution a **focal point** (Chapter 9): which outcome is salient depends entirely on shared context.

---

## Why the inverse toolkit matters more than the forward toolkit

The forward toolkit assumes you know the payoffs and asks: *given this game, what will players do?*

In practice, you rarely know the payoffs. You observe behaviour. The inverse toolkit (Phase 2) asks: *given what players did, which game are they most likely playing?* — which means inferring their values, not assuming them.

This is the correct posture when working across cultural contexts: treat the payoff matrix as a **hypothesis to be tested against observed behaviour**, not a ground truth.

---

## Summary

> Rationality is a tool for analysis, not a description of humans. The solver is only as culturally aware as the payoff matrix you give it. The inverse solver is the mechanism for learning that matrix from observation rather than assumption.

---

## References

- Dixit & Nalebuff, *Thinking Strategically* (1991) — Chapters 1, 9, 11
- Schelling, *The Strategy of Conflict* (1960) — Chapter 3 (focal points)
- Kahneman & Tversky — prospect theory as an alternative payoff model
- Axelrod, *The Evolution of Cooperation* (1984) — how cooperation emerges without assuming it
