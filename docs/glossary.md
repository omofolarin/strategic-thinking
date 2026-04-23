# Glossary — JGDL v1.0.0

Reference for every term, type, and field in the **JSON Game Description Language** (JGDL) used by this project. For the rules traits must obey, see `trait-composition-contract.md`; for why JGDL exists at all, see `composition-architecture.md` §3.

---

## JGDL

**JGDL** — *JSON Game Description Language*.

A JSON-based serialization contract that represents a strategic world in a form lossless enough for any implementation (Julia, Rust, TypeScript) to reconstruct, solve, and explain the same analysis. It is the **canonical form** of a composition: the `traits` array is ordered, every meaningful step is recorded in `provenance`, and the document's content hash (`world.id`) is a stable identity for the analysis across time and tools.

JGDL is distinct from classical game-theory formats:

| Format | What it captures | What it misses |
|---|---|---|
| `.nfg` (normal form) | Payoff matrix for simultaneous games | No sequential structure, no moves, no beliefs |
| `.efg` (extensive form) | Game tree with information sets | No strategic meta-moves (commitments, threats), no provenance |
| **JGDL** | The above, plus Dixit–Nalebuff meta-moves (traits), open-world extensions, hedges, and a full provenance chain | — |

### Version contract

- **`1.0.0`** is the current baseline.
- Additive changes (new optional fields) → minor bump (`1.1.0`).
- Breaking changes → major bump, migration script required.
- `open_world` and `hedges` are already present as optional fields in `1.0.0`, so Phase 3 antifragile extensions do not require a schema bump.

### Where JGDL lives in the repo

```
jgdl/
  schema/v1.0.0.schema.json   ← the normative schema
  examples/                    ← reference JGDL documents
    ch02_market_entry.json
    ch06_burned_bridge.json
    tales/                     ← Chapter 1 Ten Tales corpus
      chicken.json
  compliance/
    compliance_suite.json      ← cross-language test cases
```

---

## Document anatomy

A JGDL document is one top-level object with exactly two fields:

```json
{
  "version": "1.0.0",
  "world":   { ... }
}
```

### `version` : string (const `"1.0.0"`)

Schema version the document conforms to. Validators must reject documents whose `version` does not match their supported schema.

### `world` : object

The strategic world itself. Everything else in this glossary describes fields of `world` and the types they reference.

---

## Top-level fields of `world`

| Field | Type | Required | Summary |
|---|---|---|---|
| `id` | string (`sha256:` + 64 hex) | ✓ | Content hash of the world, computed over all other fields |
| `metadata` | `Metadata` | | Human-readable labels and chapter pointers |
| `players` | `Player[]` | ✓ | All actors in the game |
| `actions` | `Action[]` | ✓ | All legal moves, scoped per player |
| `structure` | `Structure` | ✓ | Move order, information sets, repetition, stochasticity |
| `payoffs` | `Payoffs` | ✓ | Terminal or computed rewards |
| `traits` | `Trait[]` | | Ordered strategic modifiers applied to the base game |
| `initial_state` | `State` | | Starting point for the lazy game tree |
| `provenance` | `ProvenanceNode[]` | ✓ | Audit chain: every operation that produced this world |
| `open_world` | `OpenWorld` | | Antifragile extension (Phase 3): shadow player, emergence rate |
| `hedges` | `Hedge[]` | | Explicit bets on unknown-unknowns (Phase 3) |

Critical properties:

- **`traits` is ordered.** Composition order affects semantics when two traits touch the same dispatch target. See `trait-composition-contract.md` §3.
- **`id` excludes itself from the hash input.** The hash is computed over the document with `id` field removed, then written into `id`. This is how the document is self-describing yet content-addressable.
- **`provenance` is append-only by convention.** Every operation that produces a new world adds a node; existing nodes are never mutated.

---

## Core type definitions

### `Metadata`

Human-readable description of the world. Does not affect semantics.

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | | Short label, e.g. `"Market Entry (Chapter 2)"` |
| `description` | string | | One-sentence summary |
| `chapter_references` | string[] | | Dixit–Nalebuff chapters the world illustrates, e.g. `["Chapter 2", "Chapter 6"]` |
| `created` | string (RFC 3339 datetime) | | Document creation timestamp |

---

### `Player`

An actor who chooses actions. Players may be rational optimizers, boundedly-rational noise models, human interventions, LLM-driven agents, or the shadow player representing unobserved actors (Phase 3).

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | ✓ | Unique identifier within this world |
| `name` | string | | Display name |
| `type` | `PlayerType` enum | ✓ | What decision procedure this player uses |
| `parameters` | `PlayerParameters` | | Behavioral knobs |

