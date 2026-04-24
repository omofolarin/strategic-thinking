"""
    validate_jgdl(json) -> Vector{ValidationError}

Pure function: accepts raw JSON (string or dict), returns a list of
validation errors. Runs two passes:
  1. JSON Schema structural validation (v1.1.0)
  2. Semantic cross-reference: payoff keys must reference declared action IDs
"""
struct ValidationError
    path::String         # JSON-pointer style
    message::String
end

const _SCHEMA_PATH = joinpath(@__DIR__, "..", "..", "..", "jgdl", "schema", "v1.1.0.schema.json")

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
    # Pass 1: schema
    result = JSONSchema.validate(doc, _schema())
    result === nothing || begin
        path = isempty(result.path) ? "/" : join(result.path, "/")
        return [ValidationError(path, result.reason)]
    end

    # Pass 2: semantic cross-reference
    _validate_payoff_keys(doc)
end

"""
    _validate_payoff_keys(doc) -> Vector{ValidationError}

Cross-check every key in world.payoffs.matrix against the declared action IDs.
Each key segment must either be a known action ID or the wildcard `*`.
"""
function _validate_payoff_keys(doc::AbstractDict)::Vector{ValidationError}
    errors = ValidationError[]
    world = get(doc, "world", nothing)
    world === nothing && return errors

    actions = get(world, "actions", [])
    known_ids = Set(string(get(a, "id", "")) for a in actions)
    isempty(known_ids) && return errors

    payoffs = get(world, "payoffs", nothing)
    payoffs === nothing && return errors
    matrix = get(payoffs, "matrix", nothing)
    matrix === nothing && return errors

    for key in keys(matrix)
        segments = split(key, ".")
        for seg in segments
            seg == "*" && continue
            if seg ∉ known_ids
                push!(errors, ValidationError(
                    "/world/payoffs/matrix/$key",
                    "Payoff key segment '$seg' does not match any declared action id. " *
                    "Known ids: $(join(sort(collect(known_ids)), ", "))"
                ))
            end
        end
    end
    errors
end
