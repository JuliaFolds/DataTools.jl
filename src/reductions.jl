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
function averaging end
@inline averaging((n, s), x) = (n + 1, s + x)
Transducers.combine(::typeof(averaging), (n1, s1), (n2, s2)) = (n1 + n2, s1 + s2)
Transducers.complete(::typeof(averaging), (n, s)) = s / n
Transducers.Completing(::typeof(averaging)) = averaging  # TODO: remove this
InitialValues.@def averaging (1, x)
