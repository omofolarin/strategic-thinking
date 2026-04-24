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

    @testset "provenance non-empty" begin
        world = strategic("""
            player p1 can [a, b]
            player p2 can [a, b]
            payoff:
                (a, a) => (1, 1)
                (a, b) => (0, 2)
                (b, a) => (2, 0)
                (b, b) => (0, 0)
        """)
        @test !isempty(world.provenance)
        @test world.provenance[1].operation == "initial_construction"
    end
end
