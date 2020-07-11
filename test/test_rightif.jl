module TestRightIf

using DataTools
using Test
using Transducers: Map, Take

reduce_bs1(args...; kw...) = reduce(args...; basesize = 1, kw...)

@testset for fold in [foldl, reduce_bs1, reduce]
    foldl = nothing
    table = 43:100 |> Map(x -> (k = gcd(x, 42), v = x))
    @test fold(rightif(<), Map(x -> x.k), table) == 42
    @test fold(rightif(>), Map(x -> x.k), table) == 1
    @test fold(rightif(<, x -> x.k), table) == (k = 42, v = 84)
end

end  # module