#### `PlayerType` values

| Value | Meaning |
|---|---|
| `rational` | Maximizes expected utility given beliefs |
| `bounded_rational` | Maximizes with noise (see `rationality_factor`); see quantal response |
| `human_oracle` | Decision deferred to a human during simulation |
| `llm_driven` | Decision delegated to an LLM via the MCP server |
| `shadow` | Represents all unobserved actors collectively (Phase 3 open-world) |

#### `PlayerParameters`

| Field | Type | Range | Description |
|---|---|---|---|
| `rationality_factor` | number | [0, 1] | 1.0 = fully rational; lower values model Chapter 7 unpredictability and bounded rationality |
| `discount_rate` | number | [0, 1] | Chapter 11 patience parameter. 1.0 = no time discount; 0.9 = 10% per round |
| `risk_aversion` | number | any | Chapter 8 sensitivity to catastrophic payoffs |

---

### `Action`

A legal move available to a specific player. Actions may carry costs and observability restrictions.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | ✓ | Unique within this world |
| `name` | string | | Display name |
| `player_id` | string | ✓ | Which player may take this action |
| `cost` | `Expression` | | Optional; subtracted from player's payoff if action taken |
| `observability` | `Observability` enum | | Whether opponents see this action |

#### `Observability` values

| Value | Meaning |
|---|---|
| `public` | All players observe the action immediately (default if omitted) |
| `private` | Only the acting player observes the action |
| `delayed` | Observed only after some number of rounds (see `Structure.information_sets`) |

---

### `Structure`

The game's temporal and informational shape. A tagged union keyed by `type`.

#### `Structure.type` values

| Value | Additional fields | Meaning |
|---|---|---|
| `simultaneous` | none | All players move at the same time, no player observes others' moves before choosing |
| `sequential` | `order` (string[]) | Players move in the given order, each observing prior moves (unless restricted by `information_sets`) |
| `repeated` | `repetitions` (int or `"infinite"`), `discount_factor` | Base game played repeatedly; supports Chapter 4 reciprocity strategies |
| `stochastic` | `transition_probs` | State transitions carry probabilities; used by Chapter 8 brinkmanship |

#### Additional `Structure` fields

| Field | Type | Description |
|---|---|---|
| `information_sets` | array of `InformationSet` | Groups of states a player cannot distinguish between; load-bearing for Chapter 13 Bayesian games |
| `repetitions` | integer ≥ 1, or `"infinite"` | Only meaningful for `repeated` |
| `discount_factor` | number in [0, 1] | Only meaningful for `repeated`; how much future payoffs count vs. present |

---

### `Payoffs`

How players are rewarded. Tagged union keyed by `type`.

#### `Payoffs.type` values

| Value | Additional fields | Meaning |
|---|---|---|
| `terminal_matrix` | `matrix` | Static lookup: outcome key → `{ player_id: payoff }` |
| `function` | `function` (Expression), `dependencies` | Computed payoff; the expression is evaluated against game state |
| `cached` | none | Payoffs were pre-computed and stored; the solver reads from a cache keyed by `world.id` |

#### `terminal_matrix` format

The `matrix` is a nested map where keys encode joint-action outcomes:

```json
"matrix": {
  "enter.fight":        { "entrant": -1, "incumbent": 1 },
  "enter.accommodate":  { "entrant":  3, "incumbent": 4 },
  "stay_out.*":         { "entrant":  0, "incumbent": 5 }
}
```

The joining character is `.`. A `*` in any position matches any action from that player.

---

### `Trait`

A strategic modifier applied to the base game. Traits stack; composition is ordered.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | ✓ | Unique within this world |
| `type` | `TraitType` enum | ✓ | Which kind of strategic move this is |
| `chapter` | string | ✓ | Chapter reference, e.g. `"Chapter 6"` |
| `applies_to` | enum | | Scope hint: `player`, `game`, `payoff`, or `action` |
| `parameters` | object | | Free-form; shape depends on `type` |

See the **Trait catalog** section below for each concrete `TraitType` and its parameters. The contract governing trait composition lives in `trait-composition-contract.md`.

---

### `State`

A snapshot of the game's current condition. Used as the root of the lazy game tree and as the context for observed plays during inverse inference.

