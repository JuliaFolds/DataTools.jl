module TestAveraging

using Test
using DataTools

@testset begin
    @test foldl(averaging, Filter(isodd), 1:10) == 5
    @test foldl(
        oncol(a = averaging, b = averaging);
        Map(identity),
        [(a = 1, b = 2), (a = 2, b = 3)],
    ) == (a = 1.5, b = 2.5)
end

end  # module
