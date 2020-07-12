module TestMeanVar

using DataTools
using DataTools: MeanVarState
using Statistics
using Test
using Transducers: Filter, Map, TeeRF, skipcomplete

reduce_bs1(args...; kw...) = reduce(args...; basesize = 1, kw...)

@testset for fold in [foldl, reduce_bs1, reduce]
    foldl = reduce = nothing

    @test fold(meanvar, Filter(isodd), 1:16) == (8.0, 24.0)

    @testset "skipcomplete" begin
        s = fold(skipcomplete(meanvar), Filter(isodd), 1:10)
        @test mean(s) === mean(1:2:9) === 5.0
        @test var(s) === var(1:2:9) === var(s; corrected = true) === 10.0
        @test var(s; corrected = false) === var(1:2:9; corrected = false) === 8.0

        s = fold(skipcomplete(meanvar), Filter(isodd), 1:96)
        @test mean(s) === mean(1:2:95) === 48.0
        @test var(s) === var(1:2:95) === 784.0
        @test std(s) === std(1:2:95) === 28.0
    end

    @testset "skipcomplete in TeeRF" begin
        s1, s2 = fold(
            TeeRF(
                Filter(isodd)'(skipcomplete(meanvar)),
                Filter(iseven)'(skipcomplete(meanvar)),
            ),
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

    @testset "TeeRF in skipcomplete" begin
        s1, s2 = fold(
            skipcomplete(TeeRF(Filter(isodd)'(meanvar), Filter(iseven)'(meanvar))),
            Map(identity),
            1:96,
        )
        @test_broken s1 isa MeanVarState
        @test_broken s2 isa MeanVarState
        @test_broken mean(s1) === 48.0
        @test_broken mean(s2) === 49.0
        @test_broken var(s1) === 784.0
        @test_broken var(s2) === 784.0
    end

    @testset "skipcomplete in oncol" begin
        snt = fold(
            oncol(odd = skipcomplete(meanvar), even = skipcomplete(meanvar)),
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

    @testset "oncol in skipcomplete" begin
        snt = fold(
            skipcomplete(oncol(odd = meanvar, even = meanvar)),
            Map(x -> (odd = 2x - 1, even = 2x)),
            1:48,
        )
        @test_broken snt.odd isa MeanVarState
        @test_broken snt.even isa MeanVarState
        @test_broken mean(snt.odd) === 48.0
        @test_broken mean(snt.even) === 49.0
        @test_broken var(snt.odd) === 784.0
        @test_broken var(snt.even) === 784.0
    end
end

end  # module
