using Test
using Strategic
using JSON

const COMPLIANCE_SUITE = joinpath(@__DIR__, "..", "..", "jgdl", "compliance", "compliance_suite.json")

@testset "JGDL compliance suite" begin
    suite = JSON.parsefile(COMPLIANCE_SUITE)

    for case in suite["cases"]
        @testset "$(case["id"])" begin
            if case["jgdl_ref"] === nothing
                @test_skip "case $(case["id"]) awaits jgdl block"
            else
                @test_skip "awaiting Phase 1 solver implementation"
            end
        end
    end
end
