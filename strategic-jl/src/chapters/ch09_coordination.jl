# Chapter 9: Cooperation and Coordination — Schelling focal points.

struct CoordinationDeviceTrait <: GameTrait
    focal_action::Symbol
    salience::Float64  # Weight placed on focal equilibrium during selection.
end

# Phase 1 stub.
