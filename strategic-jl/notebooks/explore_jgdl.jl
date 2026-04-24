### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 00000001-0000-0000-0000-000000000001
begin
    using Pkg
    Pkg.activate(joinpath(@__DIR__, ".."))
    using Strategic
    using PlutoUI
    using JSON
end

# ╔═╡ 00000001-0000-0000-0000-000000000002
md"""
# Strategic.jl Explorer

Build a 2×2 game with sliders, stack traits onto it, and run the solver live.
The provenance panel shows the **actual** citation chain the solver produced —
not a hand-written dict.

Use this to eyeball how commitment, brinkmanship, or tournament incentives
shift the equilibrium relative to the baseline payoff matrix.
"""

# ╔═╡ 00000001-0000-0000-0000-000000000003
md"## Baseline stage game (2×2)"

# ╔═╡ 00000001-0000-0000-0000-000000000004
md"""
Standard convention: R = mutual cooperation, T = temptation to defect,
S = sucker's payoff, P = mutual punishment. For a prisoner's dilemma you
want T > R > P > S.
"""

# ╔═╡ 00000001-0000-0000-0000-000000000005
@bind R Slider(-5.0:0.5:10.0; default = 3.0, show_value = true)

# ╔═╡ 00000001-0000-0000-0000-000000000006
@bind T Slider(-5.0:0.5:10.0; default = 5.0, show_value = true)

# ╔═╡ 00000001-0000-0000-0000-000000000007
@bind P Slider(-5.0:0.5:10.0; default = 1.0, show_value = true)

# ╔═╡ 00000001-0000-0000-0000-000000000008
@bind S Slider(-5.0:0.5:10.0; default = 0.0, show_value = true)

# ╔═╡ 00000001-0000-0000-0000-000000000009
md"## Traits to stack"

# ╔═╡ 00000001-0000-0000-0000-00000000000a
@bind include_commitment CheckBox(default = false)

# ╔═╡ 00000001-0000-0000-0000-00000000000b
@bind include_brinkmanship CheckBox(default = false)

# ╔═╡ 00000001-0000-0000-0000-00000000000c
@bind include_tournament CheckBox(default = false)

# ╔═╡ 00000001-0000-0000-0000-00000000000d
md"### Trait parameters"

# ╔═╡ 00000001-0000-0000-0000-00000000000e
@bind commitment_penalty Slider(0.0:1.0:100.0; default = 20.0, show_value = true)

# ╔═╡ 00000001-0000-0000-0000-00000000000f
@bind catastrophe_prob Slider(0.0:0.05:0.5; default = 0.1, show_value = true)

# ╔═╡ 00000001-0000-0000-0000-000000000010
@bind tournament_weight Slider(0.0:0.1:2.0; default = 0.5, show_value = true)

# ╔═╡ 00000001-0000-0000-0000-000000000011
md"---
## World"

# ╔═╡ 00000001-0000-0000-0000-000000000012
# Build the world from the baseline payoffs + selected traits. The DSL does
# the schema work; we then layer trait structs directly so sliders drive
# their parameters without rewriting the DSL string.
world = let
    base = strategic("""
        player p1 can [cooperate, defect]
        player p2 can [cooperate, defect]
        payoff:
            (cooperate, cooperate) => ($R, $R)
            (cooperate, defect)    => ($S, $T)
            (defect,    cooperate) => ($T, $S)
            (defect,    defect)    => ($P, $P)
    """)
    traits = GameTrait[]
    prov = copy(base.provenance)
    if include_commitment
        push!(traits, CommitmentTrait(:p1, :cooperate, commitment_penalty))
        push!(prov,
            ProvenanceNode("applied_trait", "Chapter 5",
                "p1 commits to cooperate with penalty=$(commitment_penalty)";
                trait_type = "CommitmentTrait", parent_id = base.id))
    end
    if include_brinkmanship
        push!(traits,
            BrinkmanshipTrait(:defect, catastrophe_prob,
                Dict(:p1 => -1000.0, :p2 => -1000.0)))
        push!(prov,
            ProvenanceNode("applied_trait", "Chapter 8",
                "defect carries $(round(catastrophe_prob*100; digits=1))% catastrophe risk";
                trait_type = "BrinkmanshipTrait", parent_id = base.id))
    end
    if include_tournament
        push!(traits, TournamentIncentiveTrait(tournament_weight))
        push!(prov,
            ProvenanceNode("applied_trait", "Chapter 12",
                "relative-payoff weight=$(tournament_weight)";
                trait_type = "TournamentIncentiveTrait", parent_id = base.id))
    end
    StrategicWorld(base.id, base.game, vcat(base.traits, traits), prov, base.metadata)
end

# ╔═╡ 00000001-0000-0000-0000-000000000013
md"## Solve it"

# ╔═╡ 00000001-0000-0000-0000-000000000014
@bind solver_choice Select([
    "backward" => "BackwardInduction (simultaneous Nash)",
    "dominance" => "IteratedDominance (rationalizable set)",
    "nash" => "NashEquilibrium (pure + mixed)"
])

