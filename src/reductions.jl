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

function merge_state end
Transducers.Completing(::typeof(merge_state)) = merge_state  # TODO: remove this

@inline initialize_state(x) = x
@inline initialize_right(x) = initialize_state(x)
@inline initialize_left(x) = initialize_state(x)

const InitMergeState = InitialValues.GenericInitialValue{typeof(merge_state)}
merge_state(::InitMergeState, x) = initialize_right(x)
merge_state(x, ::InitMergeState) = initialize_left(x)
merge_state(x::InitMergeState, ::InitMergeState) = x
InitialValues.hasinitialvalue(::Type{typeof(merge_state)}) = true

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

@inline Transducers.complete(::typeof(merge_state), a::AverageState) = a.sum / a.count

const averaging = reducingfunction(Map(singleton_average), merge_state)

"""
    meanvar

A reducing function for computing the mean and variance.

# Examples
```jldoctest
julia> using DataTools, Transducers

julia> foldl(meanvar, Filter(isodd), 1:10)
(5.0, 10.0)

julia> rf = oncol(a = meanvar, b = meanvar);

julia> foldl(rf, Map(identity), [(a = 1, b = 2), (a = 2, b = 3)])
(a = (1.5, 0.5), b = (2.5, 0.5))
```
"""
meanvar

struct MeanVarState{Count,Mean,M2}
    count::Count
    mean::Mean
    m2::M2
end

@inline singleton_meanvar(x) = MeanVarState(static(1), x, static(0))

# Optimization for avoiding type-changing accumulator
@inline function initialize_state(a::MeanVarState)
    count, ione = promote(a.count, 1)
    mean = float(a.mean)
    m2, = promote(a.m2, (one(mean) * one(mean) + one(a.m2)) / (ione + ione))
    return MeanVarState(count, mean, m2)
end

@inline function merge_state(a::MeanVarState, b::MeanVarState)
    d = b.mean - a.mean
    count = a.count + b.count
    return MeanVarState(
        a.count + b.count,
        a.mean + d * b.count / count,
        a.m2 + b.m2 + d^2 * a.count * b.count / count,
    )
end

@inline Transducers.complete(::typeof(merge_state), a::MeanVarState) = (mean(a), var(a))

Statistics.mean(a::MeanVarState) = a.mean
Statistics.var(a::MeanVarState; corrected::Bool = true) =
    a.m2 / (corrected ? (a.count - 1) : a.count)
Statistics.std(a::MeanVarState; kw...) = sqrt(var(a; kw...))

const meanvar = reducingfunction(Map(singleton_meanvar), merge_state)

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
