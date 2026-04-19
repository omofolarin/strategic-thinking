# Trait Composition Contract

**Status:** normative. Every trait in `strategic-jl/src/chapters/` must obey this contract, and every PR adding a new trait must update both this document and the dispatch-target registry.

Composition works because traits agree on *where* they intervene, and the type system plus a small set of invariants make those interventions compose without collision. This document specifies both.

> For the *why* behind this contract — the four layers that make the toolkit composable in the first place — see `docs/composition-architecture.md`. That document explains where composition lives in the stack; this document specifies the rules that keep it working as traits accumulate.

---

## 1. Invariants every trait must satisfy

A `GameTrait` subtype is legal only if **all** of the following hold:

### I1. Declared dispatch targets
The trait declares, in the `TRAIT_DISPATCH_TARGETS` registry, the exact set of dispatch functions it overrides. Undeclared overrides are a bug; a test enumerates all methods defined on `WithTrait{_, T}` and fails if they extend beyond the declaration.

### I2. Delegation to inner
Every method a trait defines on `WithTrait{G, T}` must either:
- fully handle the call using only `trait`-local state, or
- delegate to the inner game via `available_actions(g.inner, …)`, `payoff(g.inner, …)`, etc.

A trait that produces an output *without* consulting the inner game is almost always wrong — it breaks composition because inner traits in the stack never get a chance to contribute.

### I3. Provenance append
Every `with_trait(world, trait; chapter_ref, rationale)` call **must** append a `ProvenanceNode` before returning. The node records: the trait type, the chapter reference, the rationale, and the parent world's id. Enforced by construction in `core/traits.jl`; do not bypass `with_trait` by constructing `WithTrait` directly outside the core.

### I4. JGDL round-trip
The trait must serialize to a JGDL `Trait` entry and deserialize back to a semantically identical trait. The compliance suite includes a round-trip test for every trait; a trait that cannot round-trip cannot ship.

### I5. Deterministic given seeded RNG
Any stochastic behavior (mixed strategies, brinkmanship draws) must be reproducible given a seeded RNG passed through the solver call. This is what makes hash-addressable world analyses reproducible at all.

---

## 2. The dispatch-target registry

Traits may override only the functions in this table. Adding a new target is a core change, not a trait change — it requires a version bump and a migration note.

| Target | Signature (simplified) | Meaning | Phase |
|---|---|---|---|
| `available_actions` | `(game, state, player) -> Vector{Action}` | Which actions are legal for this player in this state | 1 |
| `payoff` | `(game, state) -> Dict{Symbol, Float64}` | Terminal or intermediate payoff per player | 1 |
| `transition` | `(game, state, joint_action) -> State` | State evolution, including stochastic outcomes | 1 |
| `sample_action` | `(strategy, state, available) -> Action` | How a player picks among available actions | 1 (used by Ch 4 reciprocity strategies) |
| `select_equilibrium` | `(game, candidates) -> Solution` | Tie-break when a game has multiple equilibria | 2 |
| `update_beliefs` | `(belief, observation) -> Belief` | Bayesian / learning update | 2 |
| `aggregate` | `(game, votes) -> outcome` | Voting / coalition aggregation | 2 |

Any other function a trait wants to touch is off the contract. File an issue to add a new dispatch target before writing the trait.

---

## 3. Composition rules

### 3.1 Order matters when overrides collide

Two traits in a stack may legally override the same dispatch target. When they do, the **outer (later-applied) trait sees the result of the inner trait's override**. Example:

```
world_base
  |> with_trait(CommitmentTrait(...))        # modifies payoff
  |> with_trait(TournamentIncentiveTrait(...))  # modifies payoff
```

Order of operations for `payoff(state)`:
1. `payoff(base_game, state)` returns raw payoffs.
2. `WithTrait{_, CommitmentTrait}` applies the deviation penalty.
3. `WithTrait{_, TournamentIncentiveTrait}` takes that result and applies the relative-payoff transform.

The reverse order — tournament first, then commitment — produces different numbers. This is **not a bug**; it's a meaningful modeling choice. The commitment penalty "before or after relative-payoff shaping" is a real strategic question.

### 3.2 Order is part of world identity

The `traits` array in JGDL is ordered. The world's content hash (`sha256:…`) covers that array in order. Two worlds with the same traits in different orders have different ids and are distinct. This is intentional.

### 3.3 Commutativity is declared, not assumed

Each trait carries a `commutes_with` annotation (Phase 2). A pair that commutes may be reordered without changing semantics; a pair that doesn't requires explicit order. The compliance suite has a test that permutes the trait array for pairs marked commutative and asserts the solver output is unchanged.

For Phase 1, all pairs are treated as non-commutative. The annotation lands with Phase 2.

### 3.4 No silent override absorption

A trait may not "consume" an inner trait's contribution — i.e. it may not decide to skip calling the inner dispatch. If a trait genuinely needs to override unconditionally, it must document why in its provenance rationale and the composition test must verify the inner trait's effect is intentionally absent.

---

## 4. Trait-to-target matrix (current)

