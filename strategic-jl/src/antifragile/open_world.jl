# Open-world extension: there are always players and actions we haven't observed.

struct ShadowPlayer <: PlayerStrategy
    id::Symbol
    surprise_weight::Float64
end

struct OpenWorldGame{G <: AbstractGame} <: AbstractGame
    inner::G
    emergence_rate::Float64
    shadow::ShadowPlayer
end

function available_actions(g::OpenWorldGame, state::State, player::Player)
    available_actions(g.inner, state, player)
end

payoff(g::OpenWorldGame, state::State) = payoff(g.inner, state)

"""
    AntifragileSolution

Result of solve_antifragile. Extends Solution with surprise events,
discovered players, and activated hedges — all with provenance.
"""
struct AntifragileSolution
    base_solution::Solution
    surprise_events::Vector{SurpriseEvent}
    discovered_players::Vector{DiscoveredPlayer}
    hedge_activations::Vector{HedgeActivation}
    provenance_chain::Vector{ProvenanceNode}
end

"""
    solve_antifragile(world, observations; hedges, threshold) -> AntifragileSolution

Runs the forward solver, then:
1. Checks each observation for surprise (detect_surprise).
2. Discovers unknown players (discover_players).
3. Evaluates hedges against each observation (evaluate_hedges).

Every step appends provenance. The result carries the full chain.
"""
function solve_antifragile(
        world::StrategicWorld,
        observations::Vector{ObservedPlay};
        hedges::Vector{Hedge} = Hedge[],
        threshold::Float64 = 2.0
)::AntifragileSolution
    # Forward solve
    base = solve(world, BackwardInduction())

    # Surprise detection
    detector = SurpriseDetector(world; threshold = threshold)
    surprises = filter(!isnothing, [detect_surprise(detector, obs) for obs in observations])

    # Player discovery
    discovered = discover_players(world, observations)

    # Hedge evaluation
    activations = HedgeActivation[]
    for obs in observations
        state = obs.context
        append!(activations, evaluate_hedges(hedges, obs, state))
    end

    # Collect all provenance
    all_prov = vcat(
        base.provenance_chain,
        [e.provenance for e in surprises]...,
        [d.provenance for d in discovered]...,
        [a.provenance for a in activations]...
    )

    isempty(all_prov) && push!(all_prov,
        ProvenanceNode(
            "antifragile_solve", "Chapter 1",
            "solve_antifragile completed with no surprises, discoveries, or hedge activations.";
            parent_id = ""
        ))

    AntifragileSolution(base, surprises, discovered, activations, all_prov)
end
