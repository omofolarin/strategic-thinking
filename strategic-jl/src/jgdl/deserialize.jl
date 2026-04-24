"""
    from_jgdl(json) -> StrategicWorld

Deserialize a JGDL document into a StrategicWorld. Accepts either a JSON
string or an already-parsed dict. Validates against v1.0.0 schema.
"""
from_jgdl(json_str::AbstractString)::StrategicWorld = from_jgdl(JSON.parse(json_str))

function from_jgdl(doc::AbstractDict)::StrategicWorld
    errors = validate_jgdl(doc)
    isempty(errors) || error("JGDL validation failed: $(errors[1].message)")
    w = doc["world"]
    provenance = [_dict_to_provenance(p) for p in get(w, "provenance", [])]

    raw_payoffs = get(w, "payoffs", Dict())
    # Normalize inner-dict keys to Symbol so solvers can use `get(pf, :p1, …)` uniformly.
    payoffs = _normalize_payoffs(raw_payoffs)

    metadata = Dict{String, Any}(
        "players" => get(w, "players", []),
        "structure" => get(w, "structure", Dict()),
        "payoffs" => payoffs,
        "initial_state" => get(w, "initial_state", Dict()),
        "move_order" => _extract_order(w),
        "actions_raw" => get(w, "actions", []),
        "players_raw" => get(w, "players", [])
    )
    for (k, v) in get(w, "metadata", Dict())
        metadata[k] = v
    end

    actions = [Action(Symbol(a["id"]), get(a, "name", a["id"]), Symbol(a["player_id"]))
               for a in get(w, "actions", [])]
    metadata["actions"] = actions

    # Hedges (antifragile extension) pass through verbatim so
    # parse_jgdl_hedges can compile them on demand.
    haskey(w, "hedges") && (metadata["hedges"] = w["hedges"])

    traits = _parse_traits(get(w, "traits", []))

    # Trait-derived metadata lookups (solvers that read from metadata, not from
    # the trait object directly).
    for t in get(w, "traits", [])
        ttype = get(t, "type", "")
        params = get(t, "parameters", Dict())
        if ttype == "VotingRule"
            prefs = get(params, "preferences", nothing)
            prefs === nothing && continue
            metadata["preferences"] = Dict(
                string(k) => [string(x) for x in v] for (k, v) in prefs)
        elseif ttype == "BargainingProtocol"
            haskey(params, "discount_factor") &&
                (metadata["structure"] = merge(get(metadata, "structure", Dict()),
                    Dict("discount_factor" => Float64(params["discount_factor"]))))
            haskey(params, "surplus") && (metadata["surplus"] = Float64(params["surplus"]))
            haskey(params, "pie") && (metadata["surplus"] = Float64(params["pie"]))
        elseif ttype == "BayesianBelief"
            # Capture prior type so the BayesianNashSolver can cite it.
            haskey(params, "value_distribution") &&
                (metadata["prior_distribution"] = string(params["value_distribution"]))
        end
    end

    # BurnedBridge pre-filters the action list so solvers that read raw
    # metadata still see the correct available set.
    forbidden = Dict{Symbol, Vector{Symbol}}()
    for t in traits
        if t isa BurnedBridgeTrait
            push!(get!(forbidden, t.player_id, Symbol[]), t.forbidden_action)
        end
    end
    if !isempty(forbidden)
        metadata["forbidden_actions"] = forbidden
        metadata["actions"] = filter(
            a -> !(a.id in get(forbidden, a.player_id, Symbol[])), actions)
    end

    StrategicWorld(get(w, "id", ""), _NullGame(), traits, provenance, metadata)
end

# --- Trait parsing -------------------------------------------------------

function _parse_traits(raw_traits)::Vector{GameTrait}
    out = GameTrait[]
    for t in raw_traits
        ttype = get(t, "type", "")
        params = get(t, "parameters", Dict())
        parsed = _parse_single_trait(ttype, params)
        parsed !== nothing && push!(out, parsed)
    end
    out
end

