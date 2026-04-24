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
    # Cooperate on round 0; mirror opponent's last action thereafter
    opp_last = _last_action(state, strat.opponent_id)
    opp_last === nothing && return _find(available, :cooperate)
    _find(available, opp_last)
end

function choose_action(strat::GrimTrigger, state::State, available::Vector{Action})::Action
    triggered = strat.triggered ||
                any(h -> h[1] == strat.opponent_id && h[2] == :defect, state.history)
    triggered ? _find(available, :defect) : _find(available, :cooperate)
end

function choose_action(strat::Pavlov, state::State, available::Vector{Action})::Action
    # Win-stay, lose-shift: repeat last action if payoff was good (>= threshold), else switch
    strat.last_own_action === nothing && return _find(available, :cooperate)
    strat.last_payoff >= 2.0 ? _find(available, strat.last_own_action) :
    _toggle(available, strat.last_own_action)
end

function choose_action(strat::GenerousTFT, state::State, available::Vector{Action})::Action
    opp_last = _last_action(state, strat.opponent_id)
    opp_last === nothing && return _find(available, :cooperate)
    opp_last == :defect && rand() < strat.forgive_probability &&
        return _find(available, :cooperate)
    _find(available, opp_last)
end

# Helpers
function _last_action(state::State, player_id::Symbol)::Union{Symbol, Nothing}
    for (pid, aid) in Iterators.reverse(state.history)
        pid == player_id && return aid
    end
    nothing
end

function _find(available::Vector{Action}, id::Symbol)::Action
    idx = findfirst(a -> a.id == id || endswith(string(a.id), string(id)), available)
    idx !== nothing ? available[idx] : available[1]
end

function _toggle(available::Vector{Action}, last::Symbol)::Action
    other = findfirst(a -> a.id != last, available)
    other !== nothing ? available[other] : available[1]
end
