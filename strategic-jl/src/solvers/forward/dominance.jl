# Iterated elimination of dominated strategies (Chapter 3 solver).
# Runs before BackwardInduction to shrink the tree; also serves as a
# standalone analysis for "what survives rationalizability?"

"""
    solve(world, ::IteratedDominance) -> RationalizableSet

Phase 1 skeleton — tasks.md 1.4.

Algorithm:
  1. For each player, compute strictly-dominated actions given opponents'
     full action sets.
  2. Remove those actions; repeat until no further eliminations possible.
  3. Return RationalizableSet per player with full elimination trace.

Every elimination step appends a ProvenanceNode citing Chapter 3 and the
specific dominance relation used.
"""
function dominates(
        world::StrategicWorld,
        player::Player,
        a::Symbol,
        b::Symbol,
        opponents::Vector;
        strict::Bool = true
)::Bool
    matrix = get(get(world.metadata, "payoffs", Dict()), "matrix", Dict())
    isempty(matrix) && return false
    actions = get(world.metadata, "actions", Action[])
    # The payoff matrix is keyed in declared player order. Reconstruct the
    # join order from the action list so keys match regardless of which
    # player we're checking.
    declared_order = unique(act.player_id for act in actions)
    opp_action_sets = [[act for act in actions if act.player_id == opp]
                       for opp in opponents]
    isempty(opp_action_sets) && return false
    opp_combos = _cartesian(opp_action_sets)
    payoff_a = Float64[]
    payoff_b = Float64[]
    for combo in opp_combos
        opp_action_map = Dict(opponents[i] => combo[i].id for i in eachindex(opponents))
        key_a = _profile_key(declared_order, player.id, a, opp_action_map)
        key_b = _profile_key(declared_order, player.id, b, opp_action_map)
        pa = _lookup_payoff(matrix, key_a, player.id)
        pb = _lookup_payoff(matrix, key_b, player.id)
        (pa === nothing || pb === nothing) && continue
        push!(payoff_a, pa)
        push!(payoff_b, pb)
    end
    isempty(payoff_a) && return false
    if strict
        return all(payoff_a .> payoff_b)
    else
        return all(payoff_a .>= payoff_b) && any(payoff_a .> payoff_b)
    end
end

function _profile_key(declared_order::Vector{Symbol}, self_id::Symbol,
        self_action::Symbol, opp_action_map::AbstractDict)::String
    parts = String[]
    for pid in declared_order
        if pid == self_id
            push!(parts, string(self_action))
        else
            haskey(opp_action_map, pid) || return ""
            push!(parts, string(opp_action_map[pid]))
        end
    end
    join(parts, ".")
end

function _cartesian(sets)
    isempty(sets) && return [[]]
    result = [[x] for x in sets[1]]
    for s in sets[2:end]
        result = [vcat(r, [x]) for r in result for x in s]
    end
    result
end

function _lookup_payoff(matrix::AbstractDict, key::String, player_id::Symbol)
    inner = haskey(matrix, key) ? matrix[key] : nothing
    if inner === nothing
        for (k, v) in matrix
            if endswith(k, ".*") && startswith(key, k[1:(end - 1)])
                inner = v
                break
            end
        end
    end
    inner === nothing && return nothing
    # Support both Symbol and String inner-dict keys — the DSL uses Symbol,
    # the JGDL deserializer may use String.
    haskey(inner, player_id) && return inner[player_id]
    haskey(inner, string(player_id)) && return inner[string(player_id)]
    nothing
end

"""
    IteratedDominanceResult

Per-player `RationalizableSet`s surviving iterated elimination of dominated
strategies, plus the full elimination trace as provenance. Returned by
`solve(world, ::IteratedDominance)`.
"""
struct IteratedDominanceResult
    sets::Vector{RationalizableSet}          # one per player
    eliminations::Vector{DominanceRelation}  # chronological elimination log
    provenance_chain::Vector{ProvenanceNode}

    function IteratedDominanceResult(sets, elims, chain)
        isempty(chain) &&
            error("IteratedDominanceResult requires non-empty provenance_chain")
        new(sets, elims, chain)
    end
end