function _parse_single_trait(ttype::AbstractString, params::AbstractDict)
    if ttype == "BurnedBridge"
        BurnedBridgeTrait(Symbol(get(params, "player_id", "")),
            Symbol(get(params, "forbidden_action", "")))
    elseif ttype == "Commitment"
        CommitmentTrait(Symbol(get(params, "player_id", "")),
            Symbol(get(params, "committed_action", "")),
            Float64(get(params, "penalty_for_deviation", 100.0)))
    elseif ttype == "CredibleThreat"
        CredibleThreatTrait(
            Symbol(get(params, "threatener_id",
                get(params, "player_id", ""))),
            Symbol(get(params, "trigger_action", "")),
            Symbol(get(params, "retaliation_action", "")),
            Float64(get(params, "credibility", 1.0)))
    elseif ttype == "MixedStrategy"
        dist = Dict{Symbol, Float64}()
        for (k, v) in get(params, "distribution", Dict())
            dist[Symbol(k)] = Float64(v)
        end
        MixedStrategyTrait(Symbol(get(params, "player_id", "")), dist)
    elseif ttype == "Brinkmanship"
        catp = Dict{Symbol, Float64}()
        for (k, v) in get(params, "catastrophe_payoff",
            get(params, "catastrophic_payoff", Dict()))
            catp[Symbol(k)] = Float64(v)
        end
        BrinkmanshipTrait(
            Symbol(get(params, "trigger_action",
                get(params, "risky_action", ""))),
            Float64(get(params, "catastrophe_probability", 0.0)),
            catp)
    elseif ttype == "TournamentIncentive"
        w = Float64(get(params, "weight_on_relative", get(params, "weight", 1.0)))
        TournamentIncentiveTrait(w)
    elseif ttype == "CoordinationDevice"
        focal = get(params, "focal_action", "")
        sal_raw = get(params, "salience", 1.0)
        salience = sal_raw isa Number ? Float64(sal_raw) : 1.0
        CoordinationDeviceTrait(Symbol(focal), salience)
    elseif ttype == "VotingRule"
        rule = Symbol(get(params, "rule", "majority"))
        VotingRuleTrait(rule, length(get(params, "preferences", Dict())))
    elseif ttype == "BargainingProtocol"
        BargainingProtocolTrait(
            Symbol[Symbol(x) for x in get(params, "players_order", String[])],
            Float64(get(params, "pie", get(params, "surplus", 100.0))),
            Float64(get(params, "discount_factor", 0.9)))
    elseif ttype == "BayesianBelief"
        # Store a placeholder trait; actual distribution handled out-of-band
        # for the closed-form solver.
        nothing
    else
        nothing
    end
end

function _normalize_payoffs(raw::AbstractDict)
    mat = get(raw, "matrix", nothing)
    mat === nothing && return raw
    new_matrix = Dict{String, Dict{Symbol, Float64}}()
    for (k, v) in mat
        inner = Dict{Symbol, Float64}()
        for (ik, iv) in v
            inner[Symbol(ik)] = Float64(iv)
        end
        new_matrix[string(k)] = inner
    end
    # Preserve any siblings (type, function, etc.)
    out = Dict{String, Any}()
    for (k, v) in raw
        out[k] = v
    end
    out["matrix"] = new_matrix
    out
end

function _extract_order(w::AbstractDict)
    structure = get(w, "structure", Dict())
    order = get(structure, "order", nothing)
    order === nothing && return Symbol[]
    [Symbol(id) for id in order]
end

function _dict_to_provenance(d::AbstractDict)::ProvenanceNode
    ProvenanceNode(
        get(d, "id", nothing),
        d["operation"],
        get(d, "trait_type", nothing),
        d["chapter_ref"],
        get(d, "theoretical_origin", nothing),
        d["rationale"],
        d["parent_id"],
        now(),   # timestamp not round-tripped for simplicity
        Symbol(d["author"])
    )
end

# Minimal concrete game type for deserialized worlds (no live dispatch needed)
struct _NullGame <: AbstractGame end
available_actions(::_NullGame, ::State, ::Player) = Action[]
payoff(::_NullGame, ::State) = Dict{Symbol, Float64}()
