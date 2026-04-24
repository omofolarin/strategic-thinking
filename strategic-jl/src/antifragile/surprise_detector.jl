# Surprise detector: flags observations the current world model assigned low
# probability, then ranks mutation templates as explanations.

struct WorldMutationTemplate
    name::String
    chapter_ref::String
    applies::Function    # (world, obs) -> Bool
    apply::Function      # (world, obs) -> StrategicWorld
end

struct SurpriseEvent
    timestamp::DateTime
    observation::ObservedPlay
    expected_probability::Float64
    magnitude::Float64           # -log(p)
    explanations::Vector{String} # names of applicable templates
    provenance::Vector{ProvenanceNode}
end

mutable struct SurpriseDetector
    world::StrategicWorld
    threshold::Float64           # magnitude threshold (-log p)
    history::Vector{SurpriseEvent}
    templates::Vector{WorldMutationTemplate}
end

function SurpriseDetector(world::StrategicWorld; threshold::Float64 = 2.0)
    SurpriseDetector(world, threshold, SurpriseEvent[], _default_templates())
end

"""
    detect_surprise(detector, obs) -> Union{SurpriseEvent, Nothing}

Compute the log-probability of `obs` under the current world model.
If -log(p) > threshold, record a SurpriseEvent with ranked mutation explanations
and a ProvenanceNode citing the evidence.
"""
function detect_surprise(d::SurpriseDetector, obs::ObservedPlay)::Union{
        SurpriseEvent, Nothing}
    ll = _log_likelihood(d.world, obs, 1.0)
    p = exp(ll)
    mag = -ll   # magnitude = -log(p); higher = more surprising

    mag <= d.threshold && return nothing

    applicable = [t.name for t in d.templates if t.applies(d.world, obs)]
    prov = [ProvenanceNode(
        "detected_surprise", "Chapter 1",
        "Observation $(obs.player_id)→$(obs.action_taken) has p=$(round(p; digits=4)), " *
        "magnitude=$(round(mag; digits=3)) > threshold=$(d.threshold). " *
        "Applicable mutations: $(join(applicable, ", "))";
        parent_id = ""
    )]
    event = SurpriseEvent(obs.timestamp, obs, p, mag, applicable, prov)
    push!(d.history, event)
    event
end

"""
    mutate_world(detector, template_name, obs) -> StrategicWorld

Apply the named mutation template to produce a new hypothesis world.
"""
function mutate_world(d::SurpriseDetector, template_name::String, obs::ObservedPlay)
    t = findfirst(t -> t.name == template_name, d.templates)
    t === nothing && error("Unknown mutation template: $template_name")
    d.templates[t].apply(d.world, obs)
end

function _default_templates()::Vector{WorldMutationTemplate}
    [
        WorldMutationTemplate(
            "new_player_emerged",
            "Chapter 1",
            (world, obs) -> begin
                actions = get(world.metadata, "actions", Action[])
                !any(a -> a.player_id == obs.player_id, actions)
            end,
            (world,
                obs) -> begin
                new_player = Player(obs.player_id, string(obs.player_id),
                    TitForTat(obs.player_id),
                    PlayerParameters(1.0, 0.9, 0.0, 0.0))
                meta = copy(world.metadata)
                meta["players"] = vcat(get(meta, "players", []), [new_player])
                StrategicWorld(world.id, world.game, world.traits,
                    vcat(world.provenance,
                        [ProvenanceNode(
                            "discovered_player", "Chapter 1",
                            "New player $(obs.player_id) inferred from surprise observation";
                            parent_id = world.id)]),
                    meta)
            end
        ),
        WorldMutationTemplate(
            "objective_change",
            "Chapter 4",
            (world, obs) -> true,   # always applicable as a fallback
            (world,
                obs) -> begin
                meta = copy(world.metadata)
                meta["hypothesis"] = "objective_function_changed"
                StrategicWorld(world.id, world.game, world.traits,
                    vcat(world.provenance,
                        [ProvenanceNode(
                            "inferred_hypothesis", "Chapter 4",
                            "Surprise suggests objective function changed for $(obs.player_id)";
                            parent_id = world.id)]),
                    meta)
            end
        ),
        WorldMutationTemplate(
            "collusion",
            "Chapter 6",
            (world, obs) -> length(get(world.metadata, "players", [])) >= 2,
            (world,
                obs) -> begin
                meta = copy(world.metadata)
                meta["hypothesis"] = "collusion_detected"
                StrategicWorld(world.id, world.game, world.traits,
                    vcat(world.provenance,
                        [ProvenanceNode(
                            "inferred_hypothesis", "Chapter 6",
                            "Surprise consistent with collusion among players";
                            parent_id = world.id)]),
                    meta)
            end
        )
    ]
end
