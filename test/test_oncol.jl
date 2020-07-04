module TestOncol

using DataTools
using Test
using Transducers

reduce_bs1(args...; kw...) = reduce(args...; basesize = 1, kw...)

@testset begin
    @test oncol(a = +, b = *)((a = 1, b = 2), (a = 3, b = 4)) == (a = 4, b = 8)
    @test oncol(:a => (+) => :sum, :a => max => :max)((sum = 1, max = 1), (a = 2,)) ==
          (sum = 3, max = 2)
    @test oncol(:a => min, :a => max)((a_min = 2, a_max = 2), (a = 1,)) ==
          (a_min = 1, a_max = 2)
end

@testset for fold in [foldl, reduce_bs1, reduce]
    @test fold(
        oncol(a = +, b = averaging),
        Filter(x -> isodd(x.a)),
        [(a = 1, b = 7), (a = 2, b = 3), (a = 3, b = 4)],
    ) == (a = 4, b = 5.5)
end

end  # module
