module Strategic

using JSON, JSONSchema, SHA, Dates, UUIDs, Graphs, Distributions

include("core/types.jl")
include("core/provenance.jl")
include("core/traits.jl")
include("core/tree.jl")

# Foundation chapters (1–4). Ch 1 is the reference corpus, Ch 2–4 own
# the substrate primitives: sequential reasoning, dominance analysis,
# and reciprocity strategies.
include("chapters/ch01_tales.jl")
include("chapters/ch02_anticipation.jl")
include("chapters/ch03_seeing_through.jl")
include("chapters/ch04_pd_resolution.jl")

# Modifier chapters (5–13). Each introduces a GameTrait composable onto
# any base game built from the foundation.
include("chapters/ch05_commitment.jl")
include("chapters/ch06_threats.jl")
include("chapters/ch07_unpredictability.jl")
include("chapters/ch08_brinkmanship.jl")
include("chapters/ch09_coordination.jl")
include("chapters/ch10_voting.jl")
include("chapters/ch11_bargaining.jl")
include("chapters/ch12_incentives.jl")
include("chapters/ch13_bayesian.jl")

include("solvers/forward/backward_induction.jl")
include("solvers/forward/dominance.jl")
include("solvers/forward/nash.jl")
include("solvers/inverse/bayesian_inference.jl")
include("solvers/inverse/hypothesis_narrowing.jl")
include("solvers/inverse/structural_break.jl")

include("antifragile/surprise_detector.jl")
include("antifragile/player_discovery.jl")
include("antifragile/hedges.jl")
include("antifragile/open_world.jl")

include("jgdl/serialize.jl")
include("jgdl/deserialize.jl")
include("jgdl/validate.jl")

include("elicitation/payoff_elicitation.jl")

export
    StrategicWorld, Player, Action, State, LazyGameTree,
    ProvenanceNode, GameTrait, WithTrait,
    # Foundation (Ch 1–4)
    Tale, TALES, tale, tales_covering,
    InformationSet, SequentialInvariants, validate_sequential, look_ahead_depth,
    DominanceRelation, RationalizableSet, IteratedDominance, dominates,
    TitForTat, GrimTrigger, Pavlov, GenerousTFT, choose_action,
    # Modifier traits (Ch 5–8)
    CommitmentTrait, CredibleThreatTrait, BurnedBridgeTrait,
    MixedStrategyTrait, BrinkmanshipTrait,
    # Solvers
    BackwardInduction, NashEquilibrium, solve, simulate,
    # JGDL
    to_jgdl, from_jgdl, world_id, validate_jgdl, ValidationError,
    # Elicitation (LLM-assisted payoff construction)
    PayoffLayerEstimate, ElicitedOutcomePayoff, ElicitedPayoffMatrix,
    to_payoff_matrix, mean_confidence, build_world_from_elicitation, elicit_layer,
    PAYOFF_LAYERS,
    # DSL
    @strategic,
    # Inverse toolkit (Phase 2)
    ObservedPlay, HypothesisWorld, PosteriorWorldDistribution, ranked,
    infer_from_observations,
    NarrowingSession, add_observation!, prune!, rule_in!, current_ranking,
    StructuralBreak, detect_structural_break,
    # Antifragile toolkit (Phase 3)
    WorldMutationTemplate, SurpriseEvent, SurpriseDetector,
    detect_surprise, mutate_world,
    DiscoveredPlayer, discover_players,
    Hedge, HedgeActivation, evaluate_hedges, parse_jgdl_hedges,
    ShadowPlayer, OpenWorldGame, AntifragileSolution, solve_antifragile

end # module Strategic
