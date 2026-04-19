# Chapter 1: Ten Tales of Strategy
#
# Not a mechanic. A *reference corpus* — the canonical examples every
# primitive must be able to model. If a Tale cannot round-trip through
# JGDL and be solved to the expected outcome, the primitives are wrong.
#
# The Tales double as:
#   - onboarding examples (smallest possible demos of each concept)
#   - compliance-suite seeds (ground truth for correctness)
#   - pedagogical provenance roots (every derived world can trace its
#     lineage to a Tale and a chapter)

struct Tale
    id::Symbol
    title::String
    summary::String
    concepts::Vector{String}       # Concept tags: "commitment", "coordination", etc.
    chapter_refs::Vector{String}   # Primary chapters this tale illustrates.
    jgdl_path::String              # Relative to jgdl/examples/tales/
end

"""
    TALES

Registry of the Ten Tales. Populated during Phase 1 as each JGDL
fixture is authored. Access via `tale(:chicken)` etc.
"""
const TALES = Dict{Symbol, Tale}(
    :hot_hand => Tale(
        :hot_hand,
        "The Hot Hand",
        "When a rival's previous success alters your anticipation of their next move.",
        ["anticipation", "sequential_reasoning"],
        ["Chapter 1", "Chapter 2"],
        "tales/hot_hand.json",
    ),
    :elevator_dilemma => Tale(
        :elevator_dilemma,
        "The Elevator Dilemma",
        "Coordination without communication via salient focal points.",
        ["coordination", "focal_points"],
        ["Chapter 1", "Chapter 9"],
        "tales/elevator_dilemma.json",
    ),
    :chicken => Tale(
        :chicken,
        "Chicken",
        "Two drivers on a collision course; swerving loses face but crashing is worse.",
        ["brinkmanship", "commitment", "mixed_strategy"],
        ["Chapter 1", "Chapter 5", "Chapter 8"],
        "tales/chicken.json",
    ),
    :dollar_auction => Tale(
        :dollar_auction,
        "The Dollar Auction",
        "Escalating commitment under sunk-cost pressure.",
        ["escalation", "commitment"],
        ["Chapter 1", "Chapter 6"],
        "tales/dollar_auction.json",
    ),
    :concert_problem => Tale(
        :concert_problem,
        "The Concert Problem",
        "When to buy tickets given beliefs about others' demand.",
        ["bayesian_reasoning", "timing"],
        ["Chapter 1", "Chapter 13"],
        "tales/concert_problem.json",
    ),
    # Remaining five tales populated during Phase 1 as JGDL fixtures land.
)

"""
    tale(id) -> Tale

Look up a canonical Tale. Raises if the Tale has not yet been authored.
"""
function tale(id::Symbol)::Tale
    haskey(TALES, id) || error("Tale :$id not yet authored. See jgdl/examples/tales/.")
    TALES[id]
end

"""
    tales_covering(concept) -> Vector{Tale}

Return all Tales tagged with a concept. Useful for pedagogical navigation
and for mapping inverse-inference hypotheses back to canonical exemplars.
"""
tales_covering(concept::AbstractString) = [t for t in values(TALES) if concept in t.concepts]
