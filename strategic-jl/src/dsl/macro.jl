# strategic(text) — parse a DSL string into a StrategicWorld.
#
# Grammar:
#   player Alice can [cooperate, defect]
#   player Bob   can [cooperate, defect]
#   Alice moves first                              # optional: sequential
#   payoff:
#       (cooperate, cooperate) => (3, 3)
#       (cooperate, defect)    => (0, 5)
#       (defect,    cooperate) => (5, 0)
#       (defect,    defect)    => (1, 1)
#   Alice commits to cooperate                     # optional: CommitmentTrait
#   Alice threatens: if Bob defect => Alice defect # optional: CredibleThreatTrait
#   Alice burns bridge: accommodate                # optional: BurnedBridgeTrait
#
# Example:
#   world = strategic("""
#       player p1 can [cooperate, defect]
#       player p2 can [cooperate, defect]
#       payoff:
#           (cooperate, cooperate) => (3, 3)
#           (defect,    defect)    => (1, 1)
#   """)

"""
    strategic(text::AbstractString) -> StrategicWorld

Parse a DSL description into a StrategicWorld. See `src/dsl/macro.jl` for grammar.
"""
function strategic(text::AbstractString)::StrategicWorld
    players   = Pair{Symbol, Vector{Symbol}}[]
    order     = Symbol[]
    payoffs   = Dict{String, Dict{Symbol, Float64}}()
    traits    = GameTrait[]
    prov_notes = String[]
    in_payoff = false

    for (lineno, raw) in enumerate(split(text, "\n"))
        line = strip(raw)
        isempty(line) && continue

        # player Alice can [cooperate, defect]
        m = match(r"^player\s+(\w+)\s+can\s+\[([^\]]+)\]$", line)
        if m !== nothing
            name = Symbol(m[1])
            acts = [Symbol(strip(a)) for a in split(m[2], ",")]
            push!(players, name => acts)
            in_payoff = false
            continue
        end

        # Alice moves first / second / last
        m = match(r"^(\w+)\s+moves\s+\w+$", line)
        if m !== nothing
            push!(order, Symbol(m[1]))
            in_payoff = false
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
                key  = join(string.(acts), ".")
                payoffs[key] = Dict(players[i].first => vals[i]
                                    for i in 1:min(length(players), length(vals)))
                continue
            end
            in_payoff = false   # non-payoff line ends the block
        end

        # Alice commits to cooperate
        m = match(r"^(\w+)\s+commits\s+to\s+(\w+)$", line)
        if m !== nothing
            pid = Symbol(m[1]); aid = Symbol(m[2])
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

        error("strategic DSL line $lineno: unrecognised: $(repr(line))")
    end

    isempty(players) && error("strategic DSL: no players declared")

    # If sequential but only one player in order, append the remaining players
    if !isempty(order)
        declared = Set(order)
        for (pid, _) in players
            pid ∉ declared && push!(order, pid)
        end
    end

    actions = [Action(aid, string(aid), pid) for (pid, acts) in players for aid in acts]

    # Apply BurnedBridge filtering to the action list (mirrors from_jgdl behaviour)
    forbidden = Dict{Symbol, Vector{Symbol}}()
    for t in traits
        if t isa BurnedBridgeTrait
            push!(get!(forbidden, t.player_id, Symbol[]), t.forbidden_action)
        end
    end
    if !isempty(forbidden)
        actions = filter(a -> !(a.id in get(forbidden, a.player_id, Symbol[])), actions)
    end
    rationale = "World constructed via strategic() DSL." *
        (isempty(prov_notes) ? "" : " " * join(prov_notes, "; "))

    prov = [ProvenanceNode("initial_construction", "Chapter 1", rationale; parent_id = "")]
    for t in traits
        push!(prov, ProvenanceNode(
            "applied_trait", "Chapter 5",
            "Trait $(nameof(typeof(t))) applied via strategic() DSL";
            trait_type = string(nameof(typeof(t))),
            parent_id = ""
        ))
    end

    structure_type = isempty(order) ? "simultaneous" : "sequential"

    metadata = Dict{String, Any}(
        "actions"    => actions,
        "move_order" => order,
        "payoffs"    => Dict("type" => "terminal_matrix", "matrix" => payoffs),
        "structure"  => Dict("type" => structure_type),
    )

    StrategicWorld("sha256:" * "0"^64, _NullGame(), traits, prov, metadata)
end

# Keep @strategic as a thin wrapper for ergonomics — accepts a string literal only.
macro strategic(s::AbstractString)
    :(strategic($s))
end
macro strategic(s)
    error("@strategic requires a string literal. Use: @strategic \"\"\"...\"\"\"")
end
