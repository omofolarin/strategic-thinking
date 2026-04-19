# Chapter 6: Credible Commitments — Threats and Burned Bridges
# Schelling's paradox: restricting your own options increases credibility.

struct CredibleThreatTrait <: GameTrait
    threatener_id::Symbol
    trigger_action::Symbol       # If this action is taken by opponent...
    retaliation_action::Symbol   # ...the threatener MUST do this.
    credibility::Float64         # Probability threat is carried out (0..1)
end

struct BurnedBridgeTrait <: GameTrait
    player_id::Symbol
    forbidden_action::Symbol     # This action is removed from the available set.
end

register_trait!(CredibleThreatTrait, Set([:available_actions]))
register_trait!(BurnedBridgeTrait,   Set([:available_actions]))

function available_actions(g::WithTrait{<:AbstractGame, BurnedBridgeTrait},
                           state::State, player::Player)
    actions = available_actions(g.inner, state, player)
    if player.id == g.trait.player_id
        return filter(a -> a.id != g.trait.forbidden_action, actions)
    end
    actions
end