# ╔═╡ 00000001-0000-0000-0000-000000000015
solution = let
    if solver_choice == "backward"
        solve(world, BackwardInduction())
    elseif solver_choice == "dominance"
        solve(world, IteratedDominance())
    else
        solve(world, NashEquilibrium())
    end
end

# ╔═╡ 00000001-0000-0000-0000-000000000016
md"### Equilibrium"

# ╔═╡ 00000001-0000-0000-0000-000000000017
# Render the solver output in a solver-specific way. Every branch pulls its
# provenance from the actual returned object — no hand-written dicts.
equilibrium_summary = if solution isa Solution
    path = isempty(solution.equilibrium_path) ? "(none found)" :
        join((string(a.id) for a in solution.equilibrium_path), " → ")
    payoffs = join(("$k=$(round(v; digits=2))" for (k, v) in solution.payoffs), ", ")
    md"""
    - **Path:** $(path)
    - **Payoffs:** $(payoffs)
    """
elseif solution isa IteratedDominanceResult
    sets = join(
        ("$(s.player_id) → {$(join(s.surviving_actions, ", "))}" for s in solution.sets),
        "; ")
    md"""
    - **Rationalizable sets:** $(sets)
    - **Eliminations:** $(length(solution.eliminations))
    """
elseif solution isa MixedNashResult
    pure = isempty(solution.pure_nash) ? "none" :
        join(("($(n[1]), $(n[2]))" for n in solution.pure_nash), ", ")
    mixed = solution.mixed_equilibrium === nothing ? "none (or degenerate)" :
        string(solution.mixed_equilibrium)
    md"""
    - **Pure Nash:** $(pure)
    - **Mixed Nash:** $(mixed)
    """
end

# ╔═╡ 00000001-0000-0000-0000-000000000018
md"### Provenance chain"

# ╔═╡ 00000001-0000-0000-0000-000000000019
# The solver's own chain — the LLM explanation layer reads from this graph.
provenance_chain = if solution isa Solution
    solution.provenance_chain
elseif solution isa IteratedDominanceResult
    solution.provenance_chain
else
    solution.provenance
end

# ╔═╡ 00000001-0000-0000-0000-00000000001a
md"""
$(join([
    "**$(i).** `$(n.operation)`" *
    (n.trait_type === nothing ? "" : " ($(n.trait_type))") *
    " — *$(n.chapter_ref)*" *
    (n.theoretical_origin === nothing ? "" : "  \n    _source: $(n.theoretical_origin)_") *
    "  \n    $(n.rationale)"
    for (i, n) in enumerate(provenance_chain)
], "\n\n"))
"""

# ╔═╡ 00000001-0000-0000-0000-00000000001b
md"---
## Repeated play (Chapter 4)"

# ╔═╡ 00000001-0000-0000-0000-00000000001c
md"""
Pick a strategy for each player and simulate `horizon` rounds with the
baseline payoff matrix. TFT vs TFT cooperates; TFT vs AllDefect converges
to mutual defection; GrimTrigger retaliates forever after the first defection.
"""

# ╔═╡ 00000001-0000-0000-0000-00000000001d
@bind p1_strategy Select([
    "tft" => "TitForTat",
    "grim" => "GrimTrigger",
    "pavlov" => "Pavlov (win-stay, lose-shift)",
    "alldefect" => "AlwaysDefect"
])

# ╔═╡ 00000001-0000-0000-0000-00000000001e
@bind p2_strategy Select([
    "tft" => "TitForTat",
    "grim" => "GrimTrigger",
    "pavlov" => "Pavlov (win-stay, lose-shift)",
    "alldefect" => "AlwaysDefect"
])

# ╔═╡ 00000001-0000-0000-0000-00000000001f
@bind horizon Slider(5:5:100; default = 20, show_value = true)

# ╔═╡ 00000001-0000-0000-0000-000000000020
@bind discount_factor Slider(0.1:0.05:0.99; default = 0.95, show_value = true)

# ╔═╡ 00000001-0000-0000-0000-000000000021
repeated_result = let
    mk(choice, opp) = choice == "tft" ? TitForTat(opp) :
                      choice == "grim" ? GrimTrigger(opp) :
                      choice == "pavlov" ? Pavlov(opp) :
                      AlwaysDefect(opp)
    strategies = Dict{Symbol, PlayerStrategy}(
        :p1 => mk(p1_strategy, :p2),
        :p2 => mk(p2_strategy, :p1)
    )
    simulate(world, strategies; horizon = horizon, discount_factor = discount_factor)
end

