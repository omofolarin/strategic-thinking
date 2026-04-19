# Hypothesis narrowing is a *workflow*, not a single call.
# A user adds observations, prunes hypotheses, requests rulings, and
# inspects provenance — each step records a ProvenanceNode.

mutable struct NarrowingSession
    hypotheses::Vector{HypothesisWorld}
    observations::Vector{ObservedPlay}
    provenance::Vector{ProvenanceNode}
end

NarrowingSession() = NarrowingSession(HypothesisWorld[], ObservedPlay[], ProvenanceNode[])

# Phase 2 skeleton — tasks.md 2.4.
function add_observation!(s::NarrowingSession, obs::ObservedPlay) end
function prune!(s::NarrowingSession, hypothesis_id::String, reason::String) end
function rule_in!(s::NarrowingSession, hypothesis_id::String, reason::String) end
function current_ranking(s::NarrowingSession) end
