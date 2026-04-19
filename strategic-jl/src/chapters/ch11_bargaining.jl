# Chapter 11: Bargaining — Rubinstein alternating offers, patience as power.

struct BargainingProtocolTrait <: GameTrait
    players_order::Vector{Symbol}
    pie::Float64
    discount_factor::Float64
end

# Phase 2+ stub.
