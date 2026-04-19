"""
    from_jgdl(json) -> StrategicWorld

Deserialize a JGDL JSON string (or parsed dict) into a StrategicWorld.
Validates against v1.0.0 schema and recomputes the integrity hash.

Phase 1 skeleton — tasks.md 1.5.
"""
function from_jgdl(json_str::AbstractString)::StrategicWorld
    error("Phase 1: from_jgdl not yet implemented (tasks.md 1.5)")
end
