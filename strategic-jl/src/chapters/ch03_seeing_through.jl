# Chapter 3: Seeing Through Your Rival's Strategy
#
# Dominance analysis: rule out actions no rational player would take,
# then rule out actions that would only be played in response to those,
# and so on. Survives actions are *rationalizable*.
#
# This chapter is doubly load-bearing: it's both a forward solver
# (narrowing the strategy space before backward induction) and an inverse
# primitive ("given that they did X, X must have been rationalizable for
# them — what does that reveal about their payoffs?").

"""
    DominanceRelation

Whether `action_a` strictly / weakly dominates `action_b` for `player`
across all remaining strategies of opponents.
"""
struct DominanceRelation
    player_id::Symbol
    dominator::Symbol
    dominated::Symbol
    strict::Bool
end

"""
    RationalizableSet

The action space surviving iterated elimination of dominated strategies.
Phase 1: strict dominance only. Weak dominance + mixed-strategy dominance
land in Phase 2 alongside Nash.
"""
struct RationalizableSet
    player_id::Symbol
    surviving_actions::Vector{Symbol}
    eliminated::Vector{Tuple{Symbol, DominanceRelation}}  # (round_eliminated, reason)
end

"""
    IteratedDominance

Solver method. Applied before BackwardInduction to prune the tree, or
as a standalone "what can we conclude without full tree-walking?" check.
"""
struct IteratedDominance <: SolverMethod
    allow_weak::Bool
end
IteratedDominance() = IteratedDominance(false)

# The actual elimination routine lives in solvers/forward/dominance.jl.
# That file's dispatch on IteratedDominance provides the solve() impl.
