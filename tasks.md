# Tasks

Tasks are grouped by phase from `roadmap.md`. Each task has a clear exit criterion. Check off only when the criterion is met.

## Phase 0 — JGDL as the Contract

### 0.1 Schema definition
- [ ] Draft `jgdl/schema/v1.0.0.schema.json` covering: players, actions, structure, payoffs, traits, initial_state, provenance
- [ ] Add open-world fields as optional (shadow_player, emergence_rate) so Phase 3 doesn't require a schema bump
- [ ] Decide on expression language grammar (subset of Julia syntax) and document
- [ ] Write schema validator as a pure function that accepts JSON and returns errors with JSON-pointer paths

### 0.2 Compliance suite
- [ ] Ch 1: Ten Tales ground-truth — each Tale authored as JGDL + expected solver output. **The primitives pass iff every Tale round-trips to its expected outcome.** Five authored in Phase 1, remaining five in Phase 2.
- [ ] Ch 3: Iterated dominance — prisoner's-dilemma-like 3x3 where one action is dominated; expected `RationalizableSet` = 2 actions for that player
- [ ] Ch 2: Market entry (sequential) — expected SPE: StayOut
- [ ] Ch 4: Prisoner's dilemma (one-shot) — expected: (Defect, Defect)
- [ ] Ch 4: PD repeated with TFT — expected: cooperation
- [ ] Ch 5: Commitment device — expected outcome shifts vs. no commitment
- [ ] Ch 6: Burned bridge — expected: threat becomes credible
- [ ] Ch 7: Mixed strategy (matching pennies) — expected: uniform mix
- [ ] Ch 8: Brinkmanship with 10% catastrophe probability — expected: equilibrium sensitive to risk
- [ ] Ch 9: Coordination with focal point — expected: focal equilibrium selected
- [ ] Ch 10: Voting (Condorcet paradox) — expected: cycle detected
- [ ] Ch 11: Alternating offers bargaining — expected: subgame perfect split
- [ ] Ch 12: Tournament incentives — expected: relative payoff dominates
- [ ] Ch 13: Bayesian auction — expected: bidder strategy depends on prior
- [ ] Composition test: Commitment + Brinkmanship + Bayesian stacked — dispatch resolves, result stable
- [ ] Composition test: Sequential + MixedStrategy — information set handled correctly
- [ ] 6 more ad-hoc composition stress tests

**Exit:** All 20 cases have `jgdl` + `expected` blocks; the schema validator accepts every `jgdl` block; no implementation exists yet.

---

## Phase 1 — Forward Toolkit (Julia)

### 1.1 Core types
- [ ] `AbstractGame`, `GameTrait`, `SolverMethod`, `PlayerStrategy`
- [ ] `StrategicWorld`, `Player`, `Action`, `State`
- [ ] `ProvenanceNode` with chapter_ref, rationale, parent_id, timestamp, author
- [ ] `LazyGameTree` — generator-based, never materializes full tree

### 1.2 Trait composition
- [ ] `WithTrait{G, T}` wrapper pattern
- [ ] Dispatch test: 3+ stacked traits resolve without ambiguity
- [ ] Provenance auto-appends on each `with_trait` call
- [ ] `TRAIT_DISPATCH_TARGETS` registry populated for every shipped trait (per `docs/trait-composition-contract.md` §5)
- [ ] Load-time check: trait with undeclared dispatch target fails module load
- [ ] Composition test enumerates trait pairs, asserts overlapping_targets flags collisions, asserts orthogonal pairs produce empty overlap
- [ ] Provenance chain integrity test: every `with_trait` call produces a node whose `parent_id` equals the pre-call world id
- [ ] Contract doc is normative: PR template requires updating `docs/trait-composition-contract.md` §4 matrix when adding a trait

