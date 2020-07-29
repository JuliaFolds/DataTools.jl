module TestFirstitems

using DataTools
using Test
using Transducers

include("utils.jl")

@testset "firstitem" begin
    @test firstitem(3:7) === 3
    @test 3:7 |> Map(x -> x + 1) |> Filter(isodd) |> firstitem == 5
end

@testset "firstitems" begin
    @test firstitems(3:7, 2) ==ₜ view(3:7, 1:2)
    @test 3:7 |> Map(x -> x + 1) |> Filter(isodd) |> firstitems(2) == [5, 7]
end

end  # module
