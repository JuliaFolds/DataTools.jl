"""
    modifying(; \$property₁ = f₁, ..., \$propertyₙ = fₙ) -> g::Function
    modifying(lens₁ => f₁, ..., lensₙ => fₙ) -> g::Function

Create a function that runs function `fᵢ` on the locations specified
by `propertyᵢ` or `lensᵢ`.

The keyword-only method `modifying(; a = f₁, b = f₂)` is equivalent to
`modifying(@len(_.a) => f₁, @len(_.b) => f₂)`.

The unary method `g(x)` is equivalent to

```julia
x = modify(f₁, x, lens₁)
x = modify(f₂, x, lens₂)
...
x = modify(fₙ, x, lensₙ)
```

The binary method `g(x, y)` is equivalent to

```julia
x = set(x, lens₁, f₁(lens₁(x)), lens₁(y))
x = set(x, lens₂, f₂(lens₂(x)), lens₂(y))
...
x = set(x, lensₙ, fₙ(lensₙ(x)), lensₙ(y))
```

Note that the locations that are not specified by the lenses keep the
values as in `x`.  This is similar to how `mergewith` behaves.

# Examples
```jldoctest
julia> using DataTools

julia> map(modifying(a = string), [(a = 1, b = 2), (a = 3, b = 4)])
2-element Array{NamedTuple{(:a, :b),Tuple{String,Int64}},1}:
 (a = "1", b = 2)
 (a = "3", b = 4)

julia> reduce(modifying(a = +), [(a = 1, b = 2), (a = 3, b = 4)])
(a = 4, b = 2)

julia> using Accessors

julia> map(modifying(@optic(_.a[1].b) => x -> 10x),
           [(a = ((b = 1,), 2),), (a = ((b = 3,), 4),)])
2-element Array{NamedTuple{(:a,),Tuple{Tuple{NamedTuple{(:b,),Tuple{Int64}},Int64}}},1}:
 (a = ((b = 10,), 2),)
 (a = ((b = 30,), 4),)
```
"""
modifying

modifying(; specs...) =
    ModifyingFunction(map(((k, v),) -> PropertyLens{k}() => v, Tuple(specs)))
modifying(specs::Pair...) = ModifyingFunction(specs)
modifying(f, lens) = ModifyingFunction((f, lens))

struct ModifyingFunction{FS} <: Function
    functions::FS
end

@inline (f::ModifyingFunction)(x) =
    foldl(f.functions; init = x) do x, (lens, g)
        @_inline_meta
        modify(g, x, lens)
    end

@inline (f::ModifyingFunction)(x, y) =
    foldl(f.functions; init = x) do z, (lens, g)
        @_inline_meta
        modify(z, lens) do v
            @_inline_meta
            g(v, lens(y))
        end
    end
