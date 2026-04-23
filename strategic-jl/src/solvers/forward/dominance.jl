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
    player_actions = [act for act in get(world.metadata, "actions", Action[]) if act.player_id == player.id]
    opp_action_sets = [
        [act for act in get(world.metadata, "actions", Action[]) if act.player_id == opp]
        for opp in opponents
    ]
    isempty(opp_action_sets) && return false
    # Build all opponent action combinations
    opp_combos = _cartesian(opp_action_sets)
    payoff_a = Float64[]
    payoff_b = Float64[]
    for combo in opp_combos
        key_a = join([string(a); [string(oa.id) for oa in combo]], ".")
        key_b = join([string(b); [string(oa.id) for oa in combo]], ".")
        pa = _lookup_payoff(matrix, key_a, player.id)
        pb = _lookup_payoff(matrix, key_b, player.id)
        pa === nothing || pb === nothing && continue
        push!(payoff_a, pa)
        push!(payoff_b, pb)
    end
    isempty(payoff_a) && return false
    strict ? all(payoff_a .> payoff_b) : all(payoff_a .>= payoff_b) && any(payoff_a .> payoff_b)
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
    haskey(matrix, key) && return get(matrix[key], string(player_id), nothing)
    # Try wildcard: "stay_out.*"
    for (k, v) in matrix
        if endswith(k, ".*") && startswith(key, k[1:end-1])
            return get(v, string(player_id), nothing)
        end
    end
    nothing
end

function solve(world::StrategicWorld, method::IteratedDominance)
    actions = get(world.metadata, "actions", Action[])
    players = unique(a.player_id for a in actions)
    # surviving[player_id] = Vector{Symbol} of action ids
    surviving = Dict(pid => [a.id for a in actions if a.player_id == pid] for pid in players)
    eliminated = Tuple{Symbol, DominanceRelation}[]
    provenance = copy(world.provenance)
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
                for a in surviving[pid]
                    a == b && continue
                    # Build a temporary world with only surviving actions
                    if dominates(world, player, a, b, opponents; strict=method.allow_weak ? false : true)
                        push!(to_remove, b)
                        rel = DominanceRelation(pid, a, b, !method.allow_weak)
                        push!(eliminated, (b, rel))
                        push!(provenance, ProvenanceNode(
                            "eliminated_dominated_action", "Chapter 3",
                            "Action :$b dominated by :$a for player :$pid (round $round)";
                            parent_id = isempty(world.provenance) ? "" : world.provenance[end].id === nothing ? "" : world.provenance[end].id
                        ))
                        changed = true
                        break
                    end
                end
            end
            surviving[pid] = filter(a -> a ∉ to_remove, surviving[pid])
        end
    end
    sets = [RationalizableSet(pid, surviving[pid], [(e[1], e[2]) for e in eliminated if e[2].player_id == pid]) for pid in players]
    # Return as Solution with provenance
    isempty(provenance) && push!(provenance, ProvenanceNode("iterated_dominance", "Chapter 3", "No eliminations performed"; parent_id = ""))
    Solution(Action[], Dict(pid => 0.0 for pid in players), provenance)
end
