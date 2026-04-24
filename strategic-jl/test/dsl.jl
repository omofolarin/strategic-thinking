using Test
using Strategic

@testset "DSL — strategic()" begin
    @testset "simultaneous PD" begin
        world = strategic("""
            player p1 can [cooperate, defect]
            player p2 can [cooperate, defect]
            payoff:
                (cooperate, cooperate) => (3, 3)
                (cooperate, defect)    => (0, 5)
                (defect,    cooperate) => (5, 0)
                (defect,    defect)    => (1, 1)
        """)
        r = solve(world, BackwardInduction())
        @test map(a -> a.id, r.equilibrium_path) == [:defect, :defect]
        @test r.payoffs[:p1] == 1.0
    end

    @testset "sequential entry game" begin
        world = strategic("""
            player entrant   can [enter, stay_out]
            player incumbent can [fight, accommodate]
            entrant moves first
            payoff:
                (enter,    fight)       => (-10, -20)
                (enter,    accommodate) => (40,   30)
                (stay_out, fight)       => (0,   100)
                (stay_out, accommodate) => (0,   100)
        """)
        r = solve(world, BackwardInduction())
        @test r.equilibrium_path[1].id == :enter
        @test r.payoffs[:entrant] == 40.0
    end

    @testset "burned bridge → stay out" begin
        world = strategic("""
            player entrant   can [enter, stay_out]
            player incumbent can [fight, accommodate]
            entrant moves first
            incumbent burns bridge: accommodate
            payoff:
                (enter,    fight)       => (-10, -20)
                (enter,    accommodate) => (40,   30)
                (stay_out, fight)       => (0,   100)
                (stay_out, accommodate) => (0,   100)
        """)
        r = solve(world, BackwardInduction())
        @test r.equilibrium_path[1].id == :stay_out
        @test r.payoffs[:incumbent] == 100.0
    end

    @testset "metadata: name and chapter" begin
        world = strategic("""
            name: Test World
            chapter: Chapter 2
            player p1 can [a, b]
            player p2 can [a, b]
            payoff:
                (a, a) => (1, 1)
                (b, b) => (0, 0)
        """)
        @test world.metadata["name"] == "Test World"
        @test "Chapter 2" in world.metadata["chapter_references"]
    end

    @testset "player parameters" begin
        world = strategic("""
            player p1 can [a, b]
            player p2 can [a, b]
            p1 rationality: 0.8
            p1 risk_aversion: 1.5
            payoff:
                (a, a) => (1, 1)
                (b, b) => (0, 0)
        """)
        params = world.metadata["player_params"]
        @test params[:p1][:rationality_factor] == 0.8
        @test params[:p1][:risk_aversion] == 1.5
    end

    @testset "repeated structure" begin
        world = strategic("""
            player p1 can [cooperate, defect]
            player p2 can [cooperate, defect]
            repeated, infinite, discount 0.9
            payoff:
                (cooperate, cooperate) => (3, 3)
                (defect,    defect)    => (1, 1)
        """)
        s = world.metadata["structure"]
        @test s["type"] == "repeated"
        @test s["repetitions"] == "infinite"
        @test s["discount_factor"] == 0.9
    end

    @testset "mixed strategy trait" begin
        world = strategic("""
            player row can [heads, tails]
            player col can [heads, tails]
            row mixes: heads 0.5, tails 0.5
            payoff:
                (heads, heads) => (1, -1)
                (heads, tails) => (-1, 1)
                (tails, heads) => (-1, 1)
                (tails, tails) => (1, -1)
        """)
        @test any(t -> t isa MixedStrategyTrait, world.traits)
        t = first(t for t in world.traits if t isa MixedStrategyTrait)
        @test t.distribution[:heads] == 0.5
    end

    @testset "brinkmanship trait" begin
        world = strategic("""
            player p1 can [escalate, back_down]
            player p2 can [escalate, back_down]
            escalate carries 10% catastrophe: (-1000, -1000)
            payoff:
                (escalate,  escalate)  => (-100, -100)
                (escalate,  back_down) => (10,    -5)
                (back_down, escalate)  => (-5,    10)
                (back_down, back_down) => (0,      0)
        """)
        @test any(t -> t isa BrinkmanshipTrait, world.traits)
        t = first(t for t in world.traits if t isa BrinkmanshipTrait)
        @test t.catastrophe_probability == 0.1
        @test t.catastrophic_payoff[:p1] == -1000.0
    end

    @testset "provenance non-empty with correct chapter" begin
        world = strategic("""
            player p1 can [a, b]
            player p2 can [a, b]
            p1 mixes: a 0.6, b 0.4
            payoff:
                (a, a) => (1, 1)
                (b, b) => (0, 0)
        """)
        @test !isempty(world.provenance)
        @test world.provenance[1].operation == "initial_construction"
        mixed_prov = filter(p -> p.trait_type == "MixedStrategyTrait", world.provenance)
        @test !isempty(mixed_prov)
        @test mixed_prov[1].chapter_ref == "Chapter 7"
    end
end
