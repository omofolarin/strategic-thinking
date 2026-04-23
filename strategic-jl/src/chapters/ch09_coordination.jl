# Chapter 9: Cooperation and Coordination — Schelling focal points.

struct CoordinationDeviceTrait <: GameTrait
    focal_action::Symbol
    salience::Float64  # Weight placed on focal equilibrium during selection.
end

register_trait!(CoordinationDeviceTrait, Set([:select_equilibrium]))

# Phase 2 stub.
