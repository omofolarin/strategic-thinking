using Test
using Strategic

@testset "Repeated game solver (Chapter 4)" begin
    # Stage-game prisoner's dilemma
    function pd_world()
        strategic("""
            player p1 can [cooperate, defect]
            player p2 can [cooperate, defect]
            payoff:
                (cooperate, cooperate) => (3, 3)
                (cooperate, defect)    => (0, 5)
                (defect,    cooperate) => (5, 0)
                (defect,    defect)    => (1, 1)
        """)
    end

    @testset "TFT vs TFT cooperates under high discount" begin
        world = pd_world()
        result = simulate(world,
            Dict(:p1 => TitForTat(:p2), :p2 => TitForTat(:p1));
            horizon = 20, discount_factor = 0.95)
        # Every round should be (cooperate, cooperate) because TFT cooperates first
        # and then mirrors a cooperator forever.
        @test all(r -> r[:p1] == :cooperate && r[:p2] == :cooperate, result.trajectory)
        # Discounted payoff approaches 3 / (1 - δ) for each player.
        expected_p1 = sum(0.95^t * 3 for t in 0:19)
        @test result.discounted_payoffs[:p1] ≈ expected_p1 atol = 1e-9
    end

    @testset "TFT vs AlwaysDefect converges to mutual defection" begin
        world = pd_world()
        result = simulate(world,
            Dict(:p1 => TitForTat(:p2), :p2 => AlwaysDefect(:p1));
            horizon = 10, discount_factor = 0.9)
        # Round 0: p1 cooperates, p2 defects → (0, 5)
        @test result.trajectory[1][:p1] == :cooperate
        @test result.trajectory[1][:p2] == :defect
        # Round 1+: TFT mirrors defect → mutual defection for the rest.
        @test all(r -> r[:p1] == :defect && r[:p2] == :defect, result.trajectory[2:end])
    end

    @testset "GrimTrigger retaliates forever after first defection" begin
        world = pd_world()
        result = simulate(world,
            Dict(:p1 => GrimTrigger(:p2), :p2 => AlwaysDefect(:p1));
            horizon = 5, discount_factor = 0.9)
        # Grim cooperates round 0; then defects forever after seeing defect.
        @test result.trajectory[1][:p1] == :cooperate
        @test all(r -> r[:p1] == :defect, result.trajectory[2:end])
    end

    @testset "Provenance chain cites Chapter 4 and Axelrod" begin
        world = pd_world()
        result = simulate(world,
            Dict(:p1 => TitForTat(:p2), :p2 => TitForTat(:p1));
            horizon = 5)
        @test !isempty(result.provenance_chain)
        @test all(n -> n.chapter_ref == "Chapter 4", result.provenance_chain)
        @test any(
            n -> n.theoretical_origin !== nothing &&
                 occursin("Axelrod", n.theoretical_origin),
            result.provenance_chain)
        @test any(n -> n.operation == "cooperation_emerged", result.provenance_chain)
    end
end

@testset "IteratedDominance returns RationalizableSet" begin
    # A 3x3 game where one action is strictly dominated for each player.
    # p1: :c is dominated by :a regardless of p2's move.
    # Payoffs chosen so that :b is NOT dominated by :a (rules out unintended extra eliminations).
    world = strategic("""
        player p1 can [a, b, c]
        player p2 can [x, y, z]
        payoff:
            (a, x) => (5, 1)
            (a, y) => (4, 1)
            (a, z) => (3, 1)
            (b, x) => (6, 1)
            (b, y) => (2, 1)
            (b, z) => (3, 1)
            (c, x) => (1, 1)
            (c, y) => (1, 1)
            (c, z) => (2, 1)
    """)
    r = solve(world, IteratedDominance())
    @test r isa IteratedDominanceResult
    p1_set = first(s for s in r.sets if s.player_id == :p1)
    @test :c ∉ p1_set.surviving_actions
    @test :a ∈ p1_set.surviving_actions
    @test !isempty(r.provenance_chain)
    @test any(n -> n.operation == "eliminated_dominated_action", r.provenance_chain)
end
