struct NashEquilibrium <: SolverMethod end

struct MixedNashResult
    pure_nash::Vector{Tuple{Symbol, Symbol}}
    mixed_equilibrium::Union{Dict{Symbol, Dict{Symbol, Float64}}, Nothing}
    expected_payoffs::Dict{Symbol, Float64}
    provenance::Vector{ProvenanceNode}
end

"""
    solve(world, ::NashEquilibrium) -> MixedNashResult

Find all Nash equilibria for a 2×2 simultaneous game:
  1. Pure Nash equilibria (best-response enumeration)
  2. Mixed Nash equilibrium via indifference equations

Mixed equilibrium: each player randomises so the opponent is indifferent
between their actions. For player 2 to be indifferent:
  U₁(a₁, p) = U₁(a₂, p)  →  solve for p (player 1's mix probability)

For a 2×2 game with payoffs:
  (a,c)→(A,E)  (a,d)→(B,F)
  (b,c)→(C,G)  (b,d)→(D,H)

Player 2 indifferent when:
  p×E + (1-p)×G = p×F + (1-p)×H  →  p = (H-G)/(E-F-G+H)

Player 1 indifferent when:
  q×A + (1-q)×B = q×C + (1-q)×D  →  q = (D-B)/(A-C-B+D)
"""
function solve(world::StrategicWorld, ::NashEquilibrium)::MixedNashResult
    matrix  = get(get(world.metadata, "payoffs", Dict()), "matrix", Dict())
    actions = get(world.metadata, "actions", Action[])
    prov    = ProvenanceNode[]

    players = unique(a.player_id for a in actions)
    length(players) != 2 && error("NashEquilibrium: supports 2-player games only")
    p1, p2 = players[1], players[2]
    p1_acts = [a for a in actions if a.player_id == p1]
    p2_acts = [a for a in actions if a.player_id == p2]
    length(p1_acts) != 2 || length(p2_acts) != 2 &&
        error("NashEquilibrium mixed solver: supports 2×2 games only")

    a1, a2 = p1_acts[1].id, p1_acts[2].id
    c1, c2 = p2_acts[1].id, p2_acts[2].id

    # Payoff lookup helper
    pf(r, c) = begin
        raw = _lookup_payoff_dict(matrix, "$(r).$(c)")
        raw === nothing ? Dict{Symbol,Float64}() :
            Dict(Symbol(k) => Float64(v) for (k,v) in raw)
    end

    A = get(pf(a1,c1), p1, 0.0); E = get(pf(a1,c1), p2, 0.0)
    B = get(pf(a1,c2), p1, 0.0); F = get(pf(a1,c2), p2, 0.0)
    C = get(pf(a2,c1), p1, 0.0); G = get(pf(a2,c1), p2, 0.0)
    D = get(pf(a2,c2), p1, 0.0); H = get(pf(a2,c2), p2, 0.0)

    # Pure Nash
    pure = Tuple{Symbol,Symbol}[]
    for r in [a1, a2], c in [c1, c2]
        p1_val = get(pf(r,c), p1, 0.0)
        p2_val = get(pf(r,c), p2, 0.0)
        other_r = r == a1 ? a2 : a1
        other_c = c == c1 ? c2 : c1
        p1_br = p1_val >= get(pf(other_r, c), p1, 0.0)
        p2_br = p2_val >= get(pf(r, other_c), p2, 0.0)
        p1_br && p2_br && push!(pure, (r, c))
    end

    push!(prov, ProvenanceNode("pure_nash_search","Chapter 7",
        "Found $(length(pure)) pure Nash equilibria: $(pure)"; parent_id=""))

    # Mixed Nash via indifference equations
    mixed = nothing
    exp_payoffs = Dict{Symbol,Float64}()

    denom_p = E - F - G + H
    denom_q = A - C - B + D

    if abs(denom_p) > 1e-10 && abs(denom_q) > 1e-10
        p = (H - G) / denom_p   # prob p1 plays a1
        q = (D - B) / denom_q   # prob p2 plays c1

        if 0 <= p <= 1 && 0 <= q <= 1
            mixed = Dict(
                p1 => Dict(a1 => p,   a2 => 1-p),
                p2 => Dict(c1 => q,   c2 => 1-q)
            )
            # Expected payoffs at mixed equilibrium
            exp_p1 = p*q*A + p*(1-q)*B + (1-p)*q*C + (1-p)*(1-q)*D
            exp_p2 = p*q*E + p*(1-q)*F + (1-p)*q*G + (1-p)*(1-q)*H
            exp_payoffs = Dict(p1 => exp_p1, p2 => exp_p2)

            push!(prov, ProvenanceNode("mixed_nash_equilibrium","Chapter 7",
                "Mixed NE: $(p1) plays $(a1) with p=$(round(p;digits=4)), " *
                "$(p2) plays $(c1) with q=$(round(q;digits=4)). " *
                "Expected payoffs: $(p1)=$(round(exp_p1;digits=4)), $(p2)=$(round(exp_p2;digits=4)).";
                parent_id="",
                theoretical_origin="Von Neumann & Morgenstern, Theory of Games (1944)"))
        end
    end

    if mixed === nothing && isempty(pure)
        push!(prov, ProvenanceNode("no_nash","Chapter 7",
            "No pure or mixed Nash equilibrium found in [0,1]"; parent_id=""))
    end

    MixedNashResult(pure, mixed, exp_payoffs, prov)
end
