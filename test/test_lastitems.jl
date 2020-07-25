module TestLastitems

using DataTools
using Test
using Transducers

@testset "lastitem" begin
    @test lastitem(3:7) === 7
    @test 3:7 |> Map(x -> x + 1) |> Filter(isodd) |> lastitem == 7
end

@testset "lastitems" begin
    @test lastitems(3:7, 2) === 6:7
    @test 3:7 |> Map(x -> x + 1) |> Filter(isodd) |> lastitems(2) == [5, 7]
end

end  # module
