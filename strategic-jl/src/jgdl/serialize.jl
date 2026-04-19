"""
    to_jgdl(world) -> String

Serialize a StrategicWorld to a JGDL JSON string, embedding the SHA-256
content hash in world.id.

Phase 1 skeleton — tasks.md 1.5.
"""
function to_jgdl(world::StrategicWorld)::String
    error("Phase 1: to_jgdl not yet implemented (tasks.md 1.5)")
end

"""
    world_id(world) -> String

Content-addressable SHA-256 hash of the world's canonical JGDL serialization,
excluding the id field itself.
"""
function world_id(world::StrategicWorld)::String
    error("Phase 1: world_id not yet implemented (tasks.md 1.5)")
end
