using Test
using Strategic
using JSON

const COMPLIANCE_SUITE = joinpath(@__DIR__, "..", "..", "jgdl", "compliance", "compliance_suite.json")
const TESTS_DIR = joinpath(@__DIR__, "..", "..", "jgdl", "compliance", "tests")

@testset "JGDL compliance suite" begin
    suite = JSON.parsefile(COMPLIANCE_SUITE)

    for case in suite["cases"]
        @testset "$(case["id"])" begin
            if case["test_path"] === nothing
                @test_skip "case $(case["id"]) awaits jgdl block"
            else
                test_file = joinpath(dirname(COMPLIANCE_SUITE), case["test_path"])
                doc = JSON.parsefile(test_file)
                errors = validate_jgdl(doc["jgdl"])
                if !isempty(errors)
                    @error "Schema validation failed" case=case["id"] errors=map(e -> e.message, errors)
                end
                @test isempty(errors)
                # Phase 1+: solver assertions go here once solvers are implemented
                @test_skip "awaiting Phase 1 solver implementation"
            end
        end
    end
end
