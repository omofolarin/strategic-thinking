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
        "tales/hot_hand.json"
    ),
    :elevator_dilemma => Tale(
        :elevator_dilemma,
        "The Elevator Dilemma",
        "Coordination without communication via salient focal points.",
        ["coordination", "focal_points"],
        ["Chapter 1", "Chapter 9"],
        "tales/elevator_dilemma.json"
    ),
    :chicken => Tale(
        :chicken,
        "Chicken",
        "Two drivers on a collision course; swerving loses face but crashing is worse.",
        ["brinkmanship", "commitment", "mixed_strategy"],
        ["Chapter 1", "Chapter 5", "Chapter 8"],
        "tales/chicken.json"
    ),
    :dollar_auction => Tale(
        :dollar_auction,
        "The Dollar Auction",
        "Escalating commitment under sunk-cost pressure.",
        ["escalation", "commitment"],
        ["Chapter 1", "Chapter 6"],
        "tales/dollar_auction.json"
    ),
    :concert_problem => Tale(
        :concert_problem,
        "The Concert Problem",
        "When to buy tickets given beliefs about others' demand.",
        ["bayesian_reasoning", "timing"],
        ["Chapter 1", "Chapter 13"],
        "tales/concert_problem.json"
    ),
    # Remaining five tales — Phase 2 JGDL fixtures.
    :price_war => Tale(
        :price_war,
        "The Price War",
        "Two firms cut prices to capture market share, ending in mutual losses. Illustrates the prisoner's dilemma in a repeated market context.",
        ["repeated_game", "commitment", "escalation"],
        ["Chapter 1", "Chapter 4", "Chapter 6"],
        "tales/price_war.json"
    ),
    :arms_race => Tale(
        :arms_race,
        "The Arms Race",
        "Two nations each prefer to arm if the other arms, and to disarm if the other disarms — but mutual arming is the dominant equilibrium.",
        ["dominance", "coordination", "commitment"],
        ["Chapter 1", "Chapter 3", "Chapter 5"],
        "tales/arms_race.json"
    ),
    :salary_negotiation => Tale(
        :salary_negotiation,
        "The Salary Negotiation",
        "A worker and firm bargain over wages. Outside options and commitment determine the split.",
        ["bargaining", "commitment", "outside_option"],
        ["Chapter 1", "Chapter 11"],
        "tales/salary_negotiation.json"
    ),
    :tournament_race => Tale(
        :tournament_race,
        "The Tournament Race",
        "Contestants exert effort for a winner-take-all prize. Relative performance, not absolute, determines reward.",
        ["tournament", "relative_payoff", "effort"],
        ["Chapter 1", "Chapter 12"],
        "tales/tournament_race.json"
    ),
    :sealed_bid => Tale(
        :sealed_bid,
        "The Sealed-Bid Auction",
        "Bidders submit private bids for an object. Optimal strategy depends on beliefs about rivals' valuations.",
        ["bayesian_reasoning", "private_information", "auction"],
        ["Chapter 1", "Chapter 13"],
        "tales/sealed_bid.json"
    )
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
function tales_covering(concept::AbstractString)
    [t for t in values(TALES) if concept in t.concepts]
end
