# Chapter 13: Case Studies — Bayesian beliefs, incomplete information.

struct BayesianBeliefTrait <: GameTrait
    player_id::Symbol
    about::Symbol                    # Which opponent / hidden variable the belief concerns.
    prior::Distribution              # From Distributions.jl
    update_rule::Symbol              # :bayes, :quantal_response, :fictitious_play
end

# Phase 2+ stub.