This matrix is the registry. If it's wrong, composition is wrong.

| Trait | Chapter | Targets | Notes |
|---|---|---|---|
| `CommitmentTrait` | 5 | `payoff` | Subtracts penalty from committed player's payoff when history shows deviation. |
| `CredibleThreatTrait` | 6 | `available_actions` | Restricts threatener's legal actions conditional on opponent's trigger action. |
| `BurnedBridgeTrait` | 6 | `available_actions` | Unconditionally removes a forbidden action from a player's legal set. |
| `MixedStrategyTrait` | 7 | `sample_action` | Randomizes action choice per declared distribution. Does not touch `payoff` or `available_actions`. |
| `BrinkmanshipTrait` | 8 | `transition`, `payoff` | Introduces stochastic catastrophic transition and its payoff. **Collides with other payoff-modifiers — order explicit.** |
| `CoordinationDeviceTrait` | 9 | `select_equilibrium` | Phase 2. |
| `VotingRuleTrait` | 10 | `aggregate`, `transition` | Phase 2. |
| `BargainingProtocolTrait` | 11 | `transition`, `available_actions` | Phase 2. Offer/response structure. |
| `TournamentIncentiveTrait` | 12 | `payoff` | Transforms each player's payoff toward `(own - opponent)`. **Collides with `CommitmentTrait` — order matters.** |
| `BayesianBeliefTrait` | 13 | `update_beliefs` | Phase 2. |

### Collisions currently present

- **`payoff` target:** `CommitmentTrait`, `BrinkmanshipTrait`, `TournamentIncentiveTrait`. Any stack containing more than one of these requires explicit order; order is part of the world's strategic semantics.
- **`available_actions` target:** `CredibleThreatTrait`, `BurnedBridgeTrait`. Both are restrictive, so their composition is commutative in practice (intersection of restrictions). Phase 2 will mark this pair commutative.

---

## 5. Enforcement

### 5.1 Static registry

`strategic-jl/src/core/traits.jl` exports:

```julia
const TRAIT_DISPATCH_TARGETS = Dict{Type{<:GameTrait}, Set{Symbol}}(
    CommitmentTrait          => Set([:payoff]),
    CredibleThreatTrait      => Set([:available_actions]),
    BurnedBridgeTrait        => Set([:available_actions]),
    MixedStrategyTrait       => Set([:sample_action]),
    BrinkmanshipTrait        => Set([:transition, :payoff]),
    TournamentIncentiveTrait => Set([:payoff]),
    # Phase 2 entries added as traits land.
)
```

This registry is the source of truth. Adding a trait without a registry entry fails a module load-time check.

### 5.2 Dynamic test

In `strategic-jl/test/composition.jl`:

```julia
# For every (T1, T2) pair of traits, construct a minimal world,
# stack both in both orders, and assert:
#   - both compositions produce a valid Solution
#   - if the pair is declared commutative, solutions are equal
#   - provenance chains contain both traits in the applied order
```

### 5.3 Registry ⇔ declaration consistency

A pre-commit check enumerates every method on `WithTrait{_, T}` for each trait `T` and fails if the set of overridden dispatch targets differs from the registry declaration. This catches the "I quietly added a new override and didn't update the contract" failure mode.

---

## 6. How to add a new trait

1. **Read sections 1–3 of this document.**
2. Declare the trait struct in the appropriate `chapters/chNN_*.jl` file.
3. Override only dispatch targets from section 2's table. If you need a new target, file an issue first — this is a core change.
4. Add an entry to `TRAIT_DISPATCH_TARGETS` matching the overrides you define.
5. Implement JGDL `serialize` / `deserialize` for the trait.
6. Add a compliance case to `jgdl/compliance/compliance_suite.json` exercising the trait in isolation.
7. Add a composition case exercising the trait stacked with at least one other trait that touches a disjoint target (orthogonal composition) and, if applicable, one that touches the same target (ordered composition).
8. Update the trait-to-target matrix in section 4 of this document.
9. If the new trait commutes with any existing trait, add the declared commutativity annotation in Phase 2.

A trait PR that skips any of these steps fails CI.

---

## 7. Known limitations

- **No cross-trait invariant checking yet.** A trait can declare itself as touching `payoff` only but silently read from internal state another trait populated. Phase 3 adds a sandbox layer forcing traits to be pure functions of `(game, state, trait_parameters)`.
- **Inverse direction not yet symmetric.** Phase 2 inverse solver will need its own composition contract for hypothesis mutations. Not yet specified.
- **Performance.** Each `WithTrait` layer adds one dispatch hop. Deeply stacked worlds (10+ traits) may benefit from a flatten pass. Not a correctness issue; revisit if benchmarks demand it.

---

## 8. Why the contract exists

Without this contract, composition is an accident. The third trait we write could quietly clobber the second, and the solver would return wrong answers silently — exactly the failure mode that makes a toolkit look clever in the demo and unusable in practice. The registry + the tests + the rule that order is explicit-when-colliding are what turn "multiple dispatch makes it compose" from a slogan into something you can trust.
