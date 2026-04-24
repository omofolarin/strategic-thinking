# DSL Reference — `strategic()`

The `strategic()` function is the primary human interface to the toolkit. It converts
a concise text description of a strategic situation into a `StrategicWorld` that can
be solved, analysed, and explained.

```julia
world = strategic("""
    player entrant   can [enter, stay_out]
    player incumbent can [fight, accommodate]
    entrant moves first
    incumbent burns bridge: accommodate
    payoff:
        (enter,    fight)       => (-10, -20)
        (enter,    accommodate) => (40,   30)
        (stay_out, fight)       => (0,   100)
        (stay_out, accommodate) => (0,   100)
""")

result = solve(world, BackwardInduction())
# → equilibrium: [:stay_out], payoffs: {entrant: 0, incumbent: 100}
```

---

## Full grammar

```
# Metadata (optional)
name: <text>
chapter: Chapter N

# Players (required, at least one)
player <Name> can [<action>, <action>, ...]

# Player parameters (optional, per player)
<Name> rationality: <0.0–1.0>
<Name> risk_aversion: <number>
<Name> discount: <0.0–1.0>

# Structure (optional — default is simultaneous)
<Name> moves first          # sequential; remaining players follow in declaration order
repeated, infinite, discount <0.0–1.0>
repeated, <N>, discount <0.0–1.0>

# Payoffs (required)
payoff:
    (<action>, <action>) => (<number>, <number>)
    (<action>, *)        => (<number>, <number>)   # wildcard: matches any action

# Traits (optional, any number)
<Name> commits to <action>
<Name> threatens: if <Opponent> <action> => <Name> <retaliation>
<Name> burns bridge: <action>
<Name> mixes: <action> <prob>, <action> <prob>, ...
<action> carries <N>% catastrophe: (<number>, <number>)
```

---

## Constructs

### `player Name can [action, action, ...]`

Declares a player and their available actions. Players are ordered — the first declared
player is player 1, the second is player 2, and so on. This order determines which
payoff value in a tuple belongs to which player.

```
player Alice can [cooperate, defect]
player Bob   can [cooperate, defect]
payoff:
    (cooperate, cooperate) => (3, 3)   # Alice gets 3, Bob gets 3
    (cooperate, defect)    => (0, 5)   # Alice gets 0, Bob gets 5
```

---

### `name:` and `chapter:`

Optional metadata. `name` sets the world's display name. `chapter` adds a chapter
reference to the provenance chain.

```
name: Market Entry Game
chapter: Chapter 2
chapter: Chapter 6
```

---

### `Name moves first`

Makes the game sequential. The named player moves first; remaining players follow in
declaration order. Only the first mover needs to be declared — the rest are inferred.

```
entrant moves first
# → structure: sequential, order: [entrant, incumbent]
```

---

### `repeated, infinite, discount D` / `repeated, N, discount D`

Makes the game a repeated game. `infinite` means indefinitely repeated; `N` means
exactly N repetitions. `D` is the discount factor (how much future payoffs count
relative to present ones).

```
repeated, infinite, discount 0.9
# → structure: repeated, repetitions: infinite, discount_factor: 0.9
```

High discount factor (close to 1) = patient player who values the future.
Low discount factor (close to 0) = impatient player who discounts the future heavily.
See `docs/mathematics.md` §1 and `docs/context-driven-payoff-design.md` Layer 3.

---

### `payoff:` block

Defines the terminal payoff matrix. Each line maps a joint action outcome to a tuple
of payoffs, one per player in declaration order.

```
payoff:
    (cooperate, cooperate) => (3, 3)
    (cooperate, defect)    => (0, 5)
    (defect,    cooperate) => (5, 0)
    (defect,    defect)    => (1, 1)
```

**Wildcard `*`**: matches any action from that player. Useful for terminal states where
one player's action doesn't affect the outcome.

```
payoff:
    (enter,    fight)       => (-10, -20)
    (enter,    accommodate) => (40,   30)
    (stay_out, *)           => (0,   100)   # incumbent's action irrelevant if entrant stays out
```

**Validation**: every action name in the payoff block must match a declared action ID.
A typo produces an error listing the known IDs.

---

### `Name rationality: N` / `Name risk_aversion: N` / `Name discount: N`

Sets behavioral parameters on a player. These are stored in the world's metadata and
used by the quantal response model in the inverse solver.

| Parameter | Range | Meaning |
|---|---|---|
| `rationality` | 0–1 | 1.0 = fully rational; lower = noisier choices (Chapter 7) |
| `risk_aversion` | any | Higher = more averse to catastrophic outcomes (Chapter 8) |
| `discount` | 0–1 | How much the player values future payoffs (Chapter 11) |

```
Alice rationality: 0.8
Alice risk_aversion: 1.5
```

---

### `Name commits to action` — Chapter 5

Adds a `CommitmentTrait`. The named player publicly and irreversibly commits to an
action. Deviating incurs a large penalty (100 by default), making the commitment
credible.

```
leader commits to high
# → CommitmentTrait(player_id: :leader, committed_action: :high, penalty: 100.0)
```

