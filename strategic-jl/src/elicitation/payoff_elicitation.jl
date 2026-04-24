# LLM-assisted payoff elicitation types.
# See docs/llm-payoff-elicitation.md for architecture and rationale.

const PAYOFF_LAYERS = (:material, :social, :temporal, :identity, :uncertainty)

"""
    PayoffLayerEstimate

One layer's contribution to a single player's payoff in a single outcome.
`confidence` is 0–1; low confidence signals the estimate should be treated as a prior
and corrected by the inverse solver as observations arrive.
"""
struct PayoffLayerEstimate
    layer::Symbol           # one of PAYOFF_LAYERS
    point_estimate::Float64
    confidence::Float64     # 0–1
    reasoning::String
    provenance::ProvenanceNode
end

"""
    ElicitedOutcomePayoff

All five layers for one player in one outcome, plus the aggregated total.
`total` is what the solver sees; the layer breakdown stays in provenance.
"""
struct ElicitedOutcomePayoff
    player_id::Symbol
    outcome_key::String     # e.g. "cooperate_1.cooperate_2"
    layers::Vector{PayoffLayerEstimate}
    total::Float64          # sum of point_estimates
    mean_confidence::Float64
end

function ElicitedOutcomePayoff(player_id::Symbol, outcome_key::String,
                                layers::Vector{PayoffLayerEstimate})
    total = sum(l.point_estimate for l in layers; init = 0.0)
    conf  = isempty(layers) ? 0.0 : sum(l.confidence for l in layers) / length(layers)
    ElicitedOutcomePayoff(player_id, outcome_key, layers, total, conf)
end

"""
    ElicitedPayoffMatrix

Full elicitation result for a world. `to_payoff_matrix()` extracts aggregated numbers
for the solver; layer breakdown is preserved in each entry's provenance.
"""
struct ElicitedPayoffMatrix
    description::String
    entries::Vector{ElicitedOutcomePayoff}
    elicitation_provenance::ProvenanceNode
end

"""
    to_payoff_matrix(em) -> Dict{String, Dict{Symbol, Float64}}

Extract the aggregated payoff matrix in the format expected by the solver
(`metadata["payoffs"]["matrix"]`).
"""
function to_payoff_matrix(em::ElicitedPayoffMatrix)::Dict{String, Dict{Symbol, Float64}}
    matrix = Dict{String, Dict{Symbol, Float64}}()
    for entry in em.entries
        row = get!(matrix, entry.outcome_key, Dict{Symbol, Float64}())
        row[entry.player_id] = entry.total
    end
    matrix
end

"""
    mean_confidence(em) -> Float64

Overall confidence of the elicitation. Values below 0.5 indicate the world should be
treated as a weak prior and corrected aggressively by the inverse solver.
"""
mean_confidence(em::ElicitedPayoffMatrix) =
    isempty(em.entries) ? 0.0 :
    sum(e.mean_confidence for e in em.entries) / length(em.entries)

"""
    build_world_from_elicitation(em, players, actions, structure) -> StrategicWorld

Construct a StrategicWorld from an ElicitedPayoffMatrix. The aggregated payoffs go into
metadata for the solver; the elicitation provenance is prepended to the world's chain.
"""
function build_world_from_elicitation(
    em::ElicitedPayoffMatrix,
    players::Vector,
    actions::Vector{Action},
    structure::Dict = Dict("type" => "simultaneous")
)::StrategicWorld
    matrix = to_payoff_matrix(em)
    metadata = Dict{String, Any}(
        "name"        => "Elicited: $(em.description[1:min(60,end)])",
        "description" => em.description,
        "actions"     => actions,
        "move_order"  => get(structure, "order", Symbol[]),
        "payoffs"     => Dict("type" => "terminal_matrix", "matrix" => matrix),
        "structure"   => structure,
        "elicitation_confidence" => mean_confidence(em),
    )
    StrategicWorld(
        "sha256:" * "0"^64,   # placeholder; world_id() computes the real hash
        _NullGame(),
        GameTrait[],
        [em.elicitation_provenance],
        metadata
    )
end

"""
    elicit_layer(layer, outcome_key, player_id, estimate, confidence, reasoning)
        -> PayoffLayerEstimate

Convenience constructor. The LLM (or a human) calls this once per layer per outcome.
"""
function elicit_layer(
    layer::Symbol,
    outcome_key::String,
    player_id::Symbol,
    estimate::Float64,
    confidence::Float64,
    reasoning::String
)::PayoffLayerEstimate
    layer ∈ PAYOFF_LAYERS || error("Unknown layer :$layer. Must be one of $PAYOFF_LAYERS")
    PayoffLayerEstimate(
        layer, estimate, clamp(confidence, 0.0, 1.0), reasoning,
        ProvenanceNode(
            "elicited_payoff_layer", "Chapter 1",
            "Layer :$layer for $player_id in '$outcome_key': " *
            "estimate=$(estimate), confidence=$(confidence). $reasoning";
            parent_id = ""
        )
    )
end
