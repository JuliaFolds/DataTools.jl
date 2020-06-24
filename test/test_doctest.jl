module TestDoctest

import DataTools
using Documenter: doctest
using Test

@testset "doctest" begin
    doctest(DataTools; manual = false)
end

end  # module
