# Iterated elimination of dominated strategies (Chapter 3 solver).
# Runs before BackwardInduction to shrink the tree; also serves as a
# standalone analysis for "what survives rationalizability?"

"""
    solve(world, ::IteratedDominance) -> RationalizableSet

Phase 1 skeleton — tasks.md 1.4.

Algorithm:
  1. For each player, compute strictly-dominated actions given opponents'
     full action sets.
  2. Remove those actions; repeat until no further eliminations possible.
  3. Return RationalizableSet per player with full elimination trace.

Every elimination step appends a ProvenanceNode citing Chapter 3 and the
specific dominance relation used.
"""
function solve(world::StrategicWorld, method::IteratedDominance)
    error("Phase 1: iterated dominance solver not yet implemented (tasks.md 1.4)")
end

"""
    dominates(world, player, a, b, opponents_strategies; strict=true)

Does action `a` dominate action `b` for `player` given the opponents'
remaining strategy space? Used by both the dominance solver and the
inverse direction (to test whether observed behavior is rationalizable
under a hypothesized payoff structure).
"""
function dominates(
    world::StrategicWorld,
    player::Player,
    a::Symbol,
    b::Symbol,
    opponents::Vector;
    strict::Bool = true
)::Bool
    error("Phase 1: dominates() not yet implemented")
end
