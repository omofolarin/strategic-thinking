# Lazy game tree: generator + memoization, never materializes the whole tree.
# Serialization (JGDL) stores the rules, not the enumeration.

struct LazyGameTree
    root_state::State
    transition::Function       # (State, Action) -> State
    is_terminal::Function      # State -> Bool
    payoff_fn::Function        # State -> Dict{Symbol, Float64}
    available_actions_fn::Function  # (State, Player) -> Vector{Action}
end

# Helpers to fold memoization across any solver walking the tree.
mutable struct ValueCache
    store::Dict{UInt64, Dict{Symbol, Float64}}
end
ValueCache() = ValueCache(Dict{UInt64, Dict{Symbol, Float64}}())

state_key(s::State) = hash((s.variables, s.history, s.current_player, s.round))
