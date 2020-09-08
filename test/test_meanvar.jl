module TestMeanVar

using DataTools
using DataTools: MeanVarState
using Statistics
using Test
using Transducers: Filter, Map, TeeRF

include("utils.jl")

reduce_bs1(args...; kw...) = reduce(args...; basesize = 1, kw...)

@testset for fold in [foldl, reduce_bs1, reduce]
    foldl = reduce = nothing

    @testset "accessors" begin
        s = fold(meanvar, Filter(isodd), 1:16)
        m, v, c = s
        @test Tuple(s) == (m, v, c) == (8.0, 24.0, 8)
        @test NamedTuple(s) == (mean = m, var = v, count = c)

        s = fold(meanvar, Filter(isodd), 1:10)
        @test mean(s) === mean(1:2:9) === 5.0
        @test var(s) === var(1:2:9) === var(s; corrected = true) === 10.0
        @test var(s; corrected = false) === var(1:2:9; corrected = false) === 8.0

        s = fold(meanvar, Filter(isodd), 1:96)
        @test mean(s) === mean(1:2:95) === 48.0
        @test var(s) === var(1:2:95) === 784.0
        @test std(s) === std(1:2:95) === 28.0
    end

    @testset "TeeRF" begin
        s1, s2 = fold(
            TeeRF(Filter(isodd)'(meanvar), Filter(iseven)'(meanvar)),
            Map(identity),
            1:96,
        )
        @test s1 isa MeanVarState
        @test s2 isa MeanVarState
        @test mean(s1) === 48.0
        @test mean(s2) === 49.0
        @test var(s1) === 784.0
        @test var(s2) === 784.0
    end

    @testset "oncol" begin
        snt = fold(
            oncol(odd = meanvar, even = meanvar),
            Map(x -> (odd = 2x - 1, even = 2x)),
            1:48,
        )
        @test snt.odd isa MeanVarState
        @test snt.even isa MeanVarState
        @test mean(snt.odd) === 48.0
        @test mean(snt.even) === 49.0
        @test var(snt.odd) === 784.0
        @test var(snt.even) === 784.0
    end
end

@testset "show and constructor" begin
    @testset "default type parameters" begin
        s = MeanVarState(mean = 8.0, count = 8, m2 = 168.0)
        @test s === MeanVarState(mean = 8.0, var = 24.0, count = 8)
        str = sprint(show, s; context = :limit => true)
        @test str == "MeanVarState(mean=8.0, var=24.0, count=8)"
        str = sprint(show, s; context = :limit => false)
        @test str == "DataTools.MeanVarState(mean=8.0, var=24.0, count=8, m2=168.0)"
    end

    @testset "non-default type parameters" begin
        s = MeanVarState{Any,Any,Any}(mean = 8.0, var = 24.0, count = 8)
        str = sprint(show, s; context = :limit => true)
        @test str ==ᵣ "MeanVarState{Any,Any,Any}(mean=8.0, var=24.0, count=8)"
        str = sprint(show, s; context = :limit => false)
        @test str ==ᵣ
              "DataTools.MeanVarState{Any,Any,Any}(mean=8.0, var=24.0, count=8, m2=168.0)"
    end
end

end  # module
