# Chapter 10: The Strategy of Voting — voting rules as game structure.

struct VotingRuleTrait <: GameTrait
    rule::Symbol   # :plurality, :majority, :borda, :condorcet, :approval
    members::Int
end

register_trait!(VotingRuleTrait, Set([:aggregate]))

struct VotingSolver <: SolverMethod end

struct VotingResult
    condorcet_winner::Union{String, Nothing}
    cycle_detected::Bool
    cycle::Vector{String}           # e.g. ["A beats B", "B beats C", "C beats A"]
    pairwise_results::Dict{String, Dict{String, Bool}}  # winner => loser => true
    provenance::Vector{ProvenanceNode}
end

"""
    solve(world, ::VotingSolver) -> VotingResult

Pairwise Condorcet solver. Reads voter preferences from the VotingRuleTrait
parameters and computes pairwise majority comparisons.

Preferences format in trait parameters:
  { "voter1": ["A", "B", "C"], "voter2": ["B", "C", "A"], ... }
  (ordered from most to least preferred)
"""
function solve(world::StrategicWorld, ::VotingSolver)::VotingResult
    trait = findfirst(t -> t isa VotingRuleTrait, world.traits)
    prov = ProvenanceNode[]

    # Fall back to reading preferences from metadata if no trait
    preferences = _extract_preferences(world, trait)
    isempty(preferences) && return VotingResult(nothing, false, String[], Dict(), [
        ProvenanceNode("voting_solve","Chapter 10","No preferences found"; parent_id="")])

    options = unique(opt for prefs in values(preferences) for opt in prefs)
    n_voters = length(preferences)

    # Pairwise majority comparisons
    pairwise = Dict{String, Dict{String, Bool}}()
    for a in options, b in options
        a == b && continue
        a_beats_b = count(v -> begin
            prefs = get(preferences, v, String[])
            ia = findfirst(==(a), prefs)
            ib = findfirst(==(b), prefs)
            ia !== nothing && ib !== nothing && ia < ib
        end, keys(preferences))
        get!(pairwise, a, Dict())[b] = a_beats_b > n_voters / 2
    end

    push!(prov, ProvenanceNode("pairwise_comparison","Chapter 10",
        "Computed pairwise comparisons over $(n_voters) voters";
        parent_id="",
        theoretical_origin="Condorcet, Essai sur l'application de l'analyse (1785)"))

    # Find Condorcet winner: beats all others
    winner = nothing
    for a in options
        if all(b -> b == a || get(get(pairwise, a, Dict()), b, false), options)
            winner = a
            push!(prov, ProvenanceNode("condorcet_winner","Chapter 10",
                "Condorcet winner: $a beats all others in pairwise majority vote"; parent_id=""))
            break
        end
    end

    # Detect cycle if no winner
    cycle = String[]
    if winner === nothing
        # Find the majority cycle among top options. Skip any triple with a
        # repeated element (A beats A is not a cycle edge).
        for a in options, b in options, c in options
            (a == b || b == c || a == c) && continue
            if get(get(pairwise,a,Dict()),b,false) &&
               get(get(pairwise,b,Dict()),c,false) &&
               get(get(pairwise,c,Dict()),a,false)
                cycle = ["$a beats $b", "$b beats $c", "$c beats $a"]
                break
            end
        end
        push!(prov, ProvenanceNode("condorcet_cycle","Chapter 10",
            isempty(cycle) ? "No Condorcet winner; no simple cycle found" :
            "Condorcet paradox: $(join(cycle, ", "))"; parent_id=""))
    end

    VotingResult(winner, !isempty(cycle), cycle, pairwise, prov)
end

function _extract_preferences(world::StrategicWorld, trait_idx)::Dict{String, Vector{String}}
    # Try trait parameters first
    if trait_idx !== nothing
        t = world.traits[trait_idx]
        raw = get(world.metadata, "trait_params_$(t.rule)", nothing)
        raw !== nothing && return Dict(string(k) => collect(string.(v)) for (k,v) in raw)
    end
    # Fall back to metadata["preferences"]
    prefs = get(world.metadata, "preferences", nothing)
    prefs === nothing && return Dict{String,Vector{String}}()
    Dict(string(k) => collect(string.(v)) for (k,v) in prefs)
end
