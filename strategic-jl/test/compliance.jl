using Test
using Strategic
using JSON3

const COMPLIANCE_SUITE = joinpath(@__DIR__, "..", "..", "jgdl", "compliance", "compliance_suite.json")

@testset "JGDL compliance suite" begin
    suite = JSON3.read(read(COMPLIANCE_SUITE, String))

    for case in suite["cases"]
        @testset "$(case["id"])" begin
            # Phase 0: cases are present but jgdl blocks may be nulls (skeletons).
            # Each phase fills in both the jgdl and the assertion that the
            # Julia implementation matches `expected`.
            if case["jgdl_ref"] === nothing
                @test_skip "case $(case["id"]) awaits jgdl block"
            else
                @test_skip "awaiting Phase 1 solver implementation"
            end
        end
    end
end
