struct ObservedPlay
    context::State
    action_taken::Symbol
    player_id::Symbol
    timestamp::DateTime
    confidence::Float64
end

struct HypothesisWorld
    world::StrategicWorld
    prior::Float64
    posterior::Float64
    provenance::Vector{ProvenanceNode}  # Why this hypothesis was proposed & how it fared.
end

struct PosteriorWorldDistribution
    hypotheses::Vector{HypothesisWorld}
end

"""
    infer_from_observations(observations, hypotheses) -> PosteriorWorldDistribution

Phase 2 inverse solver. Returns a ranked distribution, not just a MAP estimate.
Every hypothesis carries its own provenance chain.

Phase 2 skeleton — fill in during task 2.3.
"""
function infer_from_observations(
    observations::Vector{ObservedPlay},
    hypotheses::Vector{StrategicWorld}
)
    error("Phase 2: inverse Bayesian solver not yet implemented (tasks.md 2.3)")
end
