struct BackwardInduction <: SolverMethod end

"""
    solve(world, ::BackwardInduction) -> Solution

Memoized backward induction over the payoff matrix stored in world.metadata.
Supports sequential and simultaneous structures. Every meaningful step
appends a ProvenanceNode citing Chapter 2.
"""
function solve(world::StrategicWorld, ::BackwardInduction)
    matrix  = get(get(world.metadata, "payoffs", Dict()), "matrix", Dict())
    actions = get(world.metadata, "actions", Action[])
    order   = get(world.metadata, "move_order", Symbol[])
    provenance = ProvenanceNode[]

    if isempty(order)
        # Simultaneous: find Nash via best-response (for 2-player games)
        return _solve_simultaneous(world, matrix, actions, provenance)
    else
        return _solve_sequential(world, matrix, actions, order, provenance)
    end
end

function _solve_sequential(world, matrix, actions, order, provenance)
    # Backward induction: work from last mover to first
    players = reverse(order)
    # Build action map per player
    acts_by_player = Dict(pid => [a for a in actions if a.player_id == pid] for pid in order)

    # For 2-player sequential: enumerate all paths, pick SPE by backward induction
    p1, p2 = order[1], order[2]
    p1_acts = acts_by_player[p1]
    p2_acts = acts_by_player[p2]

    # For each p1 action, find p2's best response
    best_path = Action[]
    best_payoffs = Dict{Symbol, Float64}()
    best_p1_payoff = -Inf

    for a1 in p1_acts
        # p2 best response given a1
        best_p2 = nothing
        best_p2_payoff = -Inf
        for a2 in p2_acts
            key = "$(a1.id).$(a2.id)"
            pf = _lookup_payoff_dict(matrix, key)
            pf === nothing && continue
            p2_val = get(pf, p2, get(pf, string(p2), 0.0))
            if p2_val > best_p2_payoff
                best_p2_payoff = p2_val
                best_p2 = a2
            end
        end
        # Check wildcard terminal (e.g. "stay_out.*")
        wildcard_key = "$(a1.id).*"
        wc_pf = _lookup_payoff_dict(matrix, wildcard_key)
        if wc_pf !== nothing && haskey(matrix, wildcard_key)
            push!(provenance, ProvenanceNode(
                "backward_induction_step", "Chapter 2",
                "$(p1) plays $(a1.id): terminal (wildcard)";
                parent_id = ""
            ))
            p1_val = get(wc_pf, p1, get(wc_pf, string(p1), 0.0))
            if p1_val > best_p1_payoff
                best_p1_payoff = p1_val
                best_path = [a1]
                best_payoffs = Dict(Symbol(k) => v for (k,v) in wc_pf)
            end
            continue
        end
        best_p2 === nothing && continue
        key = "$(a1.id).$(best_p2.id)"
        pf = _lookup_payoff_dict(matrix, key)
        pf === nothing && continue
        p1_val = get(pf, p1, get(pf, string(p1), 0.0))
        push!(provenance, ProvenanceNode(
            "backward_induction_step", "Chapter 2",
            "$(p2) best-responds to $(a1.id) with $(best_p2.id) (payoff=$(best_p2_payoff))";
            parent_id = ""
        ))
        if p1_val > best_p1_payoff
            best_p1_payoff = p1_val
            best_path = [a1, best_p2]
            best_payoffs = Dict(Symbol(k) => v for (k,v) in pf)
        end
    end

    push!(provenance, ProvenanceNode(
        "backward_induction_complete", "Chapter 2",
        "SPE path: $(join(map(a->a.id, best_path), " → "))";
        parent_id = ""
    ))
    Solution(best_path, best_payoffs, provenance)
end

function _solve_simultaneous(world, matrix, actions, provenance)
    players = unique(a.player_id for a in actions)
    length(players) != 2 && error("BackwardInduction: simultaneous solver supports 2 players only")
    p1, p2 = players[1], players[2]
    p1_acts = [a for a in actions if a.player_id == p1]
    p2_acts = [a for a in actions if a.player_id == p2]

    # Find Nash equilibrium via iterated best response
    best_path = Action[]
    best_payoffs = Dict{Symbol, Float64}()

    for a1 in p1_acts
        for a2 in p2_acts
            key = "$(a1.id).$(a2.id)"
            pf = _lookup_payoff_dict(matrix, key)
            pf === nothing && continue
            # Check if (a1,a2) is a Nash: no player wants to deviate
            p1_val = get(pf, p1, get(pf, string(p1), 0.0))
            p2_val = get(pf, p2, get(pf, string(p2), 0.0))
            p1_nash = all(a -> begin
                k2 = "$(a.id).$(a2.id)"
                pf2 = _lookup_payoff_dict(matrix, k2)
                pf2 === nothing ? true : get(pf2, p1, get(pf2, string(p1), 0.0)) <= p1_val
            end, p1_acts)
            p2_nash = all(a -> begin
                k2 = "$(a1.id).$(a.id)"
                pf2 = _lookup_payoff_dict(matrix, k2)
                pf2 === nothing ? true : get(pf2, p2, get(pf2, string(p2), 0.0)) <= p2_val
            end, p2_acts)
            if p1_nash && p2_nash
                push!(provenance, ProvenanceNode(
                    "nash_equilibrium_found", "Chapter 2",
                    "Nash equilibrium: ($(a1.id), $(a2.id)) payoffs=$(pf)";
                    parent_id = ""
                ))
                best_path = [a1, a2]
                best_payoffs = Dict(Symbol(k) => v for (k,v) in pf)
            end
        end
    end

    isempty(provenance) && push!(provenance, ProvenanceNode(
        "no_pure_nash", "Chapter 2", "No pure Nash equilibrium found"; parent_id = ""
    ))
    Solution(best_path, best_payoffs, isempty(provenance) ?
        [ProvenanceNode("backward_induction", "Chapter 2", "complete"; parent_id="")] : provenance)
end

function _lookup_payoff_dict(matrix::AbstractDict, key::String)
    haskey(matrix, key) && return matrix[key]
    for (k, v) in matrix
        if endswith(k, ".*") && startswith(key, k[1:end-1])
            return v
        end
    end
    nothing
end
