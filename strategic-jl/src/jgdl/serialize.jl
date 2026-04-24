"""
    to_jgdl(world) -> String

Serialize a StrategicWorld to a JGDL JSON string, embedding the SHA-256
content hash in world.id.
"""
function to_jgdl(world::StrategicWorld)::String
    doc = _world_to_dict(world)
    # Compute hash over doc with id = placeholder, then embed
    doc["world"]["id"] = "sha256:" * _hash_world(doc)
    JSON.json(doc)
end

"""
    world_id(world) -> String

Content-addressable SHA-256 hash of the world's canonical JGDL serialization,
excluding the id field itself.
"""
function world_id(world::StrategicWorld)::String
    doc = _world_to_dict(world)
    "sha256:" * _hash_world(doc)
end

function _hash_world(doc::Dict)::String
    # Exclude the id field from hashing
    world_copy = copy(doc["world"])
    delete!(world_copy, "id")
    canonical = JSON.json(sort(collect(world_copy), by = first))
    bytes2hex(SHA.sha256(canonical))
end

function _world_to_dict(world::StrategicWorld)::Dict
    Dict(
        "version" => "1.0.0",
        "world" => Dict(
            "id" => world.id,
            "metadata" => world.metadata,
            "players" => get(world.metadata, "players_raw", []),
            "actions" => get(world.metadata, "actions_raw", []),
            "structure" => get(world.metadata, "structure", Dict("type" => "simultaneous")),
            "payoffs" => get(world.metadata, "payoffs", Dict("type" => "terminal_matrix")),
            "traits" => [],
            "initial_state" => get(world.metadata, "initial_state", Dict()),
            "provenance" => [_provenance_to_dict(p) for p in world.provenance]
        )
    )
end

function _provenance_to_dict(p::ProvenanceNode)::Dict
    d = Dict{String, Any}(
        "operation" => p.operation,
        "chapter_ref" => p.chapter_ref,
        "rationale" => p.rationale,
        "parent_id" => p.parent_id,
        "timestamp" => string(p.timestamp),
        "author" => string(p.author)
    )
    p.id !== nothing && (d["id"] = p.id)
    p.trait_type !== nothing && (d["trait_type"] = p.trait_type)
    p.theoretical_origin !== nothing && (d["theoretical_origin"] = p.theoretical_origin)
    d
end
