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
