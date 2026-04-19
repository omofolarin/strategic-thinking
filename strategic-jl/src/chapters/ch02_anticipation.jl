# Chapter 2: Anticipating Your Rival's Response
#
# The substrate chapter for sequential reasoning. Owns the semantics of:
#   - move order
#   - information sets
#   - look-ahead depth
#   - subgame-perfection invariants
#
# BackwardInduction (solvers/forward/backward_induction.jl) is the
# operationalization of this chapter. This file owns the *types* and
# *invariants*; the solver imports from here.

"""
    InformationSet

Groups states that a given player cannot distinguish between when choosing
an action. Essential for Chapter 2's "what the rival knows" reasoning and
for Chapter 13's Bayesian extensions.
"""
struct InformationSet
    id::Symbol
    player_id::Symbol
    indistinguishable_states::Vector{UInt64}  # state_key hashes
end

"""
    SequentialInvariants

Checked whenever a world is constructed with `structure = Sequential(order)`.
A world that violates these invariants cannot produce a valid SPE and the
solver will refuse to run.
"""
struct SequentialInvariants
    order_covers_all_movers::Bool
    information_sets_well_formed::Bool
    no_cycles_in_game_tree::Bool
end

"""
    validate_sequential(world) -> SequentialInvariants

Phase 1 skeleton — tasks.md 1.4.
"""
function validate_sequential(world::StrategicWorld)::SequentialInvariants
    # TODO: implement.
    SequentialInvariants(true, true, true)
end

"""
    look_ahead_depth(world) -> Int

Maximum depth the backward-induction solver will need to traverse.
Used for memoization budget and for "What would a boundedly-rational
player see at depth k?" queries (Chapter 7 extension).
"""
function look_ahead_depth(world::StrategicWorld)::Int
    error("Phase 1: look_ahead_depth not yet implemented")
end
