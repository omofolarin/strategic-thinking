# What Makes It Composable

**Status:** architectural. Describes *where* composition lives in the stack and *why* it works. The companion document `trait-composition-contract.md` specifies the *rules* composition must obey. Read this first if you're orienting; read the contract when you're adding a trait.

---

## The question this answers

> What parts make it composable — the DSL layer?

Natural assumption, wrong answer. The DSL is the surface, not the substrate. Composition happens deeper. The DSL is one of several *frontends* that all produce the same compositional form.

---

## Short answer

Composition is enabled by four things, in roughly this order of load-bearing:

1. **Wrapper type + multiple dispatch** — the substrate. `WithTrait{G, T}` stacks in the type system; Julia's dispatch walks the stack at call time.
2. **Provenance append invariant** — every composition step is auditable. Without this, composition is mechanically possible but not explainable.
3. **JGDL as canonical form** — composition is data, not code. It can cross process, language, and tool boundaries because the substrate is a serializable array of traits.
4. **Orthogonality of trait concerns** — traits agree on *where* they intervene. When they don't, order becomes part of semantics and is captured explicitly.

If you deleted the DSL tomorrow, every one of these still works. Delete any of the four above and nothing composes regardless of how pleasant the DSL looks.

---

## 1. Wrapper type + multiple dispatch

This is the substrate. The mechanism is a single wrapper type in `strategic-jl/src/core/traits.jl`:

```julia
struct WithTrait{G<:AbstractGame, T<:GameTrait} <: AbstractGame
    inner::G
    trait::T
end
```

Stacking `CommitmentTrait` on `BurnedBridgeTrait` on a base game produces:

```
WithTrait{WithTrait{BaseGame, BurnedBridgeTrait}, CommitmentTrait}
```

Each layer is a distinct type. When a solver calls `payoff(game, state)`, Julia's dispatch picks the most specific method — the outermost `CommitmentTrait` layer — and that method can choose to delegate to `payoff(game.inner, state)` to let inner layers contribute.

### Why this beats the alternatives

This is the Julia answer to the **Expression Problem**: how do you add new types of games *and* new types of strategic moves without rewriting old code?

- **In Python (OOP):** adding a new game type forces editing every existing trait class. Adding a new trait type forces editing every existing game class. You get O(N × M) code churn.
- **In Rust (ADTs):** adding a new trait variant means editing the `match` arm in every function that dispatches on traits. The compiler catches you, but the cost is real.
- **In Julia (multiple dispatch):** `payoff(::WithTrait{<:AbstractGame, TournamentIncentiveTrait}, ::State)` lives in its own file. Adding a new trait requires zero changes to core, zero changes to other traits. The dispatcher picks it up automatically.

This is not a stylistic preference — it's the reason Julia is the core language for the toolkit. A Rust rewrite of the MCP server for deployment is fine (it only handles a fixed vocabulary of traits); the research surface stays in Julia because new traits are the *common* operation and they must be cheap.

---

## 2. Provenance append invariant

Composition without provenance is mechanically correct but strategically useless. A user who has applied five traits and gets back an equilibrium needs to know *why* the equilibrium shifted — which trait contributed which effect, and what chapter of Dixit & Nalebuff justified each step.

The invariant lives in `with_trait()`:

```julia
function with_trait(world, trait; chapter_ref, rationale)
    new_world = StrategicWorld(…, WithTrait(world.game, trait), …)
    append_provenance!(new_world, ProvenanceNode(…, chapter_ref, rationale, …))
    new_world
end
```

You cannot apply a trait without appending a provenance node. The `StrategicWorld` constructor enforces that `Solution` carries a non-empty `provenance_chain`. Every downstream consumer — the LLM explanation layer, the web composer's explanation panel, the MCP `explain_from_provenance` tool — reads *only* from this chain.

This is what turns composition from "can be mixed" into "can be explained." It's also what prevents LLM hallucination at the explanation layer: an LLM that can only cite provenance nodes cannot invent reasons the engine didn't produce.

---

## 3. JGDL as canonical form

Composition is **data**, not code. The `traits` field in JGDL is an ordered array:

```json
{
  "world": {
    "traits": [
      { "id": "incumbent_burns_bridge", "type": "BurnedBridge", "chapter": "Chapter 6", … },
      { "id": "entrant_commits",        "type": "Commitment",   "chapter": "Chapter 5", … }
    ]
  }
}
```

This matters because it means composition can cross boundaries:

- A human composing in Julia writes `with_trait(world, …) |> with_trait(…)`.
- An LLM composing via MCP emits a JGDL JSON document.
- The future web composer composes via drag-and-drop, then serializes to the same JSON.
- The Rust MCP server reconstructs and solves from that JSON.

