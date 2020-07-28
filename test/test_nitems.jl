module TestNItems

using DataTools
using Test
using Transducers
using Transducers: IdentityTransducer

@testset "_pop_innermost_maplikes" begin
    pop(args...) = DataTools._pop_innermost_maplikes(opcompose(args...))
    @test pop(Map(inv)) === IdentityTransducer()
    @test pop(MapSplat(tuple), Map(inv)) === IdentityTransducer()
    @test pop(Filter(isodd), MapSplat(tuple), Map(inv)) === Filter(isodd)
    @test pop(Map(isodd), Filter(isodd), MapSplat(tuple), Map(inv)) ===
          opcompose(Map(isodd), Filter(isodd))
end

@testset "nitems" begin
    @test nitems(1:10) == 10
    @test nitems(error(x) for x in 1:10) == 10
    @test 1:10 |> Map(error) |> MapSplat(error) |> Scan(+) |> nitems == 10
    @test 1:10 |> Filter(isodd) |> Map(error) |> MapSplat(error) |> nitems == 5
    @test 1:10 |> Filter(isodd) |> Map(x -> x ÷ 3) |> Filter(isodd) |> nitems == 3
end

end  # module
