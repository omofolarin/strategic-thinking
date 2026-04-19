# Strategic

[![License: Apache 2.0](https://img.shields.io/badge/license-Apache_2.0-blue.svg)](./LICENSE)
[![Status: pre-alpha](https://img.shields.io/badge/status-pre--alpha-orange.svg)](./roadmap.md)
[![JGDL: v1.0.0](https://img.shields.io/badge/JGDL-v1.0.0-lightgrey.svg)](./docs/glossary.md)

A composable toolkit for strategic reasoning, grounded in Dixit & Nalebuff's *Thinking Strategically* (with roots in Schelling's *Strategy of Conflict*).

**Status:** pre-alpha. Scaffolding complete; Phase 0 (JGDL as the contract) is the next deliverable. See `roadmap.md`.

---

## What this is

Not a case-study catalog. Not a chat wrapper around game theory. A set of primitives users compose to sculpt strategic worlds the authors never anticipated — in both directions:

- **Forward:** rules → behavior. *"Given this game, what will rational players do?"*
- **Inverse:** behavior → rules. *"Given what we observed, what game are they actually playing?"*

Every composition step leaves a citation trail (provenance) so an LLM explanation layer can ground every claim in the chapter and rationale that produced it — no hallucination.

## Guiding principles

1. **Composition is the product.** The quality bar is whether a user can stack `Brinkmanship + Bayesian + Tournament` on a sequential game and get coherent semantics.
2. **Forward and inverse are peers.** Equal compositional surface in both directions; inverse is not a sidecar.
3. **Provenance is the substrate for explanation.** Every trait application, every inverse hypothesis, every hedge activation leaves a cited node. The LLM layer reads from this graph, never narrates from thin air.
4. **Antifragile tools are user-invoked affordances.** The user reaches for `detect_surprise` or `discover_player` when analysis feels incomplete. They are not autonomous.
5. **Each phase earns the next** through demonstrated usage. No Rust until Julia proves the primitives compose. No web composer until MCP proves worth.

## Layout

```
roadmap.md                      Strategic vision, phased
tasks.md                        Concrete per-phase checklists
AGENTS.md                       Contracts every contributing agent must uphold
CLAUDE.md                       Claude Code specific notes (defers to AGENTS.md)

docs/
  composition-architecture.md   Why the toolkit composes at all (the four layers)
  trait-composition-contract.md Normative rules every trait must obey
  glossary.md                   JGDL term and type reference

jgdl/                           Shared JSON Game Description Language
  schema/                       JSON Schema v1.0.0 — the load-bearing contract
  examples/                     Reference JGDL documents (includes tales/)
  compliance/                   Cross-language compliance suite

strategic-jl/                   Julia core engine (Phases 1–3)
strategic-rs/                   Rust MCP server + WASM (Phase 4, 6)
strategic-web/                  TypeScript composer + provenance viz (Phase 6)

discussion.md                   The architectural exploration that produced this
```

## Status by phase

| Phase | Focus | State |
|---|---|---|
| 0 | JGDL as the contract | schema drafted, compliance suite skeleton in place |
| 1 | Forward toolkit (Julia) | foundation chapters (1–4) and modifiers (5–8) scaffolded |
| 2 | Inverse toolkit | stubs only |
| 3 | Antifragile affordances | stubs only |
| 4 | MCP server (Rust) | workspace + crate skeletons |
| 5 | Systems-thinking layer | not started (conditional on Phase 4 usage) |
| 6 | WASM + web composer | TypeScript scaffold only (conditional) |

## For contributors (human or agent)

Before touching code, read in this order:

1. `AGENTS.md` — contracts you must uphold
2. `docs/composition-architecture.md` — why the toolkit composes
3. `docs/trait-composition-contract.md` — rules for trait authors
4. `roadmap.md` + `tasks.md` — what to work on next

## For readers orienting themselves

Start with `discussion.md` — the full architectural exploration (build-the-world toolkit, forward/inverse symmetry, antifragile extensions, systems layer) that the roadmap crystallizes.

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md). The architectural contracts in [`AGENTS.md`](./AGENTS.md) are non-negotiable — please read them before opening a PR.

## License

Licensed under the Apache License, Version 2.0. See [`LICENSE`](./LICENSE) for the full text and [`NOTICE`](./NOTICE) for attribution.

Copyright 2026 Folarin Shonibare.
