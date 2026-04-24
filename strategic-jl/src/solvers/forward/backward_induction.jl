struct BackwardInduction <: SolverMethod end

"""
    solve(world, ::BackwardInduction) -> Solution

Memoized backward induction over the payoff matrix stored in world.metadata.
Supports sequential and simultaneous structures. Every meaningful step
appends a ProvenanceNode citing Chapter 2.
"""
function solve(world::StrategicWorld, ::BackwardInduction)
    matrix = get(get(world.metadata, "payoffs", Dict()), "matrix", Dict())
    actions = get(world.metadata, "actions", Action[])
    order = get(world.metadata, "move_order", Symbol[])
    provenance = ProvenanceNode[]

    result = if isempty(order)
        _solve_simultaneous(world, matrix, actions, provenance)
    else
        _solve_sequential(world, matrix, actions, order, provenance)
    end

    # Post-process: focal equilibrium selection (Chapter 9)
    solve_with_focal(world, result)
end

function _solve_sequential(world, matrix, actions, order, provenance)
    # Backward induction: work from last mover to first
    players = reverse(order)
    # Build action map per player
    acts_by_player = Dict(pid => [a for a in actions if a.player_id == pid]
    for pid in order)

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
            pf = _apply_trait_transforms(world, Dict(Symbol(k) => v for (k, v) in pf);
                actions = [a1.id, a2.id])
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
            push!(provenance,
                ProvenanceNode(
                    "backward_induction_step", "Chapter 2",
                    "$(p1) plays $(a1.id): terminal (wildcard)";
                    parent_id = ""
                ))
            wc_pf_t = _apply_trait_transforms(
                world, Dict(Symbol(k) => v for (k, v) in wc_pf);
                actions = [a1.id])
            p1_val = get(wc_pf_t, p1, get(wc_pf_t, string(p1), 0.0))
            if p1_val > best_p1_payoff
                best_p1_payoff = p1_val
                best_path = [a1]
                best_payoffs = wc_pf_t
            end
            continue
        end
        best_p2 === nothing && continue
        key = "$(a1.id).$(best_p2.id)"
        pf = _lookup_payoff_dict(matrix, key)
        pf === nothing && continue
        pf = _apply_trait_transforms(world, Dict(Symbol(k) => v for (k, v) in pf);
            actions = [a1.id, best_p2.id])
        p1_val = get(pf, p1, get(pf, string(p1), 0.0))
        push!(provenance,
            ProvenanceNode(
                "backward_induction_step", "Chapter 2",
                "$(p2) best-responds to $(a1.id) with $(best_p2.id) (payoff=$(best_p2_payoff))";
                parent_id = ""
            ))
        if p1_val > best_p1_payoff
            best_p1_payoff = p1_val
            best_path = [a1, best_p2]
            best_payoffs = Dict(Symbol(k) => v for (k, v) in pf)
        end
    end

    push!(provenance,
        ProvenanceNode(
            "backward_induction_complete", "Chapter 2",
            "SPE path: $(join(map(a->a.id, best_path), " → "))";
            parent_id = ""
        ))
    Solution(best_path, best_payoffs, provenance)
end

