using Test
using Strategic

# Trait-composition contract tests.
# See docs/trait-composition-contract.md for the normative contract.

@testset "Trait composition contract" begin

    @testset "Every shipped trait is registered" begin
        # Every concrete GameTrait loaded by the module must appear in
        # TRAIT_DISPATCH_TARGETS. Anything missing is either an unshipped
        # stub (acceptable) or a contract violation (not acceptable).
        concrete_traits = [
            Strategic.CommitmentTrait,
            Strategic.CredibleThreatTrait,
            Strategic.BurnedBridgeTrait,
            Strategic.MixedStrategyTrait,
            Strategic.BrinkmanshipTrait,
            Strategic.TournamentIncentiveTrait,
        ]
        for T in concrete_traits
            @test haskey(Strategic.TRAIT_DISPATCH_TARGETS, T)
        end
    end

    @testset "Declared targets are valid" begin
        for (T, targets) in Strategic.TRAIT_DISPATCH_TARGETS
            @test issubset(targets, Strategic.DISPATCH_TARGETS)
        end
    end

    @testset "overlapping_targets detects collisions" begin
        # Commitment + Tournament both override :payoff.
        commitment = Strategic.CommitmentTrait(:p1, :cooperate, 10.0)
        tournament = Strategic.TournamentIncentiveTrait(0.5)
        overlaps = Strategic.overlapping_targets([commitment, tournament])
        @test haskey(overlaps, :payoff)
        @test length(overlaps[:payoff]) == 2

        # CredibleThreat + BurnedBridge both override :available_actions.
        threat = Strategic.CredibleThreatTrait(:p1, :defect, :retaliate, 1.0)
        bridge = Strategic.BurnedBridgeTrait(:p1, :retreat)
        overlaps2 = Strategic.overlapping_targets([threat, bridge])
        @test haskey(overlaps2, :available_actions)
    end

    @testset "Non-colliding traits produce no overlap" begin
        # Commitment (:payoff) + BurnedBridge (:available_actions) are orthogonal.
        commitment = Strategic.CommitmentTrait(:p1, :cooperate, 10.0)
        bridge = Strategic.BurnedBridgeTrait(:p1, :retreat)
        @test isempty(Strategic.overlapping_targets([commitment, bridge]))
    end

    @testset "Order sensitivity for colliding traits" begin
        # Phase 1 skeleton: once solver lands, assert that (A, B) vs (B, A)
        # ordering produces different solutions for pairs known to not commute,
        # and identical solutions for pairs declared commutative.
        @test_skip "requires BackwardInduction solver (tasks.md 1.4)"
    end

    @testset "Provenance integrity across composition" begin
        # Every with_trait call must append a ProvenanceNode whose parent_id
        # is the world id before the call. Stacked traits produce a linear
        # provenance chain whose order matches the traits array.
        @test_skip "requires with_trait smoke test world (tasks.md 1.1)"
    end
end
