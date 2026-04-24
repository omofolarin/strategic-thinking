# Chapter 4 repeated-game solver.
#
# The one-shot prisoner's dilemma has (Defect, Defect) as its unique Nash.
# Cooperation becomes sustainable only under repetition + reciprocity
# strategies from ch04_pd_resolution.jl. This solver operationalizes that
# claim: given PlayerStrategy-carrying players, a stage-game payoff matrix,
# and a discount factor, simulate play and return the discounted-sum payoffs.
#
# The solver does not search for equilibria — it evaluates a *named*
# strategy profile (TFT vs. TFT, Grim vs. Defector, etc.). That matches
# how Axelrod's tournaments are conventionally stated and lets the
# compliance suite check "cooperation emerges under TFT with δ high enough."

"""
    RepeatedGameSolver

Phase 1 solver for repeated stage games. Reads per-player PlayerStrategy
from `world.metadata["players"]` (or falls back to strategy-free defaults)
and simulates `horizon` rounds, applying the stage-game payoff matrix at
each round and discounting by `discount_factor^t`.
"""
struct RepeatedGameSolver <: SolverMethod
    horizon::Int
    discount_factor::Float64
end
RepeatedGameSolver() = RepeatedGameSolver(50, 0.95)

"""
    RepeatedGameResult

Per-round trajectory plus discounted payoffs. The trajectory records which
action each player took in each round; a downstream renderer (Pluto,
MCP explainer) reads it via `provenance_chain`.
"""
struct RepeatedGameResult
    trajectory::Vector{Dict{Symbol, Symbol}}    # round → (player_id → action_id)
    stage_payoffs::Vector{Dict{Symbol, Float64}}
    discounted_payoffs::Dict{Symbol, Float64}
    horizon::Int
    discount_factor::Float64
    provenance_chain::Vector{ProvenanceNode}

    function RepeatedGameResult(traj, stage, disc, h, δ, chain)
        isempty(chain) && error("RepeatedGameResult requires non-empty provenance_chain")
        new(traj, stage, disc, h, δ, chain)
    end
end

"""
    solve(world, ::RepeatedGameSolver) -> RepeatedGameResult

Simulate `horizon` rounds of the stage game with each player following the
`PlayerStrategy` attached to them in `world.metadata["players"]`. If a
player has no strategy (i.e. defaults), we fall back to always-defect as
the stage-game Nash baseline so a lone TFT is still testable against it.

For each round:
  1. Each player chooses an action via `choose_action(strategy, state, available)`.
  2. The joint action resolves to a stage-game payoff via the payoff matrix.
  3. The state's `history` is appended to so reciprocity strategies can see
     what their opponent did last round.

Discounted payoff for player p is `Σ_t δ^t · u_p(stage_t)`.
"""
function solve(world::StrategicWorld, method::RepeatedGameSolver)::RepeatedGameResult
    matrix = get(get(world.metadata, "payoffs", Dict()), "matrix", Dict())
    actions = get(world.metadata, "actions", Action[])
    isempty(matrix) &&
        error("RepeatedGameSolver: world.metadata[\"payoffs\"][\"matrix\"] is empty")
    isempty(actions) && error("RepeatedGameSolver: world.metadata[\"actions\"] is empty")

    player_ids = unique(a.player_id for a in actions)
    players = _players_with_strategies(world, player_ids)
    acts_by_player = Dict(pid => [a for a in actions if a.player_id == pid]
    for pid in player_ids)

    δ = method.discount_factor
    trajectory = Dict{Symbol, Symbol}[]
    stage_payoffs = Dict{Symbol, Float64}[]
    discounted = Dict{Symbol, Float64}(pid => 0.0 for pid in player_ids)

    state = State(Dict{Symbol, Any}(), Tuple{Symbol, Symbol}[], nothing, 0)

    for t in 0:(method.horizon - 1)
        state = State(state.variables, state.history, nothing, t)
        chosen = Dict{Symbol, Symbol}()
        for p in players
            available = acts_by_player[p.id]
            isempty(available) && continue
            a = choose_action(p.strategy, state, available)
            chosen[p.id] = a.id
        end

        key = _stage_key(player_ids, chosen)
        pf_raw = _lookup_payoff_dict(matrix, key)
        stage = pf_raw === nothing ?
                Dict{Symbol, Float64}(pid => 0.0 for pid in player_ids) :
                Dict(Symbol(k) => Float64(v) for (k, v) in pf_raw)

        push!(trajectory, chosen)
        push!(stage_payoffs, stage)
        for pid in player_ids
            discounted[pid] += (δ^t) * get(stage, pid, 0.0)
        end

        # Append the joint move to history *after* each player has chosen,
        # so reciprocity strategies see the completed previous round.
        new_history = vcat(state.history, [(pid, chosen[pid])
                                           for pid in player_ids if haskey(chosen, pid)])
        state = State(state.variables, new_history, nothing, t + 1)
    end

    prov = ProvenanceNode[]
    push!(prov,
        ProvenanceNode(
            "repeated_game_setup", "Chapter 4",
            "Repeated stage game: horizon=$(method.horizon), δ=$(δ), " *
            "strategies: $(join(["$(p.id)=$(nameof(typeof(p.strategy)))" for p in players], ", ")).";
            parent_id = "",
            theoretical_origin = "Axelrod, The Evolution of Cooperation (1984)"
        ))

    # Cooperation emergence annotation — the headline claim of Chapter 4.
    # Count rounds where every player's action contains the substring "cooperate".
    coop_rounds = count(r -> all(aid -> _is_cooperative(aid), values(r)), trajectory)
    if coop_rounds > 0
        push!(prov,
            ProvenanceNode(
                "cooperation_emerged", "Chapter 4",
                "Mutual cooperation in $(coop_rounds)/$(method.horizon) rounds under " *
                "discount δ=$(δ). Folk-theorem bound: cooperation sustainable when " *
                "δ ≥ (T − R)/(T − P), where R/T/P/S are the stage-game payoffs.";
                parent_id = prov[end].id === nothing ? "" : prov[end].id
            ))
    end

    push!(prov,
        ProvenanceNode(
            "repeated_game_complete", "Chapter 4",
            "Discounted payoffs: " *
            join(["$(pid)=$(round(discounted[pid]; digits=3))" for pid in player_ids], ", ");
            parent_id = prov[end].id === nothing ? "" : prov[end].id
        ))

    RepeatedGameResult(trajectory, stage_payoffs, discounted,
        method.horizon, δ, prov)
