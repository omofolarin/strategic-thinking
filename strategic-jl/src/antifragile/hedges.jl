# Hedge portfolio: explicit bets on unknown-unknowns.
# A hedge activates when its trigger fires on an observation.

struct Hedge
    id::Symbol
    trigger::Function            # (ObservedPlay, State) -> Bool
    payoff_profile::Dict{Symbol, Float64}
    cost::Float64
    optionality_value::Float64
    chapter_ref::String
end

struct HedgeActivation
    hedge::Hedge
    observation::ObservedPlay
    provenance::Vector{ProvenanceNode}
end

"""
    evaluate_hedges(hedges, obs, state) -> Vector{HedgeActivation}

Check each hedge's trigger against the observation. Return activations
for every hedge that fires, each with a ProvenanceNode.
"""
function evaluate_hedges(
    hedges::Vector{Hedge},
    obs::ObservedPlay,
    state::State
)::Vector{HedgeActivation}
    activations = HedgeActivation[]
    for h in hedges
        h.trigger(obs, state) || continue
        prov = ProvenanceNode(
            "activated_hedge", h.chapter_ref,
            "Hedge :$(h.id) triggered by $(obs.player_id)→$(obs.action_taken). " *
            "Payoff profile: $(h.payoff_profile). " *
            "Optionality value: $(h.optionality_value)";
            parent_id = ""
        )
        push!(activations, HedgeActivation(h, obs, [prov]))
    end
    activations
end

"""
    parse_jgdl_hedges(hedge_list) -> Vector{Hedge}

Convert JGDL hedge dicts (from from_jgdl) into live Hedge structs.
Trigger expressions are parsed as simple keyword checks.
"""
function parse_jgdl_hedges(hedge_list::Vector)::Vector{Hedge}
    map(hedge_list) do h
        trigger_expr = get(h, "trigger", "")
        payoff_raw   = get(h, "payoff_profile", Dict())
        payoff = Dict(Symbol(k) => Float64(v) for (k, v) in payoff_raw)
        Hedge(
            Symbol(get(h, "id", "hedge")),
            _compile_trigger(trigger_expr),
            payoff,
            Float64(get(h, "cost", 0.0)),
            Float64(get(h, "optionality_value", 0.0)),
            get(h, "chapter_reference", "Chapter 1")
        )
    end
end

# Compile a simple trigger expression string into a Julia function.
# Supports: "action_id == X", "prior_rounds_cooperative >= N", AND combinations.
function _compile_trigger(expr::String)::Function
    clauses = split(expr, " AND ")
    checks = Function[]
    for clause in clauses
        clause = strip(clause)
        # Pattern: "p2_action == defect_2"  →  obs.action_taken == :defect_2
        m = match(r"(\w+)_action\s*==\s*(\w+)", clause)
        if m !== nothing
            pid = Symbol(m[1]); aid = Symbol(m[2])
            push!(checks, let pid=pid, aid=aid
                (obs, state) -> obs.player_id == pid && obs.action_taken == aid
            end)
            continue
        end
        # Pattern: "prior_rounds_cooperative >= 3"  →  state.variables["prior_rounds_cooperative"] >= 3
        m = match(r"(\w+)\s*(>=|<=|==|>|<)\s*(\d+)", clause)
        if m !== nothing
            key = m[1]; op = m[2]; val = parse(Int, m[3])
            push!(checks, let key=key, op=op, val=val
                (obs, state) -> begin
                    v = get(state.variables, Symbol(key), get(state.variables, key, 0))
                    op == ">=" ? v >= val :
                    op == "<=" ? v <= val :
                    op == ">"  ? v >  val :
                    op == "<"  ? v <  val : v == val
                end
            end)
            continue
        end
    end
    isempty(checks) && return (obs, state) -> false
    (obs, state) -> all(c(obs, state) for c in checks)
end
