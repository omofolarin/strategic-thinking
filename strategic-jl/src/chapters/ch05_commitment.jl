# Chapter 5: Strategic Moves — Commitment
# A commitment binds the player's future action, altering the payoff function
# regardless of the payoff the player would face absent the commitment.

struct CommitmentTrait <: GameTrait
    player_id::Symbol
    committed_action::Symbol
    penalty_for_deviation::Float64
end

register_trait!(CommitmentTrait, Set([:payoff]))

function payoff(g::WithTrait{<:AbstractGame, CommitmentTrait}, state::State)
    base = payoff(g.inner, state)
    t = g.trait
    # If history shows the committed player did not take the committed action,
    # subtract the penalty from their payoff.
    deviated = any(h -> h[1] == t.player_id && h[2] != t.committed_action, state.history)
    if deviated
        base = copy(base)
        base[t.player_id] -= t.penalty_for_deviation
    end
    base
end