### 1.3a Foundation chapters (Ch 1–4) — LAND BEFORE MODIFIERS
- [ ] Ch 1: Author 5 of 10 Tales as JGDL fixtures under `jgdl/examples/tales/` (chicken.json already scaffolded)
- [ ] Ch 1: Populate `TALES` registry; `tales_covering(concept)` returns non-empty for core concepts
- [ ] Ch 2: `validate_sequential` — well-formed order, information sets, no cycles
- [ ] Ch 2: `look_ahead_depth` + subgame-perfection contract in `BackwardInduction`
- [ ] Ch 3: `dominates(world, player, a, b, opponents; strict)` — strict dominance first, weak later
- [ ] Ch 3: `solve(world, ::IteratedDominance)` returns `RationalizableSet` with full elimination trace as provenance
- [ ] Ch 3: Inverse-direction consumer — hypothesis is ruled out if observed action is never rationalizable
- [ ] Ch 4: `TitForTat.choose_action` — cooperate first, then mirror
- [ ] Ch 4: `GrimTrigger.choose_action` — defect forever after first defection
- [ ] Ch 4: `Pavlov.choose_action` — win-stay, lose-shift
- [ ] Ch 4: `GenerousTFT.choose_action` — TFT with forgiveness probability
- [ ] Ch 4: Repeated-game solver harness uses reciprocity strategies; produces cooperation equilibrium under TFT with high enough discount factor

### 1.3b Modifier chapters (Ch 5–8) — STACK ON FOUNDATION
- [ ] Ch 5: `CommitmentTrait` — modifies payoff given committed action
- [ ] Ch 6: `CredibleThreatTrait` + `BurnedBridgeTrait` (removes action from available set)
- [ ] Ch 7: `MixedStrategyTrait` — randomizes over pure actions
- [ ] Ch 8: `BrinkmanshipTrait` — stochastic catastrophic payoff

### 1.4 Forward solvers
- [ ] `BackwardInduction` with memoization keyed on state hash
- [ ] `IteratedDominance` runs before BackwardInduction when profitable; standalone solver for "what can we conclude without full tree walk?"
- [ ] Returns `Solution { equilibrium_path, payoffs, provenance_chain }`
- [ ] Every returned `Solution` must carry a non-empty `provenance_chain` (enforce via type)

### 1.5 JGDL bridge
- [ ] `to_jgdl(world) -> String`
- [ ] `from_jgdl(json) -> StrategicWorld` with schema validation
- [ ] SHA-256 content addressing; `Strategic.save(world)` / `Strategic.load(hash)`
- [ ] Round-trip test: `from_jgdl(to_jgdl(w)) == w` for every compliance case

### 1.6 DSL macro
- [ ] `@strategic begin ... end` parses to `StrategicWorld`
- [ ] Supports: player declarations, action sets, move order, payoff matrix or expression, trait composition
- [ ] Error messages point to the source line in the DSL block

### 1.7 Pluto explorer
- [ ] Slider-driven trait parameters
- [ ] Live game-tree visualization
- [ ] Provenance panel showing chapter citations
- [ ] Works offline (no external LLM calls)

### 1.8 Compliance pass
- [ ] Phase 0 compliance suite passes for forward-direction cases
- [ ] CI runs the suite on every PR

---

## Phase 2 — Inverse Toolkit (Julia)

### 2.1 Observation types
- [ ] `ObservedPlay { context, action, player_id, timestamp, confidence }`
- [ ] Observation stream abstraction (pull or push)

### 2.2 Hypothesis space
- [ ] Parametric hypothesis generator — vary payoffs/priors within a world template
- [ ] Interface for user-provided hypotheses (not auto-generated)
- [ ] Provenance: each hypothesis records why it was proposed

### 2.3 Likelihood model
- [ ] Quantal response behavioral noise model (Chapter 7)
- [ ] Bayesian posterior update given observations
- [ ] Return ranked posterior, not just MAP

### 2.4 Narrowing workflow
- [ ] Not a single call — an interactive session
- [ ] User can: add observation, prune hypothesis, request ruling, inspect provenance
- [ ] Each step adds a provenance node

### 2.5 Inverse DSL symmetry
- [ ] `@observe begin ... end` macro mirrors `@strategic`
- [ ] Compositional: inverse results can be piped into forward solver for prediction

### 2.6 Compliance extension
- [ ] 5 inverse-direction cases added to compliance suite
- [ ] Case: given actions consistent with PD, system ranks PD above coordination game
- [ ] Case: behavior shift mid-stream → hypothesis of payoff change ranks highly

---

## Phase 3 — Antifragile Affordances

