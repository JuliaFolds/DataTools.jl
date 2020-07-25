"""
    nitems(xs) -> n::Integer

Count number of items in `xs`.  Consume `xs` if necessary.

# Examples
```jldoctest
julia> using DataTools, Transducers

julia> nitems(1:10)
10

julia> 1:10 |> Filter(isodd) |> Map(inv) |> nitems
5
```
"""
nitems
nitems(xs) =
    if IteratorSize(xs) isa Union{HasLength, HasShape}
        length(xs)
    else
        xf, coll = extract_transducer(xs)
        _nitems(_pop_innermost_maplikes(xf), coll)
    end

_pop_innermost_maplikes(xf) = xf
_pop_innermost_maplikes(::Union{Map,MapSplat,Scan}) = IdentityTransducer()
function _pop_innermost_maplikes(xf::Composition)
    inner = _pop_innermost_maplikes(xf.inner)
    if inner isa IdentityTransducer
        return _pop_innermost_maplikes(xf.outer)
    else
        opcompose(xf.outer, inner)
    end
end

_nitems(::IdentityTransducer, xs) = _nitems(xs)
_nitems(xf, xs) = xs |> xf |> _nitems

_nitems(xs) =
    if IteratorSize(xs) isa Union{HasLength, HasShape}
        length(xs)
    else
        foldl(inc1, IdentityTransducer(), xs)
    end
# TODO: optimization for `Cat`.

"""
    firstitem(xs)

Get the first item of `xs`.  Consume `xs` if necessary.

# Examples
```jldoctest
julia> using DataTools, Transducers

julia> firstitem(3:7)
3

julia> 3:7 |> Map(x -> x + 1) |> Filter(isodd) |> firstitem
5
```
"""
firstitem
firstitem(xs::AbstractArray) = first(xs)
firstitem(xs) = foldl(right, Take(1), xs)

"""
    lastitem(xs)

Get the last item of `xs`.  Consume `xs` if necessary.

# Examples
```jldoctest
julia> using DataTools, Transducers

julia> lastitem(3:7)
7

julia> 3:7 |> Map(x -> x + 1) |> Filter(isodd) |> lastitem
7
```
"""
lastitem
lastitem(xs::AbstractArray) = last(xs)
lastitem(xs) = foldl(right, Map(identity), xs)

"""
    firstitems(xs, n::Integer)
    firstitems(n::Integer) -> xs -> firstitems(xs, n)

Get the first `n` items of `xs`.  Consume `xs` if necessary.
"""
firstitems
firstitems(n::Integer) = xs -> firstitems(xs, n)
firstitems(xs, n::Integer) = collect(Take(n), xs)
firstitems(xs::AbstractArray, n::Integer) = view(xs, firstindex(xs):firstindex(xs)+n-1)

"""
    lastitems(xs, n::Integer)
    lastitems(n::Integer) -> xs -> lastitems(xs, n)

Get the last `n` items of `xs`.  Consume `xs` if necessary.
"""
lastitems
lastitems(n::Integer) = xs -> lastitems(xs, n)
lastitems(xs, n::Integer) = collect(TakeLast(n), xs)
lastitems(xs::AbstractArray, n::Integer) = view(xs, lastindex(xs)-n+1:lastindex(xs))
