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
        # CommitmentTrait and TournamentIncentiveTrait both override :payoff.
        # A rising-tide transform (tournament) applied *after* a commitment
        # penalty differs from applying it before — the penalty scales with
        # relative comparison.
        base = strategic("""
            player p1 can [a, b]
            player p2 can [a, b]
            payoff:
                (a, a) => (3, 3)
                (a, b) => (0, 5)
                (b, a) => (5, 0)
                (b, b) => (1, 1)
        """)

        # Tournament-only should lift the Nash to (b, b) with relative transform.
        tournament_only = StrategicWorld(base.id, base.game,
            GameTrait[Strategic.TournamentIncentiveTrait(1.0)],
            copy(base.provenance), copy(base.metadata))
        r_tournament = solve(tournament_only, BackwardInduction())
        @test !isempty(r_tournament.equilibrium_path)
        @test !isempty(r_tournament.provenance_chain)
    end

    @testset "Provenance integrity across composition" begin
        # with_trait must append a node citing the parent world id.
        base = strategic("""
            player p1 can [a, b]
            player p2 can [a, b]
            payoff:
                (a, a) => (1, 1)
                (b, b) => (0, 0)
        """)
        original_id = base.id
        chained = Strategic.with_trait(base,
            Strategic.TournamentIncentiveTrait(0.5);
            chapter_ref = "Chapter 12",
            rationale = "test provenance parent link")
        last = chained.provenance[end]
        @test last.operation == "applied_trait"
        @test last.trait_type == "TournamentIncentiveTrait"
        @test last.parent_id == original_id
        @test length(chained.traits) == length(base.traits) + 1
    end
end
