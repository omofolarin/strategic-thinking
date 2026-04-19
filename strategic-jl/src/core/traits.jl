# Trait composition via wrapper types.
#
# Every trait is a value, not a mutation. A world with N traits becomes
# WithTrait{WithTrait{...{BaseGame, T1}, T2}..., TN}. Multiple dispatch
# resolves behavior by walking the type stack.
#
# Invariant: no Solution may leave a trait layer without appending a
# ProvenanceNode citing which trait applied and why.

struct WithTrait{G<:AbstractGame, T<:GameTrait} <: AbstractGame
    inner::G
    trait::T
end

# Default fallback: delegate unhandled messages to the inner game.
# Each chapter trait overrides the functions it meaningfully changes.

available_actions(g::AbstractGame, state::State, player::Player) =
    error("available_actions not implemented for $(typeof(g))")

payoff(g::AbstractGame, state::State) =
    error("payoff not implemented for $(typeof(g))")

available_actions(g::WithTrait, state::State, player::Player) =
    available_actions(g.inner, state, player)

payoff(g::WithTrait, state::State) = payoff(g.inner, state)

function with_trait(world::StrategicWorld, trait::GameTrait;
                    chapter_ref::String, rationale::String)
    new_game = WithTrait(world.game, trait)
    new_world = StrategicWorld(world.id, new_game,
                               vcat(world.traits, [trait]),
                               copy(world.provenance),
                               copy(world.metadata))
    append_provenance!(new_world, ProvenanceNode(
        "applied_trait_$(typeof(trait))",
        chapter_ref,
        rationale;
        parent_id = world.id
    ))
    new_world
end

# ----------------------------------------------------------------------
# Trait-composition contract (see docs/trait-composition-contract.md)
#
# TRAIT_DISPATCH_TARGETS is the normative registry: every concrete
# GameTrait must appear here with the exact set of dispatch targets it
# overrides. A load-time check validates that no trait silently extends
# beyond its declaration.
# ----------------------------------------------------------------------

const DISPATCH_TARGETS = Set([
    :available_actions,
    :payoff,
    :transition,
    :sample_action,
    :select_equilibrium,
    :update_beliefs,
    :aggregate,
])

"""
    TRAIT_DISPATCH_TARGETS

Per-trait declaration of which dispatch functions the trait overrides.
Populated via `register_trait!(T, targets)` from each chapter file as
traits land. See docs/trait-composition-contract.md §5.
"""
const TRAIT_DISPATCH_TARGETS = Dict{Type{<:GameTrait}, Set{Symbol}}()

function register_trait!(T::Type{<:GameTrait}, targets::Set{Symbol})
    unknown = setdiff(targets, DISPATCH_TARGETS)
    isempty(unknown) ||
        error("Trait $T declares unknown dispatch targets: $unknown. " *
              "Add to DISPATCH_TARGETS in core/traits.jl only after updating " *
              "docs/trait-composition-contract.md §2.")
    TRAIT_DISPATCH_TARGETS[T] = targets
    nothing
end

"""
    overlapping_targets(traits) -> Dict{Symbol, Vector{Type}}

For a stack of traits, return which dispatch targets are touched by
more than one trait. Used by the composition test to require explicit
order declarations for colliding traits.
"""
function overlapping_targets(traits::Vector)
    hits = Dict{Symbol, Vector{Type}}()
    for t in traits
        T = typeof(t)
        targets = get(TRAIT_DISPATCH_TARGETS, T, Set{Symbol}())
        for target in targets
            push!(get!(hits, target, Type[]), T)
        end
    end
    filter!(p -> length(p.second) > 1, hits)
    hits
end
