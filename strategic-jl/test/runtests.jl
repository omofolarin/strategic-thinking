using Test
using Strategic

@testset "Strategic.jl" begin
    @testset "module loads" begin
        @test isdefined(Strategic, :StrategicWorld)
        @test isdefined(Strategic, :GameTrait)
        @test isdefined(Strategic, :ProvenanceNode)
    end

    include("composition.jl")
    include("compliance.jl")
end
