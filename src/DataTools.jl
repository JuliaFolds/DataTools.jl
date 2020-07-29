module DataTools

export averaging,
    firstitem,
    firstitems,
    inc1,
    lastitem,
    lastitems,
    meanvar,
    modifying,
    nitems,
    oncol,
    rightif

using Base: HasLength, HasShape, IteratorSize
using InitialValues: InitialValues
using Setfield: @lens, Lens, PropertyLens, modify, set
using StaticNumbers: static
using Statistics: Statistics, mean, std, var
using Tables: Tables
using Transducers:
    Composition,
    Count,
    IdentityTransducer,
    Map,
    MapSplat,
    Scan,
    Take,
    TakeLast,
    Transducers,
    combine,
    complete,
    extract_transducer,
    next,
    opcompose,
    reducingfunction,
    right,
    start

include("utils.jl")
include("oncol.jl")
include("modifying.jl")
include("reductions.jl")
include("reducers.jl")

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end DataTools

end
