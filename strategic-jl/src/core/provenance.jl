struct ProvenanceNode
    id::Union{String, Nothing}              # Optional UUID v4
    operation::String
    trait_type::Union{String, Nothing}      # Populated iff operation == "applied_trait"
    chapter_ref::String
    theoretical_origin::Union{String, Nothing}
    rationale::String
    parent_id::String
    timestamp::DateTime
    author::Symbol                          # :user, :llm, :system
end

"""
    ProvenanceNode(operation, chapter_ref, rationale; kwargs...)

Construct a provenance node. Generates a UUID v4 by default so downstream
layers (LLM explanations, web composer) can reference the node stably;
pass `id=nothing` to opt out.
"""
function ProvenanceNode(op::String, chapter::String, rationale::String;
        id::Union{String, Nothing} = string(uuid4()),
        trait_type::Union{String, Nothing} = nothing,
        parent_id::String = "",
        theoretical_origin::Union{String, Nothing} = nothing,
        author::Symbol = :user)
    ProvenanceNode(id, op, trait_type, chapter, theoretical_origin,
        rationale, parent_id, now(), author)
end

function append_provenance!(world::StrategicWorld, node::ProvenanceNode)
    push!(world.provenance, node)
    world
end
