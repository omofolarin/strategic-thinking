# Chapter 11: Bargaining — Rubinstein alternating offers, patience as power.

struct BargainingProtocolTrait <: GameTrait
    players_order::Vector{Symbol}
    pie::Float64
    discount_factor::Float64
end

register_trait!(BargainingProtocolTrait, Set([:transition, :available_actions]))

struct BargainingSolver <: SolverMethod end

struct BargainingResult
    proposer::Symbol
    responder::Symbol
    proposer_share::Float64
    responder_share::Float64
    pie::Float64
    discount_factor::Float64
    responder_accepts::Bool
    provenance::Vector{ProvenanceNode}
end

"""
    solve(world, ::BargainingSolver) -> BargainingResult

Closed-form Rubinstein SPE split for two-player alternating-offers bargaining.

SPE shares:
  proposer  = pie × 1 / (1 + δ)
  responder = pie × δ / (1 + δ)

The responder accepts because their share equals their continuation value
(what they'd get as proposer in the next round, discounted by δ).
"""
function solve(world::StrategicWorld, ::BargainingSolver)::BargainingResult
    trait = findfirst(t -> t isa BargainingProtocolTrait, world.traits)
    prov = ProvenanceNode[]

    # Read parameters from trait or metadata
    if trait !== nothing
        t = world.traits[trait]
        players = t.players_order
        pie = t.pie
        δ = t.discount_factor
    else
        # Fall back to structure metadata
        structure = get(world.metadata, "structure", Dict())
        δ = Float64(get(structure, "discount_factor", 0.8))
        pie = Float64(get(world.metadata, "surplus", 100.0))
        actions = get(world.metadata, "actions", Action[])
        players = unique(a.player_id for a in actions)
    end

    length(players) < 2 && error("BargainingSolver: need at least 2 players")
    proposer = players[1]
    responder = players[2]

    proposer_share = pie * 1.0 / (1.0 + δ)
    responder_share = pie * δ / (1.0 + δ)

    push!(prov,
        ProvenanceNode(
            "bargaining_spe", "Chapter 11",
            "Rubinstein SPE: proposer=$(round(proposer_share; digits=2)), " *
            "responder=$(round(responder_share; digits=2)). " *
            "Formula: proposer=pie/(1+δ), responder=pie×δ/(1+δ), δ=$(δ). " *
            "Responder accepts: their share equals continuation value.";
            parent_id = "",
            theoretical_origin = "Rubinstein, Perfect Equilibrium in a Bargaining Model (1982)"
        ))

    BargainingResult(proposer, responder, proposer_share, responder_share,
        pie, δ, true, prov)
end