**Effect**: the solver treats deviation as very costly, so the committed action becomes
the player's dominant choice. Other players anticipate this and best-respond accordingly.

---

### `Name threatens: if Opponent action => Name retaliation` — Chapter 6

Adds a `CredibleThreatTrait`. If the opponent takes the trigger action, the threatener's
available actions are restricted to the retaliation action only.

```
incumbent threatens: if entrant enter => incumbent fight
```

**Effect**: once the trigger fires, the threatener has no choice but to retaliate.
This makes the threat credible — but only if the trigger actually fires.
Compare with `burns bridge`, which makes the threat credible unconditionally.

---

### `Name burns bridge: action` — Chapter 6

Adds a `BurnedBridgeTrait`. The named player permanently removes an action from their
available set. They literally cannot take that action, regardless of what happens.

```
incumbent burns bridge: accommodate
```

**Effect**: the solver removes `accommodate` from the incumbent's actions before
solving. The entrant anticipates that the incumbent can only fight, so entering is
no longer rational. Equilibrium flips to `stay_out`.

This is Schelling's "power of weakness" — restricting your own options increases
your credibility because the other player knows you have no choice.

---

### `Name mixes: action prob, action prob, ...` — Chapter 7

Adds a `MixedStrategyTrait`. The named player randomises over their actions according
to the declared probability distribution.

```
row mixes: heads 0.5, tails 0.5
```

**Constraint**: probabilities must sum to 1.0 (±0.01). A validation error is raised
if they don't.

**Effect**: the player's action is sampled from the distribution at each round. Used
for zero-sum games where predictability is exploitable (matching pennies, penalty kicks).

---

### `action carries N% catastrophe: (payoff, payoff)` — Chapter 8

Adds a `BrinkmanshipTrait`. The named action carries a probability of triggering a
catastrophic outcome that neither player fully controls.

```
escalate carries 10% catastrophe: (-1000, -1000)
```

**Effect**: if `escalate` appears in the history, the solver blends the base payoff
with the catastrophic payoff weighted by the probability:

```
expected_payoff = (1 - 0.10) × base_payoff + 0.10 × (-1000)
```

At 10% catastrophe probability, the expected payoff of escalation is sharply negative
even if the base payoff is positive. This is Schelling's brinkmanship: the threat works
because the risk is real, not because anyone intends catastrophe.

**Constraint**: probability must be in [0, 1]. `150%` raises a validation error.

---

## Validation errors

The DSL validates your input at construction time. Common errors:

| Error | Cause | Fix |
|---|---|---|
| `payoff key 'X' references undeclared action 'Y'` | Typo in payoff block | Check action names match exactly |
| `burns bridge references undeclared action 'X'` | Typo in trait | Check action name |
| `mixed strategy sums to 1.1` | Probabilities don't sum to 1 | Adjust probabilities |
| `catastrophe_probability=1.5 must be in [0,1]` | Percentage > 100 | Use a value between 0 and 100 |
| `move order references undeclared player 'X'` | Typo in player name | Check player name |
| `duplicate player ids: p1` | Two players with same name | Give each player a unique name |

---

## Complete examples

### Prisoner's Dilemma

```julia
world = strategic("""
    name: One-Shot Prisoner's Dilemma
    chapter: Chapter 4
    player p1 can [cooperate, defect]
    player p2 can [cooperate, defect]
    payoff:
        (cooperate, cooperate) => (3, 3)
        (cooperate, defect)    => (0, 5)
        (defect,    cooperate) => (5, 0)
        (defect,    defect)    => (1, 1)
""")
solve(world, BackwardInduction())
# Nash: (defect, defect), payoffs: (1, 1)
```

### Repeated PD with TFT

```julia
world = strategic("""
    name: Repeated PD
    chapter: Chapter 4
    player p1 can [cooperate, defect]
    player p2 can [cooperate, defect]
    repeated, infinite, discount 0.9
    payoff:
        (cooperate, cooperate) => (3, 3)
        (cooperate, defect)    => (0, 5)
        (defect,    cooperate) => (5, 0)
        (defect,    defect)    => (1, 1)
""")
```

### Brinkmanship

```julia
world = strategic("""
    name: Escalation Game
    chapter: Chapter 8
    player p1 can [escalate, back_down]
    player p2 can [escalate, back_down]
    escalate carries 10% catastrophe: (-1000, -1000)
    payoff:
        (escalate,  escalate)  => (-100, -100)
        (escalate,  back_down) => (10,    -5)
        (back_down, escalate)  => (-5,    10)
        (back_down, back_down) => (0,      0)
""")
solve(world, BackwardInduction())
# Equilibrium: back_down (expected escalation payoff = -91)
```

---

## Related

- `docs/mathematics.md` — the mathematics behind each solver
- `docs/context-driven-payoff-design.md` — how to choose payoff values
- `docs/llm-payoff-elicitation.md` — LLM-assisted payoff construction
- `src/dsl/macro.jl` — implementation
- `test/dsl.jl` — test cases