# ╔═╡ 00000001-0000-0000-0000-000000000022
repeated_summary = let
    coop = count(r -> all(a -> occursin("cooperate", string(a)), values(r)),
        repeated_result.trajectory)
    defect = count(r -> all(a -> occursin("defect", string(a)), values(r)),
        repeated_result.trajectory)
    n = length(repeated_result.trajectory)
    payoffs = join(
        ("$k=$(round(v; digits=2))" for (k, v) in repeated_result.discounted_payoffs),
        ", ")
    md"""
    - **Rounds of mutual cooperation:** $(coop) / $(n)
    - **Rounds of mutual defection:** $(defect) / $(n)
    - **Discounted payoffs:** $(payoffs)
    """
end

# ╔═╡ 00000001-0000-0000-0000-000000000023
md"### Simulation provenance"

# ╔═╡ 00000001-0000-0000-0000-000000000024
md"""
$(join([
    "**$(i).** `$(n.operation)` — *$(n.chapter_ref)*" *
    (n.theoretical_origin === nothing ? "" : "  \n    _source: $(n.theoretical_origin)_") *
    "  \n    $(n.rationale)"
    for (i, n) in enumerate(repeated_result.provenance_chain)
], "\n\n"))
"""

# ╔═╡ 00000001-0000-0000-0000-000000000025
md"---
## Load a compliance fixture

Pick any of the authored JGDL fixtures under `jgdl/compliance/tests/` to
round-trip it through `from_jgdl` and run the expected solver."

# ╔═╡ 00000001-0000-0000-0000-000000000026
fixture_dir = joinpath(@__DIR__, "..", "..", "jgdl", "compliance", "tests")

# ╔═╡ 00000001-0000-0000-0000-000000000027
fixture_files = sort(filter(f -> endswith(f, ".json"), readdir(fixture_dir)))

# ╔═╡ 00000001-0000-0000-0000-000000000028
@bind fixture_choice Select(fixture_files)

# ╔═╡ 00000001-0000-0000-0000-000000000029
fixture_doc = JSON.parsefile(joinpath(fixture_dir, fixture_choice))

# ╔═╡ 00000001-0000-0000-0000-00000000002a
fixture_world = from_jgdl(fixture_doc["jgdl"])

# ╔═╡ 00000001-0000-0000-0000-00000000002b
fixture_summary = md"""
- **ID:** $(fixture_doc["id"])
- **Concept:** $(fixture_doc["concept"])
- **Expected solver:** $(get(fixture_doc["expected"], "solver", "—"))
- **Players:** $(length(get(fixture_world.metadata, "actions_raw", [])))
- **Traits parsed:** $(length(fixture_world.traits))
- **Provenance nodes:** $(length(fixture_world.provenance))
"""

# ╔═╡ Cell order:
# ╟─00000001-0000-0000-0000-000000000002
# ╠═00000001-0000-0000-0000-000000000001
# ╟─00000001-0000-0000-0000-000000000003
# ╟─00000001-0000-0000-0000-000000000004
# ╠═00000001-0000-0000-0000-000000000005
# ╠═00000001-0000-0000-0000-000000000006
# ╠═00000001-0000-0000-0000-000000000007
# ╠═00000001-0000-0000-0000-000000000008
# ╟─00000001-0000-0000-0000-000000000009
# ╠═00000001-0000-0000-0000-00000000000a
# ╠═00000001-0000-0000-0000-00000000000b
# ╠═00000001-0000-0000-0000-00000000000c
# ╟─00000001-0000-0000-0000-00000000000d
# ╠═00000001-0000-0000-0000-00000000000e
# ╠═00000001-0000-0000-0000-00000000000f
# ╠═00000001-0000-0000-0000-000000000010
# ╟─00000001-0000-0000-0000-000000000011
# ╠═00000001-0000-0000-0000-000000000012
# ╟─00000001-0000-0000-0000-000000000013
# ╠═00000001-0000-0000-0000-000000000014
# ╠═00000001-0000-0000-0000-000000000015
# ╟─00000001-0000-0000-0000-000000000016
# ╠═00000001-0000-0000-0000-000000000017
# ╟─00000001-0000-0000-0000-000000000018
# ╠═00000001-0000-0000-0000-000000000019
# ╠═00000001-0000-0000-0000-00000000001a
# ╟─00000001-0000-0000-0000-00000000001b
# ╟─00000001-0000-0000-0000-00000000001c
# ╠═00000001-0000-0000-0000-00000000001d
# ╠═00000001-0000-0000-0000-00000000001e
# ╠═00000001-0000-0000-0000-00000000001f
# ╠═00000001-0000-0000-0000-000000000020
# ╠═00000001-0000-0000-0000-000000000021
# ╠═00000001-0000-0000-0000-000000000022
# ╟─00000001-0000-0000-0000-000000000023
# ╠═00000001-0000-0000-0000-000000000024
# ╟─00000001-0000-0000-0000-000000000025
# ╠═00000001-0000-0000-0000-000000000026
# ╠═00000001-0000-0000-0000-000000000027
# ╠═00000001-0000-0000-0000-000000000028
# ╠═00000001-0000-0000-0000-000000000029
# ╠═00000001-0000-0000-0000-00000000002a
# ╠═00000001-0000-0000-0000-00000000002b
