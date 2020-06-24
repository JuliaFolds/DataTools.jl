module DataTools

export inc1, modifying, oncol

using InitialValues: InitialValues
using Setfield: @lens, Lens, PropertyLens, modify, set
using Tables: Tables
using Transducers: Transducers, complete, next, start

include("utils.jl")
include("oncol.jl")
include("modifying.jl")
include("reductions.jl")

end
