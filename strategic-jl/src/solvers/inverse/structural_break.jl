"""
    StructuralBreak

Result of detect_structural_break. If detected, break_round is the first round
where the log-likelihood ratio exceeds the threshold, and objective_function_changed
is set to true.
"""
struct StructuralBreak
    detected::Bool
    break_round::Union{Int, Nothing}
    objective_function_changed::Bool
    log_likelihood_ratio::Float64
    provenance::Vector{ProvenanceNode}
end

"""
    detect_structural_break(observations; threshold, lambda) -> StructuralBreak

Scan a sequence of ObservedPlay for a point where behaviour becomes inconsistent
with the earlier pattern. Uses a cumulative log-likelihood ratio test:

  LLR(t) = Σ_{i≤t} log P(obs_i | early_model) - Σ_{i≤t} log P(obs_i | late_model)

When |LLR| exceeds `threshold`, a structural break is flagged at round t.
The early model is estimated from the first half of observations; the late model
from the second half.

Cites Chapter 4 (repeated games) — a break suggests the objective function changed.
"""
function detect_structural_break(
    observations::Vector{ObservedPlay};
    threshold::Float64 = 2.0,
    lambda::Float64 = 1.0
)::StructuralBreak
    n = length(observations)
    provenance = ProvenanceNode[]
    n < 4 && return StructuralBreak(false, nothing, false, 0.0, provenance)

    mid = n ÷ 2
    early = observations[1:mid]
    late  = observations[mid+1:end]

    # Action frequency models: P(action | player) estimated from each half
    early_freq = _action_frequencies(early)
    late_freq  = _action_frequencies(late)

    # Scan for break point: find t where cumulative LLR exceeds threshold
    max_llr = 0.0
    break_round = nothing

    for t in 2:(n-1)
        llr = 0.0
        for (i, obs) in enumerate(observations[1:t])
            p_early = get(get(early_freq, obs.player_id, Dict()), obs.action_taken, 1e-6)
            p_late  = get(get(late_freq,  obs.player_id, Dict()), obs.action_taken, 1e-6)
            llr += log(p_early) - log(p_late)
        end
        if abs(llr) > threshold && abs(llr) > abs(max_llr)
            max_llr = llr
            break_round = t + 1  # break starts at the next round
        end
    end

    detected = break_round !== nothing
    if detected
        push!(provenance, ProvenanceNode(
            "detected_surprise", "Chapter 4",
            "Structural break detected at round $(break_round). " *
            "Log-likelihood ratio $(round(max_llr; digits=3)) exceeds threshold $(threshold). " *
            "Hypothesis: objective_function_changed.";
            parent_id = ""
        ))
    else
        push!(provenance, ProvenanceNode(
            "no_structural_break", "Chapter 4",
            "No structural break detected (max LLR=$(round(max_llr; digits=3)), threshold=$(threshold)).";
            parent_id = ""
        ))
    end

    StructuralBreak(detected, break_round, detected, max_llr, provenance)
end

function _action_frequencies(obs::Vector{ObservedPlay})::Dict{Symbol, Dict{Symbol, Float64}}
    counts = Dict{Symbol, Dict{Symbol, Int}}()
    for o in obs
        player_counts = get!(counts, o.player_id, Dict{Symbol, Int}())
        player_counts[o.action_taken] = get(player_counts, o.action_taken, 0) + 1
    end
    # Normalise to probabilities
    Dict(pid => begin
        total = sum(values(ac))
        Dict(aid => c / total for (aid, c) in ac)
    end for (pid, ac) in counts)
end
