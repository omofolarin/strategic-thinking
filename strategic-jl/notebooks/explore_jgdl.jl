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
using PlutoUI, JSON3, Dates, UUIDs

# ╔═╡ 00000001-0000-0000-0000-000000000002
md"""
# JGDL Explorer

Build a JGDL v1.0.0 world interactively. No solver required — this notebook
is designed to work **before** the full `Strategic.jl` implementation lands,
so you can stress-test schema design and see how the primitives compose in
JSON form.

See `docs/glossary.md` for the full term reference.
"""

# ╔═╡ 00000001-0000-0000-0000-000000000003
md"## Players"

# ╔═╡ 00000001-0000-0000-0000-000000000004
@bind n_players Slider(2:5; default=2, show_value=true)

# ╔═╡ 00000001-0000-0000-0000-000000000005
@bind player_type Select([
    "rational" => "Rational",
    "bounded_rational" => "Bounded rational",
    "llm_driven" => "LLM-driven",
])

# ╔═╡ 00000001-0000-0000-0000-000000000006
md"## Structure"

# ╔═╡ 00000001-0000-0000-0000-000000000007
@bind structure_type Select([
    "simultaneous" => "Simultaneous (Ch 4, 7)",
    "sequential" => "Sequential (Ch 2)",
    "repeated" => "Repeated (Ch 4 reciprocity)",
])

# ╔═╡ 00000001-0000-0000-0000-000000000008
@bind repetitions NumberField(1:100, default=10)

# ╔═╡ 00000001-0000-0000-0000-000000000009
@bind discount_factor Slider(0.0:0.05:1.0; default=0.9, show_value=true)

# ╔═╡ 00000001-0000-0000-0000-00000000000a
md"## Traits (Phase 1 subset)"

# ╔═╡ 00000001-0000-0000-0000-00000000000b
@bind include_commitment CheckBox(default=false)

# ╔═╡ 00000001-0000-0000-0000-00000000000c
@bind include_burned_bridge CheckBox(default=false)

# ╔═╡ 00000001-0000-0000-0000-00000000000d
@bind include_brinkmanship CheckBox(default=false)

# ╔═╡ 00000001-0000-0000-0000-00000000000e
md"## Antifragile extension (Phase 3)"

# ╔═╡ 00000001-0000-0000-0000-00000000000f
@bind include_open_world CheckBox(default=false)

# ╔═╡ 00000001-0000-0000-0000-000000000010
@bind emergence_rate Slider(0.0:0.01:0.5; default=0.05, show_value=true)

# ╔═╡ 00000001-0000-0000-0000-000000000011
md"---"

# ╔═╡ 00000001-0000-0000-0000-000000000012
"""
    build_world(; kwargs...)

Construct a JGDL-shaped dictionary. This is schema-conformant enough for
the explorer; the real Strategic.jl implementation will replace this with
structured types, but the emitted JSON should be identical.
"""
function build_world(;
    n_players::Int,
    player_type::String,
    structure_type::String,
    repetitions::Int,
    discount_factor::Float64,
    include_commitment::Bool,
    include_burned_bridge::Bool,
    include_brinkmanship::Bool,
    include_open_world::Bool,
    emergence_rate::Float64,
)
    players = [Dict(
        "id" => "p$i",
        "name" => "Player $i",
        "type" => player_type,
    ) for i in 1:n_players]

    actions = reduce(vcat, [
        [
            Dict("id" => "a$(i)_coop",   "name" => "Cooperate", "player_id" => "p$i"),
            Dict("id" => "a$(i)_defect", "name" => "Defect",    "player_id" => "p$i"),
        ]
        for i in 1:n_players
    ])

    structure = if structure_type == "sequential"
        Dict("type" => "sequential", "order" => ["p$i" for i in 1:n_players])
    elseif structure_type == "repeated"
        Dict("type" => "repeated",
             "repetitions" => repetitions,
             "discount_factor" => discount_factor)
    else
        Dict("type" => "simultaneous")
    end

    traits = []
    provenance = [Dict(
        "id" => string(uuid4()),
        "operation" => "initial_construction",
        "chapter_ref" => "Explorer",
        "rationale" => "Built interactively in explore_jgdl.jl",
        "parent_id" => "",
        "timestamp" => string(now()),
        "author" => "user",
    )]

    if include_commitment
        push!(traits, Dict(
            "id" => "p1_commitment",
            "type" => "Commitment",
            "chapter" => "Chapter 5",
            "applies_to" => "player",
            "parameters" => Dict(
                "player_id" => "p1",
                "committed_action" => "a1_coop",
                "penalty_for_deviation" => 10.0,
            ),
        ))
        push!(provenance, Dict(
            "id" => string(uuid4()),
            "operation" => "applied_trait",
            "trait_type" => "Commitment",
            "chapter_ref" => "Chapter 5",
            "rationale" => "Player 1 commits to cooperation; penalty of 10 on deviation.",
            "parent_id" => "",
            "timestamp" => string(now()),
            "author" => "user",
        ))
    end

    if include_burned_bridge
        push!(traits, Dict(
            "id" => "p1_burned_bridge",
            "type" => "BurnedBridge",
            "chapter" => "Chapter 6",
            "applies_to" => "action",
            "parameters" => Dict(
                "player_id" => "p1",
                "forbidden_action" => "a1_defect",
            ),
        ))
        push!(provenance, Dict(
            "id" => string(uuid4()),
            "operation" => "applied_trait",
            "trait_type" => "BurnedBridge",
            "chapter_ref" => "Chapter 6",
            "theoretical_origin" => "Schelling, The Strategy of Conflict (1960), Part II",
            "rationale" => "Player 1 removes defect option — restriction signals resolve.",
            "parent_id" => "",
            "timestamp" => string(now()),
            "author" => "user",
        ))
    end

    if include_brinkmanship
        push!(traits, Dict(
            "id" => "brinkmanship_p1",
            "type" => "Brinkmanship",
            "chapter" => "Chapter 8",
            "applies_to" => "game",
            "parameters" => Dict(
                "risky_action" => "a1_defect",
                "catastrophe_probability" => 0.1,
                "catastrophic_payoff" => Dict("p1" => -1000.0, "p2" => -1000.0),
            ),
        ))
        push!(provenance, Dict(
            "id" => string(uuid4()),
            "operation" => "applied_trait",
            "trait_type" => "Brinkmanship",
            "chapter_ref" => "Chapter 8",
            "rationale" => "Defecting carries 10% chance of mutual catastrophe.",
            "parent_id" => "",
            "timestamp" => string(now()),
            "author" => "user",
        ))
    end

    world = Dict(
        "id" => "sha256:0000000000000000000000000000000000000000000000000000000000000000",
        "metadata" => Dict(
            "name" => "Explorer-built world",
            "description" => "Constructed interactively via explore_jgdl.jl",
            "chapter_references" => ["Explorer"],
            "created" => string(now()),
        ),
        "players" => players,
        "actions" => actions,
        "structure" => structure,
        "payoffs" => Dict(
            "type" => "terminal_matrix",
            "matrix" => Dict{String, Dict{String, Float64}}(),
        ),
        "traits" => traits,
        "initial_state" => Dict(
            "variables" => Dict{String, Any}(),
            "history" => [],
            "current_player" => structure_type == "sequential" ? "p1" : nothing,
            "round" => 0,
        ),
        "provenance" => provenance,
    )

    if include_open_world
        world["open_world"] = Dict(
            "emergence_rate" => emergence_rate,
            "shadow_player" => Dict(
                "id" => "__shadow__",
                "surprise_weight" => 1.5,
            ),
        )
    end

    Dict("version" => "1.0.0", "world" => world)
