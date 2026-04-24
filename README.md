# Strategic

[![License: Apache 2.0](https://img.shields.io/badge/license-Apache_2.0-blue.svg)](./LICENSE)
[![Status: pre-alpha](https://img.shields.io/badge/status-pre--alpha-orange.svg)](./roadmap.md)
[![JGDL: v1.0.0](https://img.shields.io/badge/JGDL-v1.0.0-lightgrey.svg)](./docs/glossary.md)

A toolkit for reasoning about situations where your best move depends on what other people will do — pricing against a competitor, negotiating a deal, deciding whether to back down in a standoff. The math that handles these situations is called **game theory**; this project is trying to be the missing tool that makes classical game theory practical to apply.

You describe a situation; it computes what rational participants should do. You feed it observations of how people actually played; it ranks hypotheses about what game they're really playing. Every conclusion carries a citation trail back to the reasoning that produced it, so a language model can explain the result without making things up — it can only quote what the engine already decided.

**Status: pre-alpha.** The Julia core is working and tested (155 passing tests, 0 failing). See [Status](#status) below for the full picture.

---

## A quick example

The classic prisoner's dilemma, written in the built-in DSL:

```julia
using Strategic

world = strategic("""
    player p1 can [cooperate, defect]
    player p2 can [cooperate, defect]
    payoff:
        (cooperate, cooperate) => (3, 3)
        (cooperate, defect)    => (0, 5)
        (defect,    cooperate) => (5, 0)
        (defect,    defect)    => (1, 1)
""")

r = solve(world, BackwardInduction())
# r.equilibrium_path  → [:defect, :defect]
# r.payoffs           → Dict(:p1 => 1.0, :p2 => 1.0)
```

Both players defecting is the "rational" answer even though they'd both be better off cooperating — the famous pathology of the one-shot game.

Now repeat the same game with tit-for-tat strategies and cooperation emerges:

```julia
r = simulate(world,
    Dict(:p1 => TitForTat(:p2), :p2 => TitForTat(:p1));
    horizon = 20, discount_factor = 0.95)
# Every round is (cooperate, cooperate).
# r.discounted_payoffs[:p1] ≈ 31.4
```

Every result carries a `provenance_chain` — a list of cited reasoning steps, each pointing to the chapter and the theoretical source. An explainer built on top can quote this chain but cannot invent.

## What's in the toolkit

The primitives map onto chapters of two books, one-to-one. You don't need to have read them — each primitive's docstring explains what it does — but the structure makes sense in their language:

- **Avinash Dixit & Barry Nalebuff, *Thinking Strategically* (1991)** — a plain-English tour of applied game theory. The 13 chapter primitives in `strategic-jl/src/chapters/` cover the book's arc: anticipating rivals (Ch 2), seeing through strategies via dominance (Ch 3), resolving the prisoner's dilemma (Ch 4), commitment devices (Ch 5), credible threats and burned bridges (Ch 6), mixed strategies (Ch 7), brinkmanship (Ch 8), coordination and focal points (Ch 9), voting (Ch 10), bargaining (Ch 11), tournaments (Ch 12), Bayesian reasoning under private information (Ch 13).
- **Thomas Schelling, *The Strategy of Conflict* (1960)** — the deeper theory of credibility, commitment, and focal points that Dixit & Nalebuff's chapters 5, 6, and 9 are built on. Schelling won the 2005 Nobel in economics for this.

Each chapter primitive is a **trait** that composes onto any base game — so you can stack commitment + brinkmanship + a Bayesian prior on a sequential entry game and the solver resolves it without ambiguity.

## Status

### Working (Phase 1 — Julia core)

| Area | What runs today |
|---|---|
| Game description | DSL macro `strategic("…")` + JGDL JSON format (both round-trip) |
| Forward solvers | Backward induction (SPE), iterated dominance, Nash equilibrium (2×2 pure + mixed), repeated-game simulation with reciprocity strategies, voting (Condorcet), Rubinstein bargaining, Bayesian first-price auction |
| Inverse solvers | Bayesian inference over hypothesis worlds, interactive narrowing, structural-break detection |
| Antifragile | Surprise detection, player discovery, latent-confounder flagging, hedge portfolio |
| Composition | Every trait registered to the dispatch-target matrix; stacked traits resolve unambiguously |
| Tests | 155 passing, 0 failing, 0 broken. The 20-case compliance suite is the acceptance bar. |

### Not yet shipped

- **Phase 2 inverse extension** — workflow UI, more hypothesis generators.
- **Phase 3 antifragile extensions** — PC-algorithm causal graph, Dirichlet-process player clustering.
- **Phase 4 — Rust MCP server.** Skeletons exist; the goal is an LLM can reach in through Claude Desktop and reason over worlds without hallucinating.
- **Phase 5 systems layer / Phase 6 WASM + web composer** — conditional on Phase 4 usage revealing demand.

See [`roadmap.md`](./roadmap.md) for the phased plan and exit criteria.

## Try it

Requires **Julia 1.10+**.

```bash
git clone <this-repo>
cd strategic-thinking

# One-time: install dependencies
julia --project=strategic-jl -e 'using Pkg; Pkg.instantiate()'

# Sanity check
julia --project=strategic-jl -e 'using Strategic; println("ok")'

# Run the compliance suite — doubles as runnable examples
julia --project=strategic-jl -e 'using Pkg; Pkg.test()'
```

The [`jgdl/compliance/tests/`](./jgdl/compliance/tests/) directory has 20 worked examples as standalone JSON files — each is a mini game with an expected solver output.

## How it's organized

```
roadmap.md, tasks.md      Vision + what's on the checklist
AGENTS.md                 Architectural contracts every contributor upholds
CLAUDE.md                 Claude Code specific notes (defers to AGENTS.md)

docs/
  composition-architecture.md    Why the toolkit composes at all
  trait-composition-contract.md  Rules every new trait must obey
  glossary.md                    JGDL term and type reference
  dsl-reference.md               Full DSL grammar with examples

jgdl/
  schema/                        JSON Schema — the serialization contract
  examples/                      Reference worlds (includes the Tales corpus)
  compliance/                    Cross-language compliance suite (20 cases)

strategic-jl/                    Julia core engine — what runs today
strategic-rs/                    Rust MCP server (Phase 4, scaffolding only)
strategic-web/                   TypeScript composer (Phase 6, conditional)

discussion.md                    The design discussion this project crystallizes
```

## Going deeper

- **"Why is this useful?"** — see the opening of [`discussion.md`](./discussion.md).
- **"How does composition work?"** — [`docs/composition-architecture.md`](./docs/composition-architecture.md).
- **"How do I write a game?"** — [`docs/dsl-reference.md`](./docs/dsl-reference.md), or read any file in [`jgdl/compliance/tests/`](./jgdl/compliance/tests/).
- **"How do I add a new trait or solver?"** — [`AGENTS.md`](./AGENTS.md) has the workflow; [`docs/trait-composition-contract.md`](./docs/trait-composition-contract.md) has the rules.

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md). The contracts in [`AGENTS.md`](./AGENTS.md) are non-negotiable — please read them before opening a PR. They aren't stylistic; they're what keep the explanation layer grounded and the solvers composable.

## License

Apache License 2.0. See [`LICENSE`](./LICENSE) for the full text and [`NOTICE`](./NOTICE) for attribution.

Copyright 2026 Folarin Shonibare.
