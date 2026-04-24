abstract type AbstractGame end
abstract type GameTrait end
abstract type SolverMethod end
abstract type PlayerStrategy end

struct PlayerParameters
    rationality::Float64
    discount_rate::Float64
    risk_aversion::Float64
    learning_rate::Float64
end

struct Player
    id::Symbol
    name::String
    strategy::PlayerStrategy
    parameters::PlayerParameters
end

struct Action
    id::Symbol
    name::String
    player_id::Symbol
end

struct State
    variables::Dict{Symbol, Any}
    history::Vector{Tuple{Symbol, Symbol}}  # (player_id, action_id)
    current_player::Union{Symbol, Nothing}
    round::Int
end

# StrategicWorld — forward declaration filled in by later includes
mutable struct StrategicWorld{G <: AbstractGame}
    id::String
    game::G
    traits::Vector{GameTrait}
    provenance::Vector  # Vector{ProvenanceNode}, forward reference
    metadata::Dict{String, Any}
end

# Solution carries a required provenance chain — enforced at construction.
struct Solution
    equilibrium_path::Vector{Action}
    payoffs::Dict{Symbol, Float64}
    provenance_chain::Vector  # Vector{ProvenanceNode}

    function Solution(path, payoffs, chain)
        isempty(chain) && error("Solution requires non-empty provenance_chain")
        new(path, payoffs, chain)
    end
end
