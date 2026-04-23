# Chapter 7: Unpredictability — Mixed Strategies
# A player randomizes over pure actions; opponents cannot exploit a pattern.

struct MixedStrategyTrait <: GameTrait
    player_id::Symbol
    distribution::Dict{Symbol, Float64}   # action_id => probability
end

register_trait!(MixedStrategyTrait, Set([:sample_action]))

"""
    sample_action(g, state, player) -> Action

Draw one action from the mixed strategy distribution.
Falls back to uniform if the player is not the one with the trait.
"""
function sample_action(g::WithTrait{<:AbstractGame, MixedStrategyTrait},
                       state::State, player::Player)::Action
    t = g.trait
    if player.id != t.player_id
        acts = available_actions(g.inner, state, player)
        return acts[rand(1:length(acts))]
    end
    acts = available_actions(g.inner, state, player)
    ids  = [a.id for a in acts]
    probs = [get(t.distribution, id, 0.0) for id in ids]
    s = sum(probs)
    s == 0 && return acts[rand(1:length(acts))]
    probs ./= s
    r = rand()
    cumulative = 0.0
    for (i, p) in enumerate(probs)
        cumulative += p
        r <= cumulative && return acts[i]
    end
    acts[end]
end
