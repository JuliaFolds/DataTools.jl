"""
    inc1(n, _) -> n + 1

A reducing function for counting elements.  It increments the first
argument by one.

# Examples
```jldoctest
julia> using DataTools
       using Transducers

julia> inc1(10, :ignored)
11

julia> inc1(Init(inc1), :ignored)
1

julia> foldl(inc1, Map(identity), 'a':2:'e')
3

julia> foldl(TeeRF(+, inc1), Map(identity), 1:2:10)  # sum and count
(25, 5)

julia> rf = oncol(:a => (+) => :sum, :a => inc1 => :count);

julia> foldl(rf, Map(identity), [(a = 1, b = 2), (a = 2, b = 3)])
(sum = 3, count = 2)
```
"""
inc1(n, _) = n + 1
Transducers.start(::typeof(inc1), ::InitializerFor{typeof(inc1)}) = 0
Transducers.combine(::typeof(inc1), a, b) = a + b
InitialValues.@def inc1 1


"""
    averaging

A reducing function for averaging elements.

# Examples
```jldoctest
julia> using DataTools
       using Transducers

julia> foldl(averaging, Filter(isodd), 1:10)
5.0

julia> rf = oncol(a = averaging, b = averaging);

julia> foldl(rf, Map(identity), [(a = 1, b = 2), (a = 2, b = 3)])
(a = 1.5, b = 2.5)
```
"""
averaging

struct AverageState{Sum}
    sum::Sum
    count::Int
end

@inline singleton_average(x) = AverageState(x, 1)

@inline merge_state(a::AverageState, b::AverageState) =
    AverageState(a.sum + b.sum, a.count + b.count)
InitialValues.@def_monoid merge_state

@inline Transducers.complete(::typeof(merge_state), a::AverageState) = a.sum / a.count
Transducers.Completing(::typeof(merge_state)) = merge_state  # TODO: remove this

const averaging = reducingfunction(Map(singleton_average), merge_state)

"""
    rightif(predicate, [focus = identity]) -> op::Function

Return a binary function that keeps the first argument unless
`predicate` evaluates to `true`.

This is equivalent to

```julia
(l, r) -> predicate(focus(l), focus(r)) ? r : l
```

# Examples
```jldoctest
julia> using DataTools, Transducers

julia> table = 1:100 |> Map(x -> (k = gcd(x, 42), v = x));

julia> table |> Take(5) |> collect  # preview
5-element Array{NamedTuple{(:k, :v),Tuple{Int64,Int64}},1}:
 (k = 1, v = 1)
 (k = 2, v = 2)
 (k = 3, v = 3)
 (k = 2, v = 4)
 (k = 1, v = 5)

julia> foldl(rightif(<), Map(x -> x.k), table)  # maximum
42

julia> foldl(rightif(>), Map(x -> x.k), table)  # minimum
1

julia> foldl(rightif(<, x -> x.k), table)   # first maximum
(k = 42, v = 42)

julia> foldl(rightif(<=, x -> x.k), table)  # last maximum
(k = 42, v = 84)

julia> foldl(rightif(>, x -> x.k), table)   # first minimum
(k = 1, v = 1)

julia> foldl(rightif(>=, x -> x.k), table)  # last minimum
(k = 1, v = 97)

julia> table |> Scan(rightif(<, x -> x.k)) |> Take(5) |> collect
5-element Array{NamedTuple{(:k, :v),Tuple{Int64,Int64}},1}:
 (k = 1, v = 1)
 (k = 2, v = 2)
 (k = 3, v = 3)
 (k = 3, v = 3)
 (k = 3, v = 3)
```
"""
rightif(predicate, focus = identity) = RightIf(predicate, focus)

struct RightIf{P,F} <: _Function
    predicate::P
    focus::F
end

RightIf(predicate::P, ::Type{F}) where {P,F} = RightIf{P,Type{F}}(predicate, F)

@inline (f::RightIf)(l, r) = f.predicate(f.focus(l), f.focus(r)) ? r : l

const InitRightIf{P,F} = InitialValues.GenericInitialValue{RightIf{P,F}}
(::RightIf)(::InitRightIf, x) = x
(::RightIf)(x, ::InitRightIf) = x
(::RightIf)(x::InitRightIf, ::InitRightIf) = x
InitialValues.hasinitialvalue(::Type{<:RightIf}) = true
