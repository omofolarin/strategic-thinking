# Open-world extension: there are always players and actions we haven't observed.

struct ShadowPlayer <: PlayerStrategy
    id::Symbol
    surprise_weight::Float64
end

struct OpenWorldGame{G<:AbstractGame} <: AbstractGame
    inner::G
    emergence_rate::Float64
    shadow::ShadowPlayer
end

# Phase 3 stub. Wiring comes online with tasks.md 3.1.
