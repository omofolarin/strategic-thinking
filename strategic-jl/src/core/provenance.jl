struct ProvenanceNode
    operation::String
    chapter_ref::String
    theoretical_origin::Union{String, Nothing}
    rationale::String
    parent_id::String
    timestamp::DateTime
    author::Symbol  # :user, :llm, :system
end

function ProvenanceNode(op::String, chapter::String, rationale::String;
                        parent_id::String = "",
                        theoretical_origin = nothing,
                        author::Symbol = :user)
    ProvenanceNode(op, chapter, theoretical_origin, rationale,
                   parent_id, now(), author)
end

function append_provenance!(world::StrategicWorld, node::ProvenanceNode)
    push!(world.provenance, node)
    world
end
