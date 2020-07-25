module TestFirstitems

using DataTools
using Test
using Transducers

@testset "firstitem" begin
    @test firstitem(3:7) === 3
    @test 3:7 |> Map(x -> x + 1) |> Filter(isodd) |> firstitem == 5
end

@testset "firstitems" begin
    @test firstitems(3:7, 2) === 3:4
    @test 3:7 |> Map(x -> x + 1) |> Filter(isodd) |> firstitems(2) == [5, 7]
end

end  # module
