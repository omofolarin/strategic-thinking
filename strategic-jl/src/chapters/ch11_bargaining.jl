# Chapter 11: Bargaining — Rubinstein alternating offers, patience as power.

struct BargainingProtocolTrait <: GameTrait
    players_order::Vector{Symbol}
    pie::Float64
    discount_factor::Float64
end

register_trait!(BargainingProtocolTrait, Set([:transition, :available_actions]))

# Phase 2+ stub.
