module Strategic

using JSON3, SHA, Dates, UUIDs, Graphs, Distributions

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

include("antifragile/open_world.jl")
include("antifragile/surprise_detector.jl")
include("antifragile/player_discovery.jl")
include("antifragile/hedges.jl")

include("jgdl/serialize.jl")
include("jgdl/deserialize.jl")
include("jgdl/validate.jl")

include("dsl/macro.jl")

export
    StrategicWorld, Player, Action, State, LazyGameTree,
    ProvenanceNode, GameTrait, WithTrait,
    # Foundation (Ch 1–4)
    Tale, TALES, tale, tales_covering,
    InformationSet, SequentialInvariants,
    DominanceRelation, RationalizableSet, IteratedDominance,
    TitForTat, GrimTrigger, Pavlov, GenerousTFT,
    # Solvers
    BackwardInduction, NashEquilibrium, solve, simulate,
    # JGDL
    to_jgdl, from_jgdl, world_id,
    # DSL
    @strategic

end # module Strategic
