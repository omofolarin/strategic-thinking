# Player discovery: infer new players from observations not attributable
# to known players. Parametric (K clusters) first; Dirichlet Process in Phase 3+.

struct DiscoveredPlayer
    id::Symbol
    supporting_observations::Vector{ObservedPlay}
    provenance::Vector{ProvenanceNode}
end

"""
    discover_players(world, observations; k) -> Vector{DiscoveredPlayer}

Find observations whose player_id is not in the world's known player set.
Each unknown player_id becomes a DiscoveredPlayer with a provenance node
citing the observations that birthed it.

k is reserved for future Dirichlet Process clustering (Phase 3+).
"""
function discover_players(
        world::StrategicWorld,
        observations::Vector{ObservedPlay};
        k::Int = 1
)::Vector{DiscoveredPlayer}
    actions = get(world.metadata, "actions", Action[])
    known_ids = Set(a.player_id for a in actions)

    unknown = Dict{Symbol, Vector{ObservedPlay}}()
    for obs in observations
        obs.player_id ∈ known_ids && continue
        push!(get!(unknown, obs.player_id, ObservedPlay[]), obs)
    end

    [DiscoveredPlayer(
         pid,
         obs_list,
         [ProvenanceNode(
             "discovered_player", "Chapter 1",
             "Player :$pid not in known player set. " *
             "Inferred from $(length(obs_list)) observation(s): " *
             join([string(o.action_taken) for o in obs_list], ", ");
             parent_id = world.id
         )]
     ) for (pid, obs_list) in unknown]
end
