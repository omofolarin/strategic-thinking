# Chapter 7: Unpredictability — Mixed Strategies
# A player randomizes over pure actions; opponents cannot exploit a pattern.

struct MixedStrategyTrait <: GameTrait
    player_id::Symbol
    distribution::Dict{Symbol, Float64}   # action_id => probability
end

register_trait!(MixedStrategyTrait, Set([:sample_action]))

# Phase 1 stub: sampling + solver integration come online with Phase 1.4.
