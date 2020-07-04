module TestModifying

using DataTools
using Setfield: @lens
using Test
using Transducers

reduce_bs1(args...; kw...) = reduce(args...; basesize = 1, kw...)

@testset for fold in [foldl, reduce_bs1, reduce]
    @test fold(modifying(a = +), Map(identity), [(a = 1, b = 2), (a = 3, b = 4)]) ==
          (a = 4, b = 2)
end

@testset "map" begin
    @test map(modifying(a = string), [(a = 1, b = 2), (a = 3, b = 4)]) ==
          [(a = "1", b = 2), (a = "3", b = 4)]
    @test map(
        modifying(@lens(_.a[1].b) => x -> 10x),
        [(a = ((b = 1,), 2),), (a = ((b = 3,), 4),)],
    ) == [(a = ((b = 10,), 2),), (a = ((b = 30,), 4),)]
end

end  # module