function solve(world::StrategicWorld, method::IteratedDominance)::IteratedDominanceResult
    actions = get(world.metadata, "actions", Action[])
    players = unique(a.player_id for a in actions)
    surviving = Dict(pid => [a.id for a in actions if a.player_id == pid]
    for pid in players)
    eliminated = DominanceRelation[]
    provenance = ProvenanceNode[]
    parent = isempty(world.provenance) ? "" :
             (world.provenance[end].id === nothing ? "" : world.provenance[end].id)
    round = 0
    changed = true
    while changed
        changed = false
        round += 1
        for pid in players
            player = Player(pid, string(pid), TitForTat(pid), PlayerParameters(1.0, 0.9, 0.0, 0.0))
            opponents = [p for p in players if p != pid]
            to_remove = Symbol[]
            for b in surviving[pid]
                b ∈ to_remove && continue
                for a in surviving[pid]
                    a == b && continue
                    a ∈ to_remove && continue
                    if _dominates_in_surviving(world, player, a, b, opponents, surviving;
                        strict = !method.allow_weak)
                        push!(to_remove, b)
                        rel = DominanceRelation(pid, a, b, !method.allow_weak)
                        push!(eliminated, rel)
                        node = ProvenanceNode(
                            "eliminated_dominated_action", "Chapter 3",
                            "Action :$b dominated by :$a for player :$pid (round $round)";
                            parent_id = parent
                        )
                        push!(provenance, node)
                        parent = node.id === nothing ? parent : node.id
                        changed = true
                        break
                    end
                end
            end
            surviving[pid] = filter(a -> a ∉ to_remove, surviving[pid])
        end
    end

    sets = [RationalizableSet(pid, surviving[pid],
                [(e.dominated, e) for e in eliminated if e.player_id == pid])
            for pid in players]

    if isempty(provenance)
        push!(provenance,
            ProvenanceNode(
                "iterated_dominance_fixpoint", "Chapter 3",
                "No actions eliminated; every declared action is rationalizable.";
                parent_id = parent
            ))
    else
        summary = join(
            ["$(pid) → {$(join(string.(surviving[pid]), ", "))}"
             for pid in players], "; ")
        push!(provenance,
            ProvenanceNode(
                "iterated_dominance_complete", "Chapter 3",
                "Rationalizable sets after $(round) round(s): $summary";
                parent_id = parent,
                theoretical_origin = "Bernheim, Rationalizable Strategic Behavior (1984); Pearce, Rationalizable Strategic Behavior and the Problem of Perfection (1984)"
            ))
    end

    IteratedDominanceResult(sets, eliminated, provenance)
end

# dominance check restricted to the current surviving action sets of opponents.
# Required for *iterated* elimination: a later round only considers strategies
# opponents still have available.
function _dominates_in_surviving(
        world::StrategicWorld,
        player::Player,
        a::Symbol,
        b::Symbol,
        opponents::Vector,
        surviving::Dict;
        strict::Bool = true
)::Bool
    matrix = get(get(world.metadata, "payoffs", Dict()), "matrix", Dict())
    isempty(matrix) && return false
    actions = get(world.metadata, "actions", Action[])
    declared_order = unique(act.player_id for act in actions)
    opp_action_sets = [[Action(aid, string(aid), opp)
                        for aid in get(surviving, opp, Symbol[])]
                       for opp in opponents]
    isempty(opp_action_sets) && return false
    opp_combos = _cartesian(opp_action_sets)
    payoff_a = Float64[]
    payoff_b = Float64[]
    for combo in opp_combos
        opp_action_map = Dict(opponents[i] => combo[i].id for i in eachindex(opponents))
        key_a = _profile_key(declared_order, player.id, a, opp_action_map)
        key_b = _profile_key(declared_order, player.id, b, opp_action_map)
        pa = _lookup_payoff(matrix, key_a, player.id)
        pb = _lookup_payoff(matrix, key_b, player.id)
        (pa === nothing || pb === nothing) && continue
        push!(payoff_a, pa)
        push!(payoff_b, pb)
    end
    isempty(payoff_a) && return false
    if strict
        return all(payoff_a .> payoff_b)
    else
        return all(payoff_a .>= payoff_b) && any(payoff_a .> payoff_b)
    end
end
