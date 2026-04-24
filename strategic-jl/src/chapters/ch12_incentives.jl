# Chapter 12: Incentives — Tournaments and relative-payoff incentives.

struct TournamentIncentiveTrait <: GameTrait
    weight_on_relative::Float64  # How much the player weights (own - opponent) vs. own absolute payoff.
end

register_trait!(TournamentIncentiveTrait, Set([:payoff]))

function payoff(g::WithTrait{<:AbstractGame, TournamentIncentiveTrait}, state::State)
    base = payoff(g.inner, state)
    w = g.trait.weight_on_relative
    # Symmetric two-player tournament transform; generalize when needed.
    players = collect(keys(base))
    if length(players) == 2
        p1, p2 = players
        base = Dict(p1 => base[p1] + w * (base[p1] - base[p2]),
            p2 => base[p2] + w * (base[p2] - base[p1]))
    end
    base
end
