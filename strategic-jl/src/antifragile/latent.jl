# Phase 3.4 — minimal latent-confounder flagging.
#
# When two players' action choices correlate across rounds more than the
# game's structure would predict, a latent common cause is the simplest
# explanation. tasks.md 3.4 specifies PC algorithm + tetrad-based flagging;
# this implementation is a bounded v1: pair-wise action-alignment rate over
# a window of observations, guarded by the absence of an explicit
# coordination trait. Full PC + tetrad is deferred.

"""
    LatentConfounderHypothesis

A flagged pair of players whose action-alignment rate exceeded `threshold`
with no game-structural explanation. Downstream layers read
`provenance_chain` to render the hypothesis.
"""
struct LatentConfounderHypothesis
    players::Tuple{Symbol, Symbol}
    alignment_rate::Float64
    rounds_considered::Int
    provenance::Vector{ProvenanceNode}
end

"""
    detect_latent_confounder(world, observations; threshold=0.8)
      -> Vector{LatentConfounderHypothesis}

Group observations by round; for each pair of players compute the fraction
of rounds where both chose the "same" action — matched by the action name
stripped of any `_<player-suffix>` disambiguator so `cooperate_1` /
`cooperate_2` count as the same underlying choice.

If the rate exceeds `threshold` and the world contains no
`CoordinationDeviceTrait` covering the pair, emit a hypothesis citing the
chapter on latent reasoning.
"""
function detect_latent_confounder(
    world::StrategicWorld,
    observations::Vector{ObservedPlay};
    threshold::Float64 = 0.8,
    min_rounds::Int = 3
)::Vector{LatentConfounderHypothesis}
    rounds = _observations_by_round(observations)
    length(rounds) < min_rounds && return LatentConfounderHypothesis[]

    has_coord = any(t -> t isa CoordinationDeviceTrait, world.traits)
    results = LatentConfounderHypothesis[]
    # Every unordered player pair appearing in observations.
    pids = unique(o.player_id for o in observations)
    for i in 1:length(pids), j in (i+1):length(pids)
        pa, pb = pids[i], pids[j]
        matches = 0
        considered = 0
        for (_, obs_round) in rounds
            ra = findfirst(o -> o.player_id == pa, obs_round)
            rb = findfirst(o -> o.player_id == pb, obs_round)
            (ra === nothing || rb === nothing) && continue
            considered += 1
            _action_root(obs_round[ra].action_taken) ==
                _action_root(obs_round[rb].action_taken) &&
                (matches += 1)
        end
        considered < min_rounds && continue
        rate = matches / considered
        rate < threshold && continue

        rationale = "Players :$pa and :$pb aligned on $(matches)/$(considered) " *
                    "rounds ($(round(rate * 100; digits=1))% match). " *
                    (has_coord ? "CoordinationDevice trait present — confounder " *
                                  "ranked below coordination-device explanation." :
                                  "No coordination device in world; latent common " *
                                  "cause is the simplest explanation for the " *
                                  "correlation.")
        prov = [ProvenanceNode(
            "flagged_latent_confounder", "Chapter 3",
            rationale;
            parent_id = world.id,
            theoretical_origin = "Spirtes, Glymour & Scheines, Causation, Prediction, and Search (1993), Ch 5–6"
        )]
        push!(results, LatentConfounderHypothesis((pa, pb), rate, considered, prov))
    end
    results
end

function _observations_by_round(obs::Vector{ObservedPlay})
    buckets = Dict{Int, Vector{ObservedPlay}}()
    for o in obs
        push!(get!(buckets, o.context.round, ObservedPlay[]), o)
    end
    sort(collect(buckets); by = p -> p.first)
end

# Strip a trailing `_<n>` or `_<short>` disambiguator so action ids that
# differ only in their player suffix ("cooperate_1" vs "cooperate_2")
# compare equal for the purpose of alignment scoring.
function _action_root(aid::Symbol)::Symbol
    s = string(aid)
    m = match(r"^(.*)_[a-z0-9]{1,3}$", s)
    m === nothing ? aid : Symbol(m[1])
end
