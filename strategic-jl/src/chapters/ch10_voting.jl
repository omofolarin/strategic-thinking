# Chapter 10: The Strategy of Voting — voting rules as game structure.

struct VotingRuleTrait <: GameTrait
    rule::Symbol  # :plurality, :majority, :borda, :condorcet, :approval
    members::Int
end

register_trait!(VotingRuleTrait, Set([:aggregate, :transition]))

# Phase 2+ stub.