| Field | Type | Description |
|---|---|---|
| `variables` | object | Arbitrary state variables — stocks, reputation counters, beliefs |
| `history` | array | Sequence of past actions, typically `[{ player, action }]` entries |
| `current_player` | string or null | Whose turn it is (null for simultaneous games or terminal states) |
| `round` | integer ≥ 0 | Zero-indexed round counter |

---

### `ProvenanceNode`

One entry in the audit chain. Every operation that transforms a world appends exactly one node. Downstream LLM explanations read **only** from this chain — see `composition-architecture.md` §2.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string (UUID v4) | | Optional stable identifier. Populated when the producing engine wants downstream layers to reference this specific node by id. |
| `operation` | string | ✓ | Machine-readable operation name. Canonical values: `initial_construction`, `applied_trait`, `inferred_hypothesis`, `ruled_out_hypothesis`, `detected_surprise`, `discovered_player`, `activated_hedge`. Free-form strings allowed for extensibility. |
| `trait_type` | string | | Populated iff `operation == "applied_trait"`. One of the `TraitType` enum values. Split from `operation` so explanation layers can group by trait family without parsing strings. |
| `chapter_ref` | string | ✓ | Dixit–Nalebuff chapter this operation draws from |
| `theoretical_origin` | string | | Deeper lineage, e.g. `"Schelling, The Strategy of Conflict (1960), Part II"` |
| `rationale` | string | | Human-readable justification for the operation |
| `parent_id` | string | ✓ | `world.id` before this operation (empty string for initial construction) |
| `timestamp` | string (RFC 3339) | ✓ | When the operation occurred |
| `author` | `Author` enum | ✓ | Who initiated the operation |

#### Example — trait application

```json
{
  "id": "7f8a1b3c-4d5e-4a6b-9f0c-1e2d3a4b5c6d",
  "operation": "applied_trait",
  "trait_type": "BurnedBridge",
  "chapter_ref": "Chapter 6",
  "theoretical_origin": "Schelling, The Strategy of Conflict (1960), Part II",
  "rationale": "Restricting own options to make the fight threat credible.",
  "parent_id": "sha256:abc123...",
  "timestamp": "2026-04-19T10:24:51Z",
  "author": "user"
}
```

#### `Author` values

| Value | Meaning |
|---|---|
| `user` | A human invoked this operation (DSL, direct API, composer UI) |
| `llm` | An LLM invoked this operation via the MCP server |
| `system` | The engine itself added the node (e.g. surprise detection, player discovery) |

---

### `OpenWorld`

Phase 3 antifragile extension. Optional; its presence signals that the world acknowledges unobserved actors and unmodeled actions.

| Field | Type | Description |
|---|---|---|
| `emergence_rate` | number in [0, 1] | Probability that a previously-unknown player or action emerges in a given round |
| `unknown_player_pool` | object | Prior over player types not yet observed; typed `parametric` or `DirichletProcess` |
| `shadow_player` | object | Collective representation of all unobserved actors, with a `surprise_weight` |

See `composition-architecture.md` §4 and `tasks.md` Phase 3 for how this field is consumed.

---

### `Hedge`

Phase 3. An explicit bet on an unknown-unknown — a position that pays off only in worlds the model hasn't fully conceived yet.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | ✓ | Unique within this world |
| `trigger` | `Expression` | ✓ | Boolean expression over observations and state; activates the hedge |
| `payoff_profile` | object | ✓ | How the hedge pays off when triggered |
| `cost` | number | | Ongoing cost per round |
| `optionality_value` | number | | Estimated value of the optionality this hedge provides |
| `chapter_reference` | string | | Usually `"Chapter 8 (Brinkmanship) + Antifragile Extension"` |

---

### `Expression`

A restricted, safe subset of Julia-compatible syntax used in:

- `Action.cost`
- `Payoffs.function`
- `Hedge.trigger`

Allowed constructs:

| Category | Operators / forms |
|---|---|
| Arithmetic | `+`, `-`, `*`, `/`, `^` |
| Comparison | `==`, `!=`, `<`, `>`, `<=`, `>=` |
| Logic | `&&`, `\|\|`, `!` |
| Conditional | `condition ? true_value : false_value` |
| Built-ins | `max()`, `min()`, `abs()`, `rand()` (seeded) |
| Variables | `action.<player_id>.<action_id>`, `state.<variable_name>` |

Disallowed: arbitrary function calls, mutation, I/O, module loading, reflection. The validator rejects expressions that parse outside this subset.

---

## Trait catalog

