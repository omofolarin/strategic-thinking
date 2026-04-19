# Hedge portfolio: explicit bets on unknown-unknowns.

struct Hedge
    id::Symbol
    trigger::Function         # (ObservedPlay) -> Bool
    payoff::Function          # (StrategicWorld) -> Float64
    cost::Float64
    optionality_value::Float64
    chapter_ref::String
end

# Phase 3 stub — wired to SurpriseDetector in tasks.md 3.5.
