"""
    validate_jgdl(json) -> Vector{ValidationError}

Pure function: accepts raw JSON (string or dict), returns a list of
validation errors against v1.0.0 schema. Empty list means valid.

Phase 0 — loaded from jgdl/schema/v1.0.0.schema.json.
"""
struct ValidationError
    path::String         # JSON-pointer style
    message::String
end

function validate_jgdl(json)::Vector{ValidationError}
    error("Phase 0: schema validator not yet implemented (tasks.md 0.1)")
end