end

# ╔═╡ 00000001-0000-0000-0000-000000000013
world = build_world(;
    n_players = n_players,
    player_type = player_type,
    structure_type = structure_type,
    repetitions = repetitions,
    discount_factor = discount_factor,
    include_commitment = include_commitment,
    include_burned_bridge = include_burned_bridge,
    include_brinkmanship = include_brinkmanship,
    include_open_world = include_open_world,
    emergence_rate = emergence_rate,
)

# ╔═╡ 00000001-0000-0000-0000-000000000014
md"## Summary"

# ╔═╡ 00000001-0000-0000-0000-000000000015
begin
    w = world["world"]
    n_traits = length(get(w, "traits", []))
    n_prov = length(w["provenance"])
    md"""
    - **Players:** $(length(w["players"]))
    - **Actions:** $(length(w["actions"]))
    - **Structure:** `$(w["structure"]["type"])`
    - **Traits stacked:** $(n_traits)
    - **Provenance nodes:** $(n_prov)
    - **Open-world:** $(haskey(w, "open_world") ? "yes" : "no")
    """
end

# ╔═╡ 00000001-0000-0000-0000-000000000016
md"## Emitted JGDL"

# ╔═╡ 00000001-0000-0000-0000-000000000017
Text(JSON3.write(world, allow_inf=false))

# ╔═╡ 00000001-0000-0000-0000-000000000018
md"## Provenance chain"

# ╔═╡ 00000001-0000-0000-0000-000000000019
md"""
$(join([
    "**$(i).** `$(node["operation"])`" *
    (haskey(node, "trait_type") ? " ($(node["trait_type"]))" : "") *
    " — *$(node["chapter_ref"])*  \n$(get(node, "rationale", ""))"
    for (i, node) in enumerate(world["world"]["provenance"])
], "\n\n"))
"""

# ╔═╡ Cell order:
# ╟─00000001-0000-0000-0000-000000000002
# ╠═00000001-0000-0000-0000-000000000001
# ╟─00000001-0000-0000-0000-000000000003
# ╠═00000001-0000-0000-0000-000000000004
# ╠═00000001-0000-0000-0000-000000000005
# ╟─00000001-0000-0000-0000-000000000006
# ╠═00000001-0000-0000-0000-000000000007
# ╠═00000001-0000-0000-0000-000000000008
# ╠═00000001-0000-0000-0000-000000000009
# ╟─00000001-0000-0000-0000-00000000000a
# ╠═00000001-0000-0000-0000-00000000000b
# ╠═00000001-0000-0000-0000-00000000000c
# ╠═00000001-0000-0000-0000-00000000000d
# ╟─00000001-0000-0000-0000-00000000000e
# ╠═00000001-0000-0000-0000-00000000000f
# ╠═00000001-0000-0000-0000-000000000010
# ╟─00000001-0000-0000-0000-000000000011
# ╟─00000001-0000-0000-0000-000000000012
# ╠═00000001-0000-0000-0000-000000000013
# ╟─00000001-0000-0000-0000-000000000014
# ╠═00000001-0000-0000-0000-000000000015
# ╟─00000001-0000-0000-0000-000000000016
# ╠═00000001-0000-0000-0000-000000000017
# ╟─00000001-0000-0000-0000-000000000018
# ╠═00000001-0000-0000-0000-000000000019
