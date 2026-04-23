"""
    from_jgdl(json_str) -> StrategicWorld

Deserialize a JGDL JSON string into a StrategicWorld.
Validates against v1.0.0 schema and recomputes the integrity hash.
"""
function from_jgdl(json_str::AbstractString)::StrategicWorld
    doc = JSON.parse(json_str)
    errors = validate_jgdl(doc)
    isempty(errors) || error("JGDL validation failed: $(errors[1].message)")
    w = doc["world"]
    provenance = [_dict_to_provenance(p) for p in get(w, "provenance", [])]
    metadata = Dict{String,Any}(
        "players"       => get(w, "players", []),
        "actions"       => get(w, "actions", []),
        "structure"     => get(w, "structure", Dict()),
        "payoffs"       => get(w, "payoffs", Dict()),
        "initial_state" => get(w, "initial_state", Dict()),
        "move_order"    => _extract_order(w),
        "actions_raw"   => get(w, "actions", []),
        "players_raw"   => get(w, "players", []),
    )
    # Merge any extra metadata fields
    for (k, v) in get(w, "metadata", Dict())
        metadata[k] = v
    end
    # Build Action list for solver use
    actions = [Action(Symbol(a["id"]), get(a, "name", a["id"]), Symbol(a["player_id"]))
               for a in get(w, "actions", [])]
    metadata["actions"] = actions
    # Parse traits from JGDL and store forbidden actions in metadata
    forbidden = Dict{Symbol, Vector{Symbol}}()  # player_id => [forbidden_action_ids]
    for t in get(w, "traits", [])
        if get(t, "type", "") == "BurnedBridge"
            params = get(t, "parameters", Dict())
            pid = Symbol(get(params, "player_id", ""))
            fid = Symbol(get(params, "forbidden_action", ""))
            push!(get!(forbidden, pid, Symbol[]), fid)
        end
    end
    if !isempty(forbidden)
        metadata["forbidden_actions"] = forbidden
        # Filter actions for solver
        metadata["actions"] = filter(a -> !(a.id in get(forbidden, a.player_id, Symbol[])), actions)
    end
    StrategicWorld(get(w, "id", ""), _NullGame(), GameTrait[], provenance, metadata)
end

function _extract_order(w::AbstractDict)    structure = get(w, "structure", Dict())
    order = get(structure, "order", nothing)
    order === nothing && return Symbol[]
    [Symbol(id) for id in order]
end

function _dict_to_provenance(d::AbstractDict)::ProvenanceNode
    ProvenanceNode(
        get(d, "id", nothing),
        d["operation"],
        get(d, "trait_type", nothing),
        d["chapter_ref"],
        get(d, "theoretical_origin", nothing),
        d["rationale"],
        d["parent_id"],
        now(),   # timestamp not round-tripped for simplicity
        Symbol(d["author"]),
    )
end

# Minimal concrete game type for deserialized worlds (no live dispatch needed)
struct _NullGame <: AbstractGame end
available_actions(::_NullGame, ::State, ::Player) = Action[]
payoff(::_NullGame, ::State) = Dict{Symbol,Float64}()