end

# --- Simulation primitive ------------------------------------------------

"""
    simulate(world, strategies; horizon) -> RepeatedGameResult

Run a strategy profile against `world` for `horizon` rounds. `strategies`
is a `Dict{Symbol, PlayerStrategy}` mapping player_id to the strategy the
player uses each round. Convenience wrapper over `RepeatedGameSolver` that
does not require stuffing strategies into `world.metadata`.
"""
function simulate(world::StrategicWorld,
        strategies::Dict{Symbol, <:PlayerStrategy};
        horizon::Int = 50,
        discount_factor::Float64 = 0.95)::RepeatedGameResult
    meta = copy(world.metadata)
    existing = get(meta, "players", Player[])
    action_ids = unique(a.player_id for a in get(meta, "actions", Action[]))

    overridden = Player[]
    for pid in action_ids
        strat = get(strategies, pid, nothing)
        base = _find_player(existing, pid)
        params = base === nothing ? PlayerParameters(1.0, discount_factor, 0.0, 0.0) :
                 base.parameters
        name = base === nothing ? string(pid) : base.name
        push!(overridden, Player(pid, name,
            strat === nothing ? _default_strategy(pid) : strat,
            params))
    end
    meta["players"] = overridden
    new_world = StrategicWorld(world.id, world.game, world.traits,
        copy(world.provenance), meta)
    solve(new_world, RepeatedGameSolver(horizon, discount_factor))
end

# --- Helpers -------------------------------------------------------------

function _players_with_strategies(world::StrategicWorld, player_ids::Vector{Symbol})
    existing = get(world.metadata, "players", Player[])
    [begin
         p = _find_player(existing, pid)
         if p === nothing
             Player(pid, string(pid),
                 _default_strategy(pid),
                 PlayerParameters(1.0, 0.95, 0.0, 0.0))
         else
             p
         end
     end
     for pid in player_ids]
end

function _find_player(players, pid::Symbol)
    for p in players
        p isa Player && p.id == pid && return p
    end
    nothing
end

# Default strategy for a player with no explicit assignment. `AlwaysDefect`
# is the stage-game Nash of the PD; serves as a rational baseline opponent.
struct AlwaysDefect <: PlayerStrategy
    opponent_id::Symbol
end
function choose_action(::AlwaysDefect, ::State, available::Vector{Action})
    _find(available, :defect)
end

_default_strategy(pid::Symbol) = AlwaysDefect(pid)

# Join the joint action into a matrix key "a1.a2[.a3...]" following the
# declared player_ids order. Matches the DSL payoff-key convention.
function _stage_key(player_ids::Vector{Symbol}, chosen::Dict{Symbol, Symbol})::String
    parts = String[]
    for pid in player_ids
        haskey(chosen, pid) || return ""
        push!(parts, string(chosen[pid]))
    end
    join(parts, ".")
end

# A loose notion of "cooperative": any action whose symbol contains
# "cooperate". Keeps the cooperation-emergence heuristic chapter-agnostic.
_is_cooperative(aid::Symbol) = occursin("cooperate", string(aid))
