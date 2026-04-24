struct ObservedPlay
    context::State
    action_taken::Symbol
    player_id::Symbol
    timestamp::DateTime
    confidence::Float64
end

struct HypothesisWorld
    id::String                          # Stable identifier for prune!/rule_in!
    world::StrategicWorld
    prior::Float64
    posterior::Float64
    provenance::Vector{ProvenanceNode}
end

function HypothesisWorld(world::StrategicWorld, prior::Float64)
    HypothesisWorld(string(uuid4()), world, prior, prior, ProvenanceNode[])
end

struct PosteriorWorldDistribution
    hypotheses::Vector{HypothesisWorld}
end

# Ranked accessor — highest posterior first
function ranked(d::PosteriorWorldDistribution)
    sort(d.hypotheses; by = h -> h.posterior, rev = true)
end

"""
    infer_from_observations(observations, hypotheses) -> PosteriorWorldDistribution

Bayesian posterior update over a hypothesis space of StrategicWorlds.

Likelihood model: quantal response — for each observation, the likelihood that
a rational player (with noise λ) chose the observed action given the payoff matrix.
Higher payoff actions are exponentially more likely (softmax over available actions).

Returns a ranked PosteriorWorldDistribution. Every hypothesis carries provenance
explaining why its posterior moved.
"""
function infer_from_observations(
        observations::Vector{ObservedPlay},
        hypotheses::Vector{<:StrategicWorld};
        lambda::Float64 = 1.0   # Quantal response rationality parameter
)::PosteriorWorldDistribution
    n = length(hypotheses)
    n == 0 && return PosteriorWorldDistribution(HypothesisWorld[])

    # Uniform prior if not specified
    prior = 1.0 / n
    hw = [HypothesisWorld(w, prior) for w in hypotheses]

    for obs in observations
        log_likelihoods = [_log_likelihood(h.world, obs, lambda) for h in hw]
        # Bayesian update: posterior ∝ prior × likelihood
        log_posteriors = [log(h.posterior) + ll for (h, ll) in zip(hw, log_likelihoods)]
        # Normalise in log space
        log_Z = _logsumexp(log_posteriors)
        for (i, h) in enumerate(hw)
            new_post = exp(log_posteriors[i] - log_Z)
            node = ProvenanceNode(
                "bayesian_update", "Chapter 7",
                "Observed $(obs.player_id) played $(obs.action_taken); " *
                "posterior $(round(h.posterior; digits=4)) → $(round(new_post; digits=4))";
                parent_id = isempty(h.provenance) ? "" :
                            something(h.provenance[end].id, "")
            )
            hw[i] = HypothesisWorld(
                h.id, h.world, h.prior, new_post, vcat(h.provenance, [node]))
        end
    end

    PosteriorWorldDistribution(hw)
end

# Quantal response log-likelihood: log P(action | world, player, lambda)
function _log_likelihood(world::StrategicWorld, obs::ObservedPlay, lambda::Float64)::Float64
    matrix = get(get(world.metadata, "payoffs", Dict()), "matrix", Dict())
    actions = get(world.metadata, "actions", Action[])
    player_actions = [a for a in actions if a.player_id == obs.player_id]
    isempty(player_actions) && return 0.0

    # Get payoff for each action (marginalise over opponent actions uniformly)
    opp_actions = [a for a in actions if a.player_id != obs.player_id]
    function expected_payoff(aid::Symbol)
        if isempty(opp_actions)
            pf = _lookup_payoff_dict(matrix, string(aid))
            pf === nothing && return 0.0
            return get(pf, obs.player_id, get(pf, string(obs.player_id), 0.0))
        end
        total = 0.0
        count = 0
        for oa in opp_actions
            key = "$(aid).$(oa.id)"
            pf = _lookup_payoff_dict(matrix, key)
            pf === nothing && continue
            total += get(pf, obs.player_id, get(pf, string(obs.player_id), 0.0))
            count += 1
        end
        count == 0 ? 0.0 : total / count
    end

    payoffs = [expected_payoff(a.id) for a in player_actions]
    # Softmax
    scaled = lambda .* payoffs
    log_Z = _logsumexp(scaled)
    obs_idx = findfirst(a -> a.id == obs.action_taken, player_actions)
    obs_idx === nothing && return log(1.0 / length(player_actions))  # uniform fallback
    scaled[obs_idx] - log_Z
end

function _logsumexp(xs::Vector{Float64})::Float64
    isempty(xs) && return -Inf
    m = maximum(xs)
    m + log(sum(exp.(xs .- m)))
end
