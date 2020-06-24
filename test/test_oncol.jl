module TestOncol

using Test
using DataTools

@testset begin
    @test oncol(a = +, b = *)((a = 1, b = 2), (a = 3, b = 4)) == (a = 4, b = 8)
    @test oncol(:a => (+) => :sum, :a => max => :max)((sum = 1, max = 1), (a = 2,)) ==
          (sum = 3, max = 2)
    @test oncol(:a => min, :a => max)((a_min = 2, a_max = 2), (a = 1,)) ==
          (a_min = 1, a_max = 2)
end

end  # module
