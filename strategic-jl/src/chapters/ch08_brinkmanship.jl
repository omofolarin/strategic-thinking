# Chapter 8: Brinkmanship — stochastic catastrophic payoff
# Some actions carry a probability of a shared disaster no party fully controls.

struct BrinkmanshipTrait <: GameTrait
    risky_action::Symbol
    catastrophe_probability::Float64
    catastrophic_payoff::Dict{Symbol, Float64}  # Payoff to every player if catastrophe triggers.
end

register_trait!(BrinkmanshipTrait, Set([:transition, :payoff]))

# Phase 1 stub. Solver integration in ch08 lands with solvers/forward/backward_induction.jl.
