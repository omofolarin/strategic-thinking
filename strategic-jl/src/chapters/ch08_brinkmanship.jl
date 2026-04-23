# Chapter 8: Brinkmanship — stochastic catastrophic payoff
# Some actions carry a probability of a shared disaster no party fully controls.

struct BrinkmanshipTrait <: GameTrait
    risky_action::Symbol
    catastrophe_probability::Float64
    catastrophic_payoff::Dict{Symbol, Float64}
end

register_trait!(BrinkmanshipTrait, Set([:payoff]))

"""
    payoff(g::WithTrait{<:AbstractGame, BrinkmanshipTrait}, state)

If the risky action appears in history, blend the base payoff with the
catastrophic payoff weighted by catastrophe_probability.
"""
function payoff(g::WithTrait{<:AbstractGame, BrinkmanshipTrait}, state::State)
    base = payoff(g.inner, state)
    t = g.trait
    triggered = any(h -> h[2] == t.risky_action, state.history)
    triggered || return base
    p = t.catastrophe_probability
    Dict(k => (1 - p) * get(base, k, 0.0) + p * get(t.catastrophic_payoff, k, 0.0)
         for k in union(keys(base), keys(t.catastrophic_payoff)))
end