All three frontends collapse to the same structure. That's only possible because the trait array is a first-class serializable thing, not a product of DSL parsing.

Content-addressing (SHA-256 over the canonical JGDL) completes the loop: two compositions producing the same JGDL share the same world id and are provably the same analysis. Two compositions producing *different* orderings of the same trait set have *different* world ids — which is correct, because order is part of semantics (see §4).

---

## 4. Orthogonality of trait concerns

The final layer. Traits compose without silent collision because they agree on *which dispatch targets* they're allowed to override. In `core/traits.jl`:

```julia
const DISPATCH_TARGETS = Set([
    :available_actions, :payoff, :transition,
    :sample_action, :select_equilibrium,
    :update_beliefs, :aggregate,
])

const TRAIT_DISPATCH_TARGETS = Dict{Type{<:GameTrait}, Set{Symbol}}(
    CommitmentTrait          => Set([:payoff]),
    BurnedBridgeTrait        => Set([:available_actions]),
    MixedStrategyTrait       => Set([:sample_action]),
    BrinkmanshipTrait        => Set([:transition, :payoff]),
    TournamentIncentiveTrait => Set([:payoff]),
    # …
)
```

When two traits touch the same target (e.g. `CommitmentTrait` and `TournamentIncentiveTrait` both modify `payoff`), composition order becomes part of the semantics. The outer (later-applied) trait sees the result of the inner trait's override. This is a meaningful strategic question — *"does the commitment penalty apply before or after relative-payoff shaping?"* — and the user must decide.

Without this agreement, a new trait could silently clobber another by overriding a function nobody anticipated. You wouldn't know until the solver returned a surprising number.

The **trait-composition contract** (`docs/trait-composition-contract.md`) is what turns this convention into an enforced property: registry + collision detection + tests that fail when a trait overrides more than it declared.

---

## Where the DSL fits

```
┌────────────────────────────────────────────────────────────┐
│  FRONTENDS (ergonomics — pick the one that fits the user)  │
│                                                            │
│   @strategic macro  │  JGDL JSON  │  web composer  │  API  │
└────────────────┬───────────────┬──────────┬─────────┬──────┘
                 ▼               ▼          ▼         ▼
            ┌──────────────────────────────────────────┐
            │  SUBSTRATE (composition lives here)       │
            │                                           │
            │  1. WithTrait{G, T} wrapper + dispatch    │
            │  2. with_trait() appends ProvenanceNode   │
            │  3. JGDL as canonical ordered form        │
            │  4. Dispatch-target registry + contract   │
            └──────────────────────────────────────────┘
```

The DSL exists because writing `with_trait(with_trait(base, bridge; …), commitment; …)` is awkward for humans. `@strategic begin … end` is sugar that lowers to the same calls. That's it. The DSL has no compositional power beyond what the substrate provides.

This is also why the toolkit is portable across languages: the substrate is transferable (via JGDL), the frontend is not. A user who prefers YAML or a visual editor can compose just as well as a user who likes macros.

---

## Thought experiment: what breaks if we remove each layer?

| Remove | What breaks |
|---|---|
| DSL | Nothing structural. Users write `with_trait(…)` directly, or compose via JGDL JSON. Ergonomics suffer; composition works. |
| Wrapper + dispatch | Composition becomes impossible. Every trait combination needs a hand-written `SequentialBayesianCommitmentGame` type. The Expression Problem returns with full force. |
| Provenance append | Composition still works mechanically. But the LLM layer can no longer explain anything without hallucinating, and auditability is gone. The toolkit becomes a black-box solver. |
| JGDL canonical form | Composition only works within one language. LLM can't compose via tool calls. Web composer can't exist. Reproducibility across machines and across time is broken. |
| Dispatch-target contract | Composition works for two or three traits, then silently breaks when a new trait overrides something a previous trait was quietly relying on. The toolkit demos beautifully and fails in production. |

Four of those five are fatal. The DSL one is inconvenient. That ranking is the answer to the original question.

---

## Relationship to other docs

- **`docs/trait-composition-contract.md`** — the normative rules traits must obey. Where this document says "the registry exists," the contract says "here's exactly what must appear in it, and here are the tests that enforce it."
- **`roadmap.md`** — schedules these layers across phases. Wrapper+dispatch and provenance land in Phase 1. JGDL is Phase 0. The contract enforcement matures through Phases 1–3.
- **`strategic-jl/src/core/traits.jl`** — where the substrate actually lives in code. Read with this document open.

---

## One-line summary

Composition is a property of the substrate, not the frontend. The DSL is ergonomics; the wrapper, dispatch, provenance, JGDL, and contract are the reason it works.
