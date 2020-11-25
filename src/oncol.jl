# Something like `DataFrames.combine`
# https://juliadata.github.io/DataFrames.jl/stable/man/split_apply_combine/
# https://juliadata.github.io/DataFrames.jl/stable/lib/functions/#DataFrames.select

"""
    oncol(iname₁ => spec₁, ..., inameₙ => specₙ) -> f::Function
    oncol(; \$iname₁ = spec₁, ..., \$inameₙ = specₙ) -> f::Function

Combine functions that work on a column and create a function that
work on an entire row.

It constructs a reducing step function acting on a table row where
`specᵢ` is either a reducing step function or a `Pair` of a reducing
step function and an output column name.

It also defines a unary function when `specᵢ` is either a unary
function or a `Pair` of a unary function and an output column name.

This function is inspired by the "`Pair` notation" in DataFrames.jl
(see also [Split-apply-combine ·
DataFrames.jl](https://juliadata.github.io/DataFrames.jl/stable/man/split_apply_combine/)
and
[`DataFrames.select`](https://juliadata.github.io/DataFrames.jl/stable/lib/functions/#DataFrames.select)).

# Examples
```jldoctest oncol
julia> using DataTools
       using Transducers

julia> rf = oncol(a = +, b = *);

julia> foldl(rf, Map(identity), [(a = 1, b = 2), (a = 3, b = 4)])
(a = 4, b = 8)

julia> rf((a = 1, b = 2), (a = 3, b = 4))
(a = 4, b = 8)

julia> rf = oncol(:a => (+) => :sum, :a => max => :max);

julia> foldl(rf, Map(identity), [(a = 1,), (a = 2,)])
(sum = 3, max = 2)

julia> rf((sum = 1, max = 1), (a = 2,))
(sum = 3, max = 2)

julia> rf = oncol(:a => min, :a => max);

julia> foldl(rf, Map(identity), [(a = 2,), (a = 1,)])
(a_min = 1, a_max = 2)

julia> rf((a_min = 2, a_max = 2), (a = 1,))
(a_min = 1, a_max = 2)

julia> foldl(rf, Map(x -> (a = x,)), [5, 2, 6, 8, 3])
(a_min = 2, a_max = 8)
```

`oncol` also defines a unary function

```jldoctest oncol
julia> f = oncol(a = string);

julia> f((a = 1, b = 2))
(a = "1",)
```

Note that `oncol` does not verify the arity of input functions.  If
the input functions have unary and binary methods, `oncol` is callable
with both arities:

```jldoctest oncol
julia> f((a = 1, b = 2), (a = 3, b = 4))
(a = "13",)
```
"""
oncol

struct Property{name} end
Property(p::Property) = p
Property(name::Symbol) = Property{name}()
Property(::Val{name}) where {name} = Property{name}()

@inline getprop(x, ::Property{name}) where {name} = getproperty(x, name)
@inline Base.Symbol(::Property{name}) where {name} = name::Symbol

const PropertyLike = Union{Symbol,Val,Property}

struct OnRowFunction{FS} <: Function
    functions::FS
end

# :x => f                    (x_f = f(a.x, b.x),)
# :x => f => :y              (y = f(a.x, b.x),)
# (:x, :y) => f => :z        (z = f((a.x, a.y), (b.x, b.y)),)   ???

@inline (f::OnRowFunction)(x) =
    mapfoldl(merge, f.functions; init = NamedTuple()) do (iname, g, oname)
        Base.@_inline_meta
        (; Symbol(oname) => g(getprop(x, iname)))
    end

@inline (rf::OnRowFunction)(acc, x) = next(rf, acc, x)
@inline Transducers.next(rf::OnRowFunction, acc, x) =
    mapfoldl(merge, rf.functions; init = NamedTuple()) do (iname, op, oname)
        Base.@_inline_meta
        (; Symbol(oname) => next(op, getprop(acc, oname), getprop(x, iname)))
    end

Transducers.start(rf::OnRowFunction, init) =
    mapfoldl(merge, rf.functions; init = NamedTuple()) do (_, op, oname)
        (; Symbol(oname) => start(op, init))
    end

# TODO: dispatch on "Initializer" type instead
Transducers.start(rf::OnRowFunction, init::RowLike) =
    mapfoldl(merge, rf.functions; init = NamedTuple()) do (_, op, oname)
        (; Symbol(oname) => start(op, getprop(init, oname)))
    end

Transducers.complete(rf::OnRowFunction, acc) =
    mapfoldl(merge, rf.functions; init = NamedTuple()) do (_, op, oname)
        (; Symbol(oname) => complete(op, getprop(acc, oname)))
    end

Transducers.combine(rf::OnRowFunction, a, b) =
    mapfoldl(merge, rf.functions; init = NamedTuple()) do (_, op, oname)
        (; Symbol(oname) => combine(op, getprop(a, oname), getprop(b, oname)))
    end

# TODO: define better API:
Transducers._asmonoid(rf::OnRowFunction) =
    OnRowFunction(map(modifying(@optic(_[2]) => Transducers._asmonoid), rf.functions))
Transducers.Completing(rf::OnRowFunction) =
    OnRowFunction(map(modifying(@optic(_[2]) => Transducers.Completing), rf.functions))

@inline process_spec_kwargs((iname, spec)::Pair) =
    process_spec(Property(iname), spec, Property(iname))

@inline process_spec(name::PropertyLike) = (Property(name), identity, Property(name))
@inline process_spec((iname, spec)::Pair) = process_spec(iname, spec)
@inline process_spec(iname, (op, oname)::Pair) = process_spec(iname, op, oname)
@inline process_spec(iname, op) = process_spec(iname, op, outname(iname, op))
@inline process_spec(iname, op, oname) = (Property(iname), op, Property(oname))

outname(iname, op) = Symbol(Symbol(iname), '_', funname(op))

funname(op::ComposedFunction) = Symbol(funname(op.f), :_, funname(op.g))
function funname(op)
    name = string(op)
    return startswith(name, "#") ? :function : Symbol(op)
end

oncol(; specs...) =
    if any(((_, spec),) -> spec isa Pair, specs)
        fs = map(process_spec, Tuple(specs))
        @assert allunique(map(last, fs))  # TODO: uniquify function names
        OnRowFunction(fs)
    else
        OnRowFunction(map(process_spec_kwargs, Tuple(specs)))
    end

oncol(specs::Union{Pair{<:PropertyLike},PropertyLike}...) =
    OnRowFunction(map(process_spec, specs))
