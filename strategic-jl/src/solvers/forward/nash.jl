struct NashEquilibrium <: SolverMethod end
struct MixedStrategy <: SolverMethod end

# Phase 2 stub.
function solve(world::StrategicWorld, ::NashEquilibrium)
    error("Phase 2: Nash equilibrium solver not yet implemented")
end