function _solve_simultaneous(world, matrix, actions, provenance)
    players = unique(a.player_id for a in actions)
    length(players) != 2 &&
        error("BackwardInduction: simultaneous solver supports 2 players only")
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
            pf = _apply_trait_transforms(world, Dict(Symbol(k) => v for (k, v) in pf);
                actions = [a1.id, a2.id])
            # Check if (a1,a2) is a Nash: no player wants to deviate
            p1_val = get(pf, p1, get(pf, string(p1), 0.0))
            p2_val = get(pf, p2, get(pf, string(p2), 0.0))
            p1_nash = all(
                a -> begin
                    k2 = "$(a.id).$(a2.id)"
                    pf2 = _lookup_payoff_dict(matrix, k2)
                    pf2 === nothing ? true :
                    begin
                        pf2t = _apply_trait_transforms(
                            world, Dict(Symbol(k)=>v for (k, v) in pf2);
                            actions = [a.id, a2.id])
                        get(pf2t, p1, 0.0) <= p1_val
                    end
                end,
                p1_acts)
            p2_nash = all(
                a -> begin
                    k2 = "$(a1.id).$(a.id)"
                    pf2 = _lookup_payoff_dict(matrix, k2)
                    pf2 === nothing ? true :
                    begin
                        pf2t = _apply_trait_transforms(
                            world, Dict(Symbol(k)=>v for (k, v) in pf2);
                            actions = [a1.id, a.id])
                        get(pf2t, p2, 0.0) <= p2_val
                    end
                end,
                p2_acts)
            if p1_nash && p2_nash
                push!(provenance,
                    ProvenanceNode(
                        "nash_equilibrium_found", "Chapter 2",
                        "Nash equilibrium: ($(a1.id), $(a2.id)) payoffs=$(pf)";
                        parent_id = ""
                    ))
                best_path = [a1, a2]
                best_payoffs = Dict(Symbol(k) => v for (k, v) in pf)
            end
        end
    end

    isempty(provenance) && push!(provenance,
        ProvenanceNode(
            "no_pure_nash", "Chapter 2", "No pure Nash equilibrium found"; parent_id = ""
        ))
    Solution(best_path,
        best_payoffs,
        isempty(provenance) ?
        [ProvenanceNode("backward_induction", "Chapter 2", "complete"; parent_id = "")] :
        provenance)
end

"""
    _apply_trait_transforms(world, pf; actions=Symbol[])

Route the raw payoff cell `pf` through the trait stack. `actions` is the
joint action profile that produced the cell — needed for traits that
depend on what was played (Commitment, Brinkmanship, CredibleThreat).

Order matches `world.traits`: earlier traits are applied first, so a
later trait sees the transformed payoff.
"""
function _apply_trait_transforms(world::StrategicWorld, pf::Dict;
        actions::Vector{Symbol} = Symbol[])::Dict
    pf = Dict{Symbol, Float64}(k => Float64(v) for (k, v) in pf)
    for t in world.traits
        pf = _apply_trait(t, pf, actions)
    end
    pf
end

_apply_trait(t::GameTrait, pf::Dict, actions::Vector{Symbol}) = pf

function _apply_trait(t::TournamentIncentiveTrait, pf::Dict, ::Vector{Symbol})
    w = t.weight_on_relative
    players = collect(keys(pf))
    length(players) == 2 || return pf
    p1, p2 = players
    Dict(p1 => pf[p1] + w * (pf[p1] - pf[p2]),
        p2 => pf[p2] + w * (pf[p2] - pf[p1]))
end

function _apply_trait(t::CommitmentTrait, pf::Dict, actions::Vector{Symbol})
    # If the committed player deviated (their action isn't the committed one),
    # subtract the penalty. Ch 5 semantics: commitment binds the player to
    # the declared action; deviation is costly.
    isempty(actions) && return pf
    # Find this player's action in the profile. With only the joint key we
    # need a separate view — the caller passes the action list ordered by
    # the player index of the matrix key.
    committed_played = any(a -> a == t.committed_action, actions)
    committed_played && return pf
    # The committed action wasn't taken; penalize.
    out = copy(pf)
    out[t.player_id] = get(out, t.player_id, 0.0) - t.penalty_for_deviation
    out
end

function _apply_trait(t::BrinkmanshipTrait, pf::Dict, actions::Vector{Symbol})
    # If the risky action shows up in the joint profile, blend payoffs.
    any(a -> a == t.risky_action, actions) || return pf
    p = t.catastrophe_probability
    players = union(keys(pf), keys(t.catastrophic_payoff))
    Dict{Symbol, Float64}(k => (1 - p) * get(pf, k, 0.0) +
                               p * get(t.catastrophic_payoff, k, 0.0)
    for k in players)
end

# CredibleThreat and BurnedBridge are handled at the available-action layer
# (before the matrix lookup), not by transforming a given cell. BurnedBridge
# pre-filtering happens in the deserializer + DSL; CredibleThreat would need
# the solver to walk turn-by-turn, which this matrix-based solver doesn't
# do today. Keep the no-op fallback and document the limitation.
# _apply_trait(::CredibleThreatTrait, pf, _) → falls through to default no-op.

function _lookup_payoff_dict(matrix::AbstractDict, key::String)
    haskey(matrix, key) && return matrix[key]
    for (k, v) in matrix
        if endswith(k, ".*") && startswith(key, k[1:(end - 1)])
            return v
        end
    end
    nothing
end
