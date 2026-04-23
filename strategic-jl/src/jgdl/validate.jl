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

const _SCHEMA_PATH = joinpath(@__DIR__, "..", "..", "..", "jgdl", "schema", "v1.0.0.schema.json")

const _JGDL_SCHEMA = Ref{Any}(nothing)

function _schema()
    if _JGDL_SCHEMA[] === nothing
        _JGDL_SCHEMA[] = JSONSchema.Schema(JSON.parsefile(_SCHEMA_PATH))
    end
    _JGDL_SCHEMA[]
end

function validate_jgdl(json_str::AbstractString)::Vector{ValidationError}
    validate_jgdl(JSON.parse(json_str))
end

function validate_jgdl(doc::AbstractDict)::Vector{ValidationError}
    result = JSONSchema.validate(doc, _schema())
    result === nothing && return ValidationError[]
    path = isempty(result.path) ? "/" : join(result.path, "/")
    [ValidationError(path, result.reason)]
end