### 3.1 Open-world JGDL extension
- [ ] Add `open_world` block to JGDL v1.1.0 (backward-compatible)
- [ ] `ShadowPlayer` representing all unobserved actors
- [ ] `emergence_rate` parameter

### 3.2 Surprise detector
- [ ] Log-likelihood threshold for flagging observations
- [ ] Mutation template library (new_player, objective_change, collusion, asymmetry)
- [ ] Ranked explanations for every surprise event
- [ ] Surprise events stored with full provenance

### 3.3 Player discovery
- [ ] Start parametric (known K, cluster into K)
- [ ] Upgrade to Dirichlet Process when parametric version passes
- [ ] Each discovered player gets a provenance node citing the observations that birthed it

### 3.4 Causal graph (bounded scope)
- [ ] DAG over actions, payoffs, external events
- [ ] PC algorithm for edge discovery (no more advanced methods in v1)
- [ ] Latent-node flagging when tetrad condition holds
- [ ] Explicitly out-of-scope for v1: counterfactual reasoning, instrumental variables

### 3.5 Hedge portfolio
- [ ] `Hedge { trigger, payoff, cost, optionality_value }` type
- [ ] Activation rule wired to surprise detector
- [ ] JGDL serialization for hedges

### 3.6 Antifragile solver
- [ ] `solve_antifragile(world)` returns `AntifragileSolution` with known/unknown risks quantified
- [ ] Compliance suite gains antifragile cases from Phase 0

---

## Phase 4 — LLM Access via MCP (Rust)

### 4.1 Rust core mirror
- [ ] `strategic-core` crate: JGDL types via serde
- [ ] Schema validator in Rust, shares compliance suite with Julia
- [ ] Content addressing matches Julia byte-for-byte

### 4.2 Rust solver
- [ ] `strategic-solver` crate: backward induction with memoization
- [ ] Validates every output against Julia oracle (via FFI or JGDL round-trip)
- [ ] Inverse solver can remain Julia-only in v1

### 4.3 MCP server
- [ ] `strategic-mcp` crate: axum server implementing MCP protocol
- [ ] Tools: `instantiate_world`, `solve_world`, `mutate_world`, `infer_from_observations`, `detect_surprise`, `explain_from_provenance`
- [ ] Session management with content-addressable world storage
- [ ] Every tool response includes the provenance chain that justifies it

### 4.4 LLM explanation contract
- [ ] LLM prompt template reads *only* from provenance graph + solver output
- [ ] No tool returns free-form text without provenance citations
- [ ] Test: LLM explanation is reproducible given the same provenance input

### 4.5 Claude Desktop integration
- [ ] MCP manifest
- [ ] End-to-end: user describes situation → LLM calls `instantiate_world` → `solve_world` → `explain_from_provenance`
- [ ] No hallucination tolerance: every claim in the LLM response traceable to a provenance node

---

## Phase 5 — Systems Layer (conditional)

Only if Phase 1–4 usage reveals users hitting long-run dynamics limits. Otherwise, skip.

- [ ] Confirm user demand before starting
- [ ] `with_systems(world, stocks, flows)` opt-in API
- [ ] Strategic move → feedback loop inference
- [ ] Basin-of-attraction analysis
- [ ] Stella/Vensim export

---

## Phase 6 — WASM + Web Composer (conditional)

Only if server round-trip or deployment cost becomes friction.

- [ ] `strategic-wasm` compile target
- [ ] TypeScript composer with drag-and-drop
- [ ] Provenance graph viz (D3 or reactflow)
- [ ] Explanation panel bound to MCP

---

## Cross-cutting

### Testing discipline
- [ ] Every PR runs compliance suite in both Julia and Rust
- [ ] Composition stress tests expanded each phase (no regressions)
- [ ] Provenance chain integrity test: no `Solution` returned without provenance

### Documentation
- [ ] Every primitive has a minimal example with expected output
- [ ] Chapter-to-primitive mapping kept current in `docs/chapter_index.md`
- [ ] "Why this design" doc for the trait composition pattern

### Release discipline
- [ ] v0.1 = Phase 1 complete
- [ ] v0.2 = Phase 2 complete
- [ ] v0.3 = Phase 3 complete
- [ ] v1.0 = Phase 4 complete, MCP stable, provenance contract locked
