# strategic(text) — parse a DSL string into a StrategicWorld.
#
# Full grammar:
#
#   # Metadata
#   name: Market Entry Game
#   chapter: Chapter 2
#
#   # Players (with optional parameters)
#   player Alice can [cooperate, defect]
#   player Bob   can [cooperate, defect]
#   Alice rationality: 0.8
#   Alice risk_aversion: 1.5
#
#   # Structure
#   Alice moves first          # sequential; remaining players appended in declaration order
#   repeated, infinite, discount 0.9   # repeated game
#
#   # Payoffs
#   payoff:
#       (cooperate, cooperate) => (3, 3)
#       (cooperate, defect)    => (0, 5)
#       (defect,    cooperate) => (5, 0)
#       (defect,    defect)    => (1, 1)
#
#   # Traits
#   Alice commits to cooperate
#   Alice threatens: if Bob defect => Alice defect
#   Alice burns bridge: accommodate
#   Alice mixes: cooperate 0.7, defect 0.3
#   fight carries 10% catastrophe: (-1000, -1000)

"""
    strategic(text::AbstractString) -> StrategicWorld

Parse a DSL description into a StrategicWorld. See `src/dsl/macro.jl` for full grammar.
"""
function strategic(text::AbstractString)::StrategicWorld
    players = Pair{Symbol, Vector{Symbol}}[]
    player_params = Dict{Symbol, Dict{Symbol, Float64}}()
    order = Symbol[]
    payoffs = Dict{String, Dict{Symbol, Float64}}()
    traits = GameTrait[]
    prov_notes = String[]
    in_payoff = false
    world_name = ""
    chapter_refs = String[]
    structure_type = "simultaneous"
    discount_factor = nothing
    repetitions = nothing

    for (lineno, raw) in enumerate(split(text, "\n"))
        line = strip(raw)
        isempty(line) && continue

        # name: Market Entry Game
        m = match(r"^name:\s*(.+)$", line)
        if m !== nothing
            world_name = strip(m[1])
            continue
        end

        # chapter: Chapter 2
        m = match(r"^chapter:\s*(.+)$", line)
        if m !== nothing
            push!(chapter_refs, strip(m[1]))
            continue
        end

        # player Alice can [cooperate, defect]
        m = match(r"^player\s+(\w+)\s+can\s+\[([^\]]+)\]$", line)
        if m !== nothing
            name = Symbol(m[1])
            acts = [Symbol(strip(a)) for a in split(m[2], ",")]
            push!(players, name => acts)
            in_payoff = false
            continue
        end

        # Alice rationality: 0.8
        m = match(r"^(\w+)\s+rationality:\s*([\d.]+)$", line)
        if m !== nothing
            pid = Symbol(m[1])
            get!(player_params, pid, Dict{Symbol, Float64}())[:rationality_factor] = parse(Float64, m[2])
            continue
        end

        # Alice risk_aversion: 1.5
        m = match(r"^(\w+)\s+risk_aversion:\s*([\d.]+)$", line)
        if m !== nothing
            pid = Symbol(m[1])
            get!(player_params, pid, Dict{Symbol, Float64}())[:risk_aversion] = parse(Float64, m[2])
            continue
        end

        # Alice discount: 0.9
        m = match(r"^(\w+)\s+discount:\s*([\d.]+)$", line)
        if m !== nothing
            pid = Symbol(m[1])
            get!(player_params, pid, Dict{Symbol, Float64}())[:discount_rate] = parse(Float64, m[2])
            continue
        end

        # Alice moves first / second / last
        m = match(r"^(\w+)\s+moves\s+\w+$", line)
        if m !== nothing
            push!(order, Symbol(m[1]))
            structure_type = "sequential"
            in_payoff = false
            continue
        end

        # repeated, infinite, discount 0.9
        # repeated, 10, discount 0.8
        m = match(r"^repeated,\s*(infinite|\d+),\s*discount\s+([\d.]+)$", line)
        if m !== nothing
            structure_type = "repeated"
            repetitions = m[1] == "infinite" ? "infinite" : parse(Int, m[1])
            discount_factor = parse(Float64, m[2])
            continue
        end

        # payoff:
        if match(r"^payoff\s*:", line) !== nothing
            in_payoff = true
            continue
        end

        # (cooperate, defect) => (0, 5)
        if in_payoff
            m = match(r"^\(([^)]+)\)\s*=>\s*\(([^)]+)\)$", line)
            if m !== nothing
                acts = [Symbol(strip(a)) for a in split(m[1], ",")]
                vals = [parse(Float64, strip(v)) for v in split(m[2], ",")]
                key = join(string.(acts), ".")
                payoffs[key] = Dict(players[i].first => vals[i]
                for i in 1:min(length(players), length(vals)))
                continue
            end
            in_payoff = false
        end

        # Alice commits to cooperate
        m = match(r"^(\w+)\s+commits\s+to\s+(\w+)$", line)
        if m !== nothing
            pid = Symbol(m[1]);
            aid = Symbol(m[2])
            push!(traits, CommitmentTrait(pid, aid, 100.0))
            push!(prov_notes, "$(m[1]) commits to $(m[2]) (Chapter 5)")
            continue
        end

        # Alice threatens: if Bob defect => Alice defect
        m = match(r"^(\w+)\s+threatens:\s+if\s+(\w+)\s+(\w+)\s*=>\s*(\w+)\s+(\w+)$", line)
        if m !== nothing
            push!(traits, CredibleThreatTrait(Symbol(m[1]), Symbol(m[3]), Symbol(m[5]), 1.0))
            push!(prov_notes, "$(m[1]) threatens $(m[5]) if $(m[2]) plays $(m[3]) (Chapter 6)")
            continue
        end

        # Alice burns bridge: accommodate
        m = match(r"^(\w+)\s+burns\s+bridge:\s+(\w+)$", line)
        if m !== nothing
            push!(traits, BurnedBridgeTrait(Symbol(m[1]), Symbol(m[2])))
            push!(prov_notes, "$(m[1]) burns bridge on $(m[2]) (Chapter 6)")
            continue
        end

        # Alice mixes: cooperate 0.7, defect 0.3
        m = match(r"^(\w+)\s+mixes:\s+(.+)$", line)
        if m !== nothing
            pid = Symbol(m[1])
            dist = Dict{Symbol, Float64}()
            for part in split(m[2], ",")
                part = strip(part)
                pm = match(r"^(\w+)\s+([\d.]+)$", part)
                pm !== nothing && (dist[Symbol(pm[1])] = parse(Float64, pm[2]))
            end
            push!(traits, MixedStrategyTrait(pid, dist))
            push!(prov_notes, "$(m[1]) uses mixed strategy (Chapter 7)")
            continue
        end

        # fight carries 10% catastrophe: (-1000, -1000)
        m = match(r"^(\w+)\s+carries\s+([\d.]+)%\s+catastrophe:\s+\(([^)]+)\)$", line)
        if m !== nothing
            risky = Symbol(m[1])
            prob = parse(Float64, m[2]) / 100.0
            vals = [parse(Float64, strip(v)) for v in split(m[3], ",")]
            cat_payoff = Dict(players[i].first => vals[i]
            for i in 1:min(length(players), length(vals)))
            push!(traits, BrinkmanshipTrait(risky, prob, cat_payoff))
            push!(prov_notes, "$(m[1]) carries $(m[2])% catastrophe risk (Chapter 8)")
            continue
        end

        # relative payoff weight: 0.5
        m = match(r"^relative\s+payoff\s+weight:\s*([\d.]+)$", line)
        if m !== nothing
            push!(traits, TournamentIncentiveTrait(parse(Float64, m[1])))
            push!(prov_notes, "tournament incentive, relative weight=$(m[1]) (Chapter 12)")
            continue
        end

        error("strategic DSL line $lineno: unrecognised: $(repr(line))")
    end

    isempty(players) && error("strategic DSL: no players declared")

    # Unique player IDs
    player_ids = [pid for (pid, _) in players]
    dupes = [id for id in player_ids if count(==(id), player_ids) > 1] |> unique
    isempty(dupes) || error("strategic DSL: duplicate player ids: $(join(dupes, ", "))")

    # Unique action IDs within each player (same name across players is fine)
    for (pid, acts) in players
        dupes = [id for id in acts if count(==(id), acts) > 1] |> unique
        isempty(dupes) ||
            error("strategic DSL: player $pid has duplicate action ids: $(join(dupes, ", "))")
    end

    all_action_ids = Set(aid for (_, acts) in players for aid in acts)

    all_action_ids = Set(aid for (_, acts) in players for aid in acts)

    # Payoff key segments reference declared action IDs
    for key in keys(payoffs)
        for seg in split(string(key), ".")
            seg == "*" && continue
            Symbol(seg) ∉ all_action_ids &&
                error("strategic DSL: payoff key '$key' references undeclared action '$seg'. " *
                      "Declared: $(join(sort(string.(collect(all_action_ids))), ", "))")
        end
    end

    # Payoff matrix completeness (2-player games) — hard error only if payoffs block exists but is empty
    isempty(payoffs) && length(players) > 0 &&
        error("strategic DSL: payoff block is empty — no outcomes defined")

    # Trait references valid IDs
    for t in traits
        if t isa BurnedBridgeTrait
            t.player_id ∉ all_action_ids || true  # player_id checked below
            t.forbidden_action ∉ all_action_ids &&
                error("strategic DSL: burns bridge references undeclared action '$(t.forbidden_action)'")
            t.player_id ∉ Set(player_ids) &&
                error("strategic DSL: burns bridge references undeclared player '$(t.player_id)'")
        elseif t isa CommitmentTrait
            t.committed_action ∉ all_action_ids &&
                error("strategic DSL: commits to undeclared action '$(t.committed_action)'")
        elseif t isa MixedStrategyTrait
            total = sum(values(t.distribution); init = 0.0)
            abs(total - 1.0) > 0.01 &&
                error("strategic DSL: mixed strategy for $(t.player_id) sums to $(round(total; digits=4)), expected 1.0")
        elseif t isa BrinkmanshipTrait
            (t.catastrophe_probability < 0 || t.catastrophe_probability > 1) &&
                error("strategic DSL: catastrophe_probability=$(t.catastrophe_probability) must be in [0, 1]")
        end
    end

    # Sequential order references declared players
    for pid in order
        pid ∉ Set(player_ids) &&
            error("strategic DSL: move order references undeclared player '$pid'")
    end

    # Complete sequential order with undeclared players
    if structure_type == "sequential" && !isempty(order)
        declared = Set(order)
        for (pid, _) in players
            pid ∉ declared && push!(order, pid)
        end
    end

    actions = [Action(aid, string(aid), pid) for (pid, acts) in players for aid in acts]

    # Apply BurnedBridge filtering
    forbidden = Dict{Symbol, Vector{Symbol}}()
    for t in traits
        t isa BurnedBridgeTrait &&
            push!(get!(forbidden, t.player_id, Symbol[]), t.forbidden_action)
    end
    if !isempty(forbidden)
        actions = filter(a -> !(a.id in get(forbidden, a.player_id, Symbol[])), actions)
    end

    # Build structure dict
    structure_dict = Dict{String, Any}("type" => structure_type)
    structure_type == "sequential" && (structure_dict["order"] = string.(order))
    if structure_type == "repeated"
        structure_dict["repetitions"] = repetitions
        structure_dict["discount_factor"] = discount_factor
    end

    # Provenance
    rationale = (isempty(world_name) ? "World" : world_name) *
                " constructed via strategic() DSL." *
                (isempty(prov_notes) ? "" : " " * join(prov_notes, "; "))
    prov = [ProvenanceNode("initial_construction", "Chapter 1", rationale; parent_id = "")]
    for t in traits
        chapter = t isa CommitmentTrait ? "Chapter 5" :
                  t isa BurnedBridgeTrait ? "Chapter 6" :
                  t isa CredibleThreatTrait ? "Chapter 6" :
                  t isa MixedStrategyTrait ? "Chapter 7" :
                  t isa BrinkmanshipTrait ? "Chapter 8" : "Chapter 1"
        push!(prov,
            ProvenanceNode(
                "applied_trait", chapter,
                "Trait $(nameof(typeof(t))) applied via strategic() DSL";
                trait_type = string(nameof(typeof(t))),
                parent_id = ""
            ))
    end

    metadata = Dict{String, Any}(
        "name" => world_name,
        "chapter_references" => isempty(chapter_refs) ? ["Chapter 1"] : chapter_refs,
        "actions" => actions,
        "move_order" => order,
        "payoffs" => Dict("type" => "terminal_matrix", "matrix" => payoffs),
        "structure" => structure_dict,
        "player_params" => player_params
    )

    StrategicWorld("sha256:" * "0"^64, _NullGame(), traits, prov, metadata)
end

# @strategic accepts a string literal only.
macro strategic(s::AbstractString)
    :(strategic($s))
end
macro strategic(s)
    error("@strategic requires a string literal. Use strategic(\"\"\"...\"\"\")")
end