The eleven concrete `TraitType` values. Each entry lists the chapter, the dispatch target the trait overrides (per `trait-composition-contract.md`), and the parameter shape.

### `Commitment`

*Chapter 5.* Subtracts a penalty from a player's payoff if their action history diverges from a committed action.

- **Overrides:** `payoff`
- **Parameters:** `player_id`, `committed_action`, `penalty_for_deviation`

### `CredibleThreat`

*Chapter 6.* Restricts a threatener's legal actions conditional on an opponent's trigger action.

- **Overrides:** `available_actions`
- **Parameters:** `threatener_id`, `trigger_action`, `retaliation_action`, `credibility` ∈ [0, 1]

### `BurnedBridge`

*Chapter 6.* Unconditionally removes a forbidden action from a player's legal set — Schelling's "the power of weakness."

- **Overrides:** `available_actions`
- **Parameters:** `player_id`, `forbidden_action`

### `MixedStrategy`

*Chapter 7.* Randomizes a player's action choice per a declared probability distribution.

- **Overrides:** `sample_action`
- **Parameters:** `player_id`, `distribution` (map of `action_id` → probability summing to 1)

### `Brinkmanship`

*Chapter 8.* Introduces a stochastic catastrophic transition — an action that triggers disaster with some probability.

- **Overrides:** `transition`, `payoff` *(collides with other payoff-modifiers; order is semantically significant)*
- **Parameters:** `risky_action`, `catastrophe_probability` ∈ [0, 1], `catastrophic_payoff` (map of `player_id` → payoff)

### `CoordinationDevice`

*Chapter 9.* When multiple equilibria exist, selects the focal one (Schelling point) weighted by salience.

- **Overrides:** `select_equilibrium` *(Phase 2)*
- **Parameters:** `focal_action`, `salience`

### `VotingRule`

*Chapter 10.* Vote aggregation rule applied at designated decision points.

- **Overrides:** `aggregate`, `transition` *(Phase 2)*
- **Parameters:** `rule` (`plurality`, `majority`, `borda`, `condorcet`, `approval`), `members`

### `BargainingProtocol`

*Chapter 11.* Rubinstein alternating-offers structure; patience (high `discount_factor`) is power.

- **Overrides:** `transition`, `available_actions` *(Phase 2)*
- **Parameters:** `players_order`, `pie`, `discount_factor`

### `TournamentIncentive`

*Chapter 12.* Transforms each player's payoff toward `own + weight * (own − opponent)`. Relative performance dominates absolute.

- **Overrides:** `payoff` *(collides with `Commitment`, `Brinkmanship`; order matters)*
- **Parameters:** `weight_on_relative`

### `BayesianBelief`

*Chapter 13.* Maintains a Bayesian posterior over an opponent's type or hidden state; updates on observations.

- **Overrides:** `update_beliefs` *(Phase 2)*
- **Parameters:** `player_id`, `about`, `prior` (distribution spec), `update_rule` (`bayes`, `quantal_response`, `fictitious_play`)

### `LearningRule`

*Chapter 13.* Cross-round belief or strategy update mechanism — e.g. reinforcement learning, fictitious play.

- **Overrides:** `update_beliefs` *(Phase 2)*
- **Parameters:** `player_id`, `rule`, learning-specific hyperparameters

---

## Content addressing

`world.id` is a **content hash** that uniquely identifies a strategic analysis across machines, time, and tools.

### Format

```
sha256:<64 lowercase hex chars>
```

Regex: `^sha256:[a-f0-9]{64}$`

### How it's computed

1. Take the full JGDL document.
2. Remove the `world.id` field.
3. Canonicalize the remaining JSON (sorted keys, normalized whitespace, specified number format — see `trait-composition-contract.md` §1.I5 for the exact canonicalization rules once they land in Phase 1).
4. Compute SHA-256 of the canonical bytes.
5. Prepend `sha256:` and lowercase the hex.
6. Write the result back into `world.id`.

### Identity implications

