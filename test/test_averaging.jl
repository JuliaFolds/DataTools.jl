module TestAveraging

using DataTools
using Test
using Transducers: Filter, Map

reduce_bs1(args...; kw...) = reduce(args...; basesize = 1, kw...)

@testset for fold in [foldl, reduce_bs1, reduce]
    @test fold(averaging, Filter(isodd), 1:10) == 5
    @test fold(
        oncol(a = averaging, b = averaging),
        Map(identity),
        [(a = 1, b = 2), (a = 2, b = 3)],
    ) == (a = 1.5, b = 2.5)
end

end  # module
