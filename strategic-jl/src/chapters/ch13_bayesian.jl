# Chapter 13: Bayesian reasoning — incomplete information, private types.

struct BayesianBeliefTrait <: GameTrait
    player_id::Symbol
    about::Symbol
    prior::Distribution
    update_rule::Symbol   # :bayes, :quantal_response, :fictitious_play
end

register_trait!(BayesianBeliefTrait, Set([:update_beliefs]))

struct BayesianNashSolver <: SolverMethod end

struct BayesianNashResult
    strategy::String          # Description of the BNE strategy
    bne_bid_formula::String   # For auction: "bid = value × factor"
    bid_factor::Float64       # The multiplier on private value
    prior_distribution::String
    provenance::Vector{ProvenanceNode}
end

"""
    solve(world, ::BayesianNashSolver) -> BayesianNashResult

Bayesian Nash Equilibrium solver for first-price sealed-bid auctions
with symmetric bidders and uniform private values.

For n bidders with values drawn from Uniform[0, V]:
  BNE bid = value × (n-1)/n

For 2 bidders: bid = value/2
For 3 bidders: bid = value × 2/3

This is the unique symmetric BNE. Bidding your full value yields zero surplus;
shading by (n-1)/n balances the probability of winning against the surplus captured.
"""
function solve(world::StrategicWorld, ::BayesianNashSolver)::BayesianNashResult
    prov = ProvenanceNode[]

    # Count bidders
    actions = get(world.metadata, "actions", Action[])
    n_bidders = length(unique(a.player_id for a in actions))
    n_bidders = max(n_bidders, 2)  # at least 2

    bid_factor = (n_bidders - 1) / n_bidders
    formula = n_bidders == 2 ? "bid = value / 2" :
              "bid = value × $(n_bidders-1)/$(n_bidders)"

    push!(prov,
        ProvenanceNode(
            "bayesian_nash_equilibrium", "Chapter 13",
            "First-price auction BNE with $n_bidders symmetric bidders, Uniform[0,1] values. " *
            "BNE strategy: $formula. " *
            "Derivation: bidder maximises (value - bid) × P(win). " *
            "P(win) = (bid/V)^(n-1) for uniform prior. " *
            "FOC gives bid = value × (n-1)/n.";
            parent_id = "",
            theoretical_origin = "Vickrey, Counterspeculation, Auctions, and Competitive Sealed Tenders (1961)"
        ))

    BayesianNashResult(
        "Bid $(round(bid_factor; digits=4)) × private value",
        formula,
        bid_factor,
        "Uniform[0,1]",
        prov
    )
end
