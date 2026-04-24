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
include("solvers/forward/repeated.jl")
include("solvers/inverse/bayesian_inference.jl")
include("solvers/inverse/hypothesis_narrowing.jl")
include("solvers/inverse/structural_break.jl")

include("antifragile/surprise_detector.jl")
include("antifragile/player_discovery.jl")
include("antifragile/latent.jl")
include("antifragile/hedges.jl")
include("antifragile/open_world.jl")

include("jgdl/serialize.jl")
include("jgdl/deserialize.jl")
include("jgdl/validate.jl")

include("elicitation/payoff_elicitation.jl")
include("dsl/macro.jl")

# Core types
export StrategicWorld, Player, Action, State, LazyGameTree
export ProvenanceNode, GameTrait, WithTrait
export Solution, SolverMethod, PlayerStrategy

# Foundation (Ch 1–4)
export Tale, TALES, tale, tales_covering
export InformationSet, SequentialInvariants, validate_sequential, look_ahead_depth
export DominanceRelation, RationalizableSet, IteratedDominance, IteratedDominanceResult
export dominates
export TitForTat, GrimTrigger, Pavlov, GenerousTFT, choose_action

# Modifier traits (Ch 5–13)
export CommitmentTrait, CredibleThreatTrait, BurnedBridgeTrait
export MixedStrategyTrait, BrinkmanshipTrait
export CoordinationDeviceTrait, VotingRuleTrait
export BargainingProtocolTrait, TournamentIncentiveTrait, BayesianBeliefTrait
export solve_with_focal

# Solvers
export BackwardInduction, NashEquilibrium, MixedNashResult
export VotingSolver, VotingResult
export BargainingSolver, BargainingResult
export BayesianNashSolver, BayesianNashResult
export RepeatedGameSolver, RepeatedGameResult, AlwaysDefect
export solve, simulate

# JGDL
export to_jgdl, from_jgdl, world_id, validate_jgdl, ValidationError

# Elicitation (LLM-assisted payoff construction)
export PayoffLayerEstimate, ElicitedOutcomePayoff, ElicitedPayoffMatrix
export to_payoff_matrix, mean_confidence, build_world_from_elicitation, elicit_layer
export PAYOFF_LAYERS

# DSL
export strategic, @strategic

# Inverse toolkit (Phase 2)
export ObservedPlay, HypothesisWorld, PosteriorWorldDistribution, ranked
export infer_from_observations
export NarrowingSession, add_observation!, prune!, rule_in!, current_ranking
export StructuralBreak, detect_structural_break

# Antifragile toolkit (Phase 3)
export WorldMutationTemplate, SurpriseEvent, SurpriseDetector
export detect_surprise, mutate_world
export DiscoveredPlayer, discover_players
export LatentConfounderHypothesis, detect_latent_confounder
export Hedge, HedgeActivation, evaluate_hedges, parse_jgdl_hedges
export ShadowPlayer, OpenWorldGame, AntifragileSolution, solve_antifragile

end # module Strategic
