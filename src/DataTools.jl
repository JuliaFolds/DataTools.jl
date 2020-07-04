module DataTools

export averaging, inc1, modifying, oncol

using InitialValues: InitialValues
using Setfield: @lens, Lens, PropertyLens, modify, set
using Tables: Tables
using Transducers: Transducers, complete, next, start

include("utils.jl")
include("oncol.jl")
include("modifying.jl")
include("reductions.jl")

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end DataTools

end
