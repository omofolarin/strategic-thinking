# Chapter 9: Cooperation and Coordination — Schelling focal points.

struct CoordinationDeviceTrait <: GameTrait
    focal_action::Symbol
    salience::Float64
end

register_trait!(CoordinationDeviceTrait, Set([:select_equilibrium]))

"""
    solve_with_focal(world, equilibria) -> Solution

Post-process a list of Nash equilibria by selecting the focal one.
The focal equilibrium is the one where any player's action matches
the CoordinationDeviceTrait's focal_action. If no equilibrium matches,
returns the first one (arbitrary selection with provenance note).
"""
function solve_with_focal(world::StrategicWorld, base_solution::Solution)::Solution
    focal_trait = findfirst(t -> t isa CoordinationDeviceTrait, world.traits)
    focal_trait === nothing && return base_solution

    t = world.traits[focal_trait]
    path = base_solution.equilibrium_path

    # Check if current equilibrium already uses the focal action
    uses_focal = any(
        a -> a.id == t.focal_action ||
             endswith(string(a.id), string(t.focal_action)), path)

    prov = vcat(base_solution.provenance_chain,
        [ProvenanceNode(
            "applied_trait", "Chapter 9",
            uses_focal ?
            "Focal equilibrium selected: $(t.focal_action) is salient (salience=$(t.salience)). " *
            "Schelling: without communication, players converge on the culturally obvious option." :
            "No equilibrium uses focal action $(t.focal_action); returning base equilibrium.";
            trait_type = "CoordinationDevice",
            parent_id = "",
            theoretical_origin = "Schelling, The Strategy of Conflict (1960), Chapter 3"
        )])

    Solution(path, base_solution.payoffs, prov)
end
