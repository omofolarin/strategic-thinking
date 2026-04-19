# Chapter 4: Resolving the Prisoner's Dilemma
#
# The one-shot PD has (Defect, Defect) as the unique Nash. Cooperation
# becomes sustainable only under repetition + reciprocity strategies.
# This chapter owns the *reciprocity strategies* as first-class
# PlayerStrategy types. The repeated-game *structure* already lives in
# the JGDL schema; this file is about the behavioral side.

"""
    TitForTat <: PlayerStrategy

Cooperate first, then mirror the opponent's previous action.
Axelrod's classical winner.
"""
struct TitForTat <: PlayerStrategy
    opponent_id::Symbol
end

"""
    GrimTrigger <: PlayerStrategy

Cooperate until the first defection, then defect forever. High cost of
defection on the opponent, but unforgiving — no recovery from noise.
"""
struct GrimTrigger <: PlayerStrategy
    opponent_id::Symbol
    triggered::Bool
end
GrimTrigger(opponent_id) = GrimTrigger(opponent_id, false)

"""
    Pavlov <: PlayerStrategy (Win-Stay, Lose-Shift)

If last round's payoff was good, repeat the action; otherwise switch.
More robust to noise than GrimTrigger, exploits All-Cooperate better
than TFT.
"""
struct Pavlov <: PlayerStrategy
    opponent_id::Symbol
    last_own_action::Union{Symbol, Nothing}
    last_payoff::Float64
end
Pavlov(opponent_id) = Pavlov(opponent_id, nothing, 0.0)

"""
    GenerousTFT <: PlayerStrategy

TFT with a forgiveness probability — sometimes cooperate after opponent
defection. Restores cooperation in noisy environments.
"""
struct GenerousTFT <: PlayerStrategy
    opponent_id::Symbol
    forgive_probability::Float64
end

# choose_action dispatches per strategy.
# Phase 1 skeleton — tasks.md 1.4 extension.

function choose_action(strat::TitForTat, state::State, available::Vector{Action})::Action
    error("Phase 1: TitForTat.choose_action not yet implemented")
end

function choose_action(strat::GrimTrigger, state::State, available::Vector{Action})::Action
    error("Phase 1: GrimTrigger.choose_action not yet implemented")
end

function choose_action(strat::Pavlov, state::State, available::Vector{Action})::Action
    error("Phase 1: Pavlov.choose_action not yet implemented")
end

function choose_action(strat::GenerousTFT, state::State, available::Vector{Action})::Action
    error("Phase 1: GenerousTFT.choose_action not yet implemented")
end
