# Strategic Roadmap

## Framing

This is not a platform. It's a **toolkit**: composable primitives for strategic reasoning, built so users can sculpt worlds the authors never anticipated.

The guiding principles, in order of priority:

1. **Composition is the product.** The quality bar is whether a user can stack `Brinkmanship + Bayesian + Tournament` on a sequential game and get coherent semantics — not whether we shipped a case-study catalog.
2. **Forward and inverse are peers.** `world → analysis` (what will rational players do?) and `analysis → world` (what game are they actually playing?) must have equal compositional surface. Inverse is not a sidecar.
3. **Provenance is the substrate for explanation.** Every trait application, every inverse hypothesis, every hedge activation leaves a cited node in the provenance graph. The LLM layer reads from this graph — it does not narrate from thin air.
4. **Antifragile tools are discovery affordances, not a research project.** The user reaches for `detect_surprise` or `discover_player` when their analysis feels incomplete. They are invoked, not autonomous.
5. **Ship the toolkit, let usage earn the next layer.** Rust, WASM, systems-thinking integration — none of these are built until a concrete user friction demands them.

## The Stack (layered, each layer earns the next)

| Layer | Purpose | When it ships |
|---|---|---|
| **JGDL** | Serialization contract, source of truth | Phase 0 |
| **Strategic.jl core** | Primitives, trait composition, forward solver | Phase 1 |
| **Inverse solver** | Observations → candidate worlds | Phase 2 |
| **Antifragile tools** | Surprise, player discovery, hedges | Phase 3 |
| **MCP server (Rust)** | LLM access via provenance graph | Phase 4 |
| **Systems-thinking layer** | Stocks/flows/loops overlay | Phase 5 (if earned) |
| **WASM + web composer** | Browser-native world building | Phase 6 (if earned) |

## Phases

### Phase 0 — JGDL as the Contract (Weeks 1–2)

The schema is load-bearing. Everything else regenerates from it.

- JGDL v1.0.0 JSON schema, frozen and versioned
- 20 hand-written compliance cases covering Chapters 1–13, with expected equilibria
- Validator (language-agnostic, runs on raw JSON)

**Exit criterion:** A JGDL file round-trips through any future implementation and the schema validator catches malformed worlds before a solver sees them.

### Phase 1 — Forward Toolkit (Weeks 3–6)

Julia-only. Small, composable, stress-tested. **The foundation chapters (1–4) are the substrate** — they must land before any Chapter 5+ modifier.

Foundation (Ch 1–4):
- **Ch 1** — Ten Tales corpus: five canonical JGDL fixtures authored (`jgdl/examples/tales/`) with the other five stubbed
- **Ch 2** — Sequential structure invariants + `BackwardInduction` solver, memoized
- **Ch 3** — `IteratedDominance` solver; `RationalizableSet` usable both forward (prune tree) and inverse (rationality check)
- **Ch 4** — Reciprocity strategy types (`TitForTat`, `GrimTrigger`, `Pavlov`, `GenerousTFT`) wired into the repeated-game structure

Core plumbing:
- Core types: `StrategicWorld`, `Player`, `Action`, `State`, `LazyGameTree`, `ProvenanceNode`
- Trait composition via wrapper types (`WithTrait{G, T}`)

Modifier chapters (on top of the foundation):
- Chapters 5, 6, 7, 8 traits implemented and *stacked*

Surface:
- `@strategic` DSL macro (minimum viable)
- Pluto notebook: interactive explorer

**Exit criteria:**
1. All five authored Tales round-trip through JGDL and solve to their expected outcomes.
2. User can stack 3+ modifier traits on a Ch 1–4 base game, dispatch resolves unambiguously.
3. Compliance suite passes for Ch 1–8 cases.

### Phase 2 — Inverse Toolkit (Weeks 7–10)

Symmetry with forward. Same DSL, same compositional surface.

- `ObservedPlay` type, observation streams
- Hypothesis space generators (parametric first, nonparametric in Phase 3)
- Bayesian likelihood under behavioral noise
- Interactive hypothesis narrowing (not a single Bayesian update — a workflow)
- Provenance captures which hypotheses were considered and why each was ruled in/out

**Exit criterion:** Given 10 observations, the system returns a ranked posterior over candidate worlds, each with a provenance chain explaining the fit.

### Phase 3 — Antifragile Affordances (Weeks 11–14)

Tools the user invokes when their model feels suspect.

- Open-world extension to JGDL (shadow player, emergence rate)
- `SurpriseDetector` with mutation templates
- `DirichletProcess` player discovery (start parametric, upgrade to DP)
- Causal graph with latent-node flagging
- Hedge portfolio primitive

**Exit criterion:** When fed observations that violate the current world model, the system flags the anomaly, proposes ranked mutations, and never silently "becomes less confident."

### Phase 4 — LLM Access via MCP (Weeks 15–18)

Rust layer. Reads from provenance, not from free text.

- `strategic-core` Rust mirror of JGDL (serde)
- `strategic-solver` fast backward induction (validates against Julia oracle)
- `strategic-mcp` server exposing tools: `instantiate_world`, `solve_world`, `mutate_world`, `infer_from_observations`, `detect_surprise`, `explain_from_provenance`
- Session + content-addressable world storage

**Exit criterion:** An LLM in Claude Desktop can instantiate, mutate, solve, and explain a world without hallucinating — every explanation cites a provenance node.

### Phase 5 — Systems Layer (conditional)

Only if Phase 1–4 usage reveals users hitting the "game equilibrium ≠ long-run dynamics" wall.

- Opt-in `with_systems(world, stocks, flows, loops)`
- Strategic move → feedback loop inference
- Basin-of-attraction analysis
- Export to Stella/Vensim

### Phase 6 — WASM + Web Composer (conditional)

Only if server-round-trip latency or deployment cost becomes real friction.

- `strategic-wasm` compile target
- TypeScript composer: drag-and-drop world building
- Provenance graph visualizer
- Explanation panel wired to MCP

## What "Done" Looks Like for v1.0

A user can:

1. Describe a strategic situation in natural language.
2. See it composed into a JGDL world with cited chapter primitives.
3. Solve it forward; see the equilibrium with provenance-grounded explanation.
4. Feed observations and have the system narrow to the game actually being played.
5. Ask "what am I missing?" and get ranked hypotheses about unmodeled players, payoff shifts, or confounders.
6. Export the entire analysis as a hash-addressable artifact that reproduces exactly elsewhere.

## Non-goals (explicit)

- Not building a case-study catalog. Case studies are tests, not features.
- Not chasing a closed-form Nash solver for large games. Lazy + approximate + explainable beats exact + opaque.
- Not auto-generating strategy. The tool gives the user a sharper lens; the user still does the thinking.
- Not a chat wrapper. The LLM layer explains what the engine produced; it does not substitute for the engine.

## Risk Register

| Risk | Mitigation |
|---|---|
| Trait composition collides at depth 3+ | Dispatch-conflict test in compliance suite; fail loudly |
| Inverse under-specified, becomes Bayesian hand-waving | Narrowing workflow spec'd in Phase 2 before code |
| Antifragile layer drifts into research | Bound scope: DP clustering + surprise threshold + hedge portfolio. No causal discovery beyond PC algorithm in v1. |
| Julia/Rust drift | Rust solver validated against Julia oracle via shared compliance suite on every PR |
| Provenance becomes optional | Every solver output is typed to require a provenance chain. No untraced results. |
