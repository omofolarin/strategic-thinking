struct BackwardInduction <: SolverMethod end

"""
    solve(world, ::BackwardInduction) -> Solution

Memoized backward induction over the lazy game tree. Every recursive call
appends to the provenance chain so the Solution can be explained.

Phase 1 skeleton — fill in during task 1.4.
"""
function solve(world::StrategicWorld, ::BackwardInduction)
    error("Phase 1: implement backward induction solver (tasks.md 1.4)")
end
