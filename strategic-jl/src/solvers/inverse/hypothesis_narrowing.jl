# Hypothesis narrowing is a *workflow*, not a single call.
# A user adds observations, prunes hypotheses, requests rulings, and
# inspects provenance — each step records a ProvenanceNode.

mutable struct NarrowingSession
    hypotheses::Vector{HypothesisWorld}
    observations::Vector{ObservedPlay}
    provenance::Vector{ProvenanceNode}
end

NarrowingSession() = NarrowingSession(HypothesisWorld[], ObservedPlay[], ProvenanceNode[])

NarrowingSession(hypotheses::Vector{<:StrategicWorld}) =
    NarrowingSession([HypothesisWorld(w, 1.0 / length(hypotheses)) for w in hypotheses],
                     ObservedPlay[], ProvenanceNode[])

"""
    add_observation!(session, obs)

Add an observation and re-run Bayesian inference over all non-pruned hypotheses.
Appends a provenance node recording the update.
"""
function add_observation!(s::NarrowingSession, obs::ObservedPlay)
    push!(s.observations, obs)
    active_idx = findall(h -> h.posterior > 0.0, s.hypotheses)
    if !isempty(active_idx)
        worlds = [s.hypotheses[i].world for i in active_idx]
        dist = infer_from_observations(s.observations, worlds)
        for (j, i) in enumerate(active_idx)
            h = s.hypotheses[i]
            new_post = dist.hypotheses[j].posterior
            new_prov = dist.hypotheses[j].provenance
            s.hypotheses[i] = HypothesisWorld(h.id, h.world, h.prior, new_post,
                                               vcat(h.provenance, new_prov))
        end
    end
    push!(s.provenance, ProvenanceNode(
        "observation_added", "Chapter 4",
        "Observed $(obs.player_id) → $(obs.action_taken) (confidence=$(obs.confidence))";
        parent_id = isempty(s.provenance) ? "" : something(s.provenance[end].id, "")
    ))
    s
end

"""
    prune!(session, hypothesis_id, reason)

Set a hypothesis posterior to 0 (ruled out). Records provenance.
"""
function prune!(s::NarrowingSession, hypothesis_id::String, reason::String)
    idx = findfirst(h -> h.id == hypothesis_id, s.hypotheses)
    idx === nothing && return s
    h = s.hypotheses[idx]
    node = ProvenanceNode(
        "ruled_out_hypothesis", "Chapter 4",
        reason;
        parent_id = isempty(h.provenance) ? "" : something(h.provenance[end].id, "")
    )
    s.hypotheses[idx] = HypothesisWorld(h.id, h.world, h.prior, 0.0, vcat(h.provenance, [node]))
    push!(s.provenance, node)
    s
end

"""
    rule_in!(session, hypothesis_id, reason)

Boost a hypothesis by doubling its posterior (then renormalise). Records provenance.
"""
function rule_in!(s::NarrowingSession, hypothesis_id::String, reason::String)
    idx = findfirst(h -> h.id == hypothesis_id, s.hypotheses)
    idx === nothing && return s
    h = s.hypotheses[idx]
    node = ProvenanceNode(
        "inferred_hypothesis", "Chapter 4",
        reason;
        parent_id = isempty(h.provenance) ? "" : something(h.provenance[end].id, "")
    )
    boosted = HypothesisWorld(h.id, h.world, h.prior, h.posterior * 2.0, vcat(h.provenance, [node]))
    s.hypotheses[idx] = boosted
    # Renormalise
    total = sum(h.posterior for h in s.hypotheses)
    if total > 0
        s.hypotheses = [HypothesisWorld(h.id, h.world, h.prior, h.posterior / total, h.provenance)
                        for h in s.hypotheses]
    end
    push!(s.provenance, node)
    s
end

"""
    current_ranking(session) -> Vector{HypothesisWorld}

Return hypotheses sorted by posterior (highest first), with provenance intact.
"""
function current_ranking(s::NarrowingSession)::Vector{HypothesisWorld}
    sort(s.hypotheses; by = h -> h.posterior, rev = true)
end
