# Surprise detector: flags observations that the current world model
# assigned low probability, spawns ranked explanations.

struct WorldMutationTemplate
    name::String                 # e.g. "new_player_emerged"
    chapter_ref::String
    applies::Function            # (world, observation) -> Bool
    apply::Function              # (world, observation) -> StrategicWorld
end

struct SurpriseEvent
    timestamp::DateTime
    observation  # ::ObservedPlay
    expected_probability::Float64
    magnitude::Float64           # -log(expected_probability)
    explanations::Vector{WorldMutationTemplate}
end

mutable struct SurpriseDetector
    threshold::Float64
    history::Vector{SurpriseEvent}
    templates::Vector{WorldMutationTemplate}
end

SurpriseDetector(threshold = 3.0) = SurpriseDetector(threshold, SurpriseEvent[], default_templates())

default_templates() = WorldMutationTemplate[]  # Filled in with Phase 3.

# Phase 3 skeleton — tasks.md 3.2.