- Two documents with the same `traits` in **different orders** have different `id`s. This is intentional: composition order is semantically significant.
- Two documents with identical provenance but different `metadata.name` have different `id`s. (If you need stable identity under cosmetic edits, hash just the semantic subset — but that's not what `world.id` is for.)
- `Strategic.save(world)` and `Strategic.load(hash)` use `world.id` as the storage key; reproducibility depends on cross-language hash agreement.

---

## Enum value reference

Consolidated list of every enumerated value in the schema.

| Enum | Valid values |
|---|---|
| `PlayerType` | `rational`, `bounded_rational`, `human_oracle`, `llm_driven`, `shadow` |
| `Observability` | `public`, `private`, `delayed` |
| `Structure.type` | `simultaneous`, `sequential`, `repeated`, `stochastic` |
| `Payoffs.type` | `terminal_matrix`, `function`, `cached` |
| `Trait.type` | `Commitment`, `CredibleThreat`, `BurnedBridge`, `MixedStrategy`, `Brinkmanship`, `CoordinationDevice`, `VotingRule`, `BargainingProtocol`, `TournamentIncentive`, `BayesianBelief`, `LearningRule` |
| `Trait.applies_to` | `player`, `game`, `payoff`, `action` |
| `ProvenanceNode.author` | `user`, `llm`, `system` |
| `OpenWorld.unknown_player_pool.type` | `parametric`, `DirichletProcess` |

---

## Game-theory terms referenced in JGDL

These terms appear in field descriptions, rationales, or provenance nodes throughout the schema and examples. Short definitions for readers coming from software engineering rather than game theory:

| Term | Where it appears | Meaning (brief) |
|---|---|---|
| **Subgame perfect equilibrium (SPE)** | compliance suite, Ch 2 examples | A Nash equilibrium that remains rational at every decision point, not just the starting state. Computed via backward induction. |
| **Nash equilibrium** | compliance suite, Ch 4 examples | A profile of strategies where no player can improve by unilaterally deviating. |
| **Information set** | `Structure.information_sets` | A group of game states that a player cannot distinguish between when choosing an action. Central to Chapter 13 Bayesian games. |
| **Quantal response** | `BayesianBelief.update_rule` | Behavioral model where players choose actions with probabilities proportional to `exp(λ * utility)` rather than deterministically maximizing. |
| **Dirichlet Process** | `OpenWorld.unknown_player_pool` | Nonparametric Bayesian prior allowing the number of player types to grow with observation. |
| **Focal point (Schelling point)** | `CoordinationDevice.focal_action` | A solution that players gravitate to in the absence of communication, due to salience or cultural convention. |
| **Zone of agreement** | bargaining contexts | Range of settlements both parties would accept; the intersection of their reservation prices. |
| **Reservation price** | bargaining contexts | The worst outcome a player will accept before walking away. |
| **Discount factor** | `Structure.discount_factor`, `PlayerParameters.discount_rate` | How much a player values future payoffs relative to present ones. In Chapter 11, patience-as-power is a high discount factor. |
| **Backward induction** | compliance suite | Solving a sequential game by starting at terminal nodes and propagating optimal choices up the tree. |
| **Iterated elimination of dominated strategies** | Chapter 3 solver | Repeatedly remove actions that no rational player would take given the current strategy space. The residual is the rationalizable set. |
| **Rationalizability** | `RationalizableSet` in Ch 3 | Actions that survive iterated elimination; playable by *some* rational player who believes others are rational. |
| **Tit-for-Tat, Grim Trigger, Pavlov, Generous TFT** | Chapter 4 reciprocity strategies | Concrete behavioral strategies that resolve repeated prisoner's dilemmas. Defined in `strategic-jl/src/chapters/ch04_pd_resolution.jl`. |

For deeper treatment, the source material is *Thinking Strategically* (Dixit & Nalebuff, 1991) with theoretical roots in *The Strategy of Conflict* (Schelling, 1960).

---

## Relationship to other docs

| Document | What it covers | Read when |
|---|---|---|
| **This glossary** | JGDL terms and types | Reading, writing, or validating a JGDL document |
| `composition-architecture.md` | Why JGDL is one of four layers that make the toolkit composable | Orienting to the architecture |
| `trait-composition-contract.md` | Rules every `Trait` must obey, dispatch-target registry, collision resolution | Authoring a new trait |
| `jgdl/schema/v1.0.0.schema.json` | Machine-readable schema | Running validation, generating code |
| `jgdl/examples/*.json` | Reference JGDL documents | Learning by example |
| `jgdl/compliance/compliance_suite.json` | Cross-language correctness tests | Verifying an implementation |
| `roadmap.md` | Which schema features ship in which phase | Planning work |

---

## One-line summary

JGDL is the canonical, content-addressable, provenance-carrying serialization of a strategic world — lossless enough to round-trip between Julia, Rust, and TypeScript implementations, and structured enough that an LLM can compose worlds by emitting JSON and explain them by citing provenance.
