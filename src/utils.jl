@static if VERSION < v"1.8.0-DEV.410"
    using Base: @_inline_meta
else
    const var"@_inline_meta" = Base.var"@inline"
end

const RowLike = Union{NamedTuple,Tables.Row,Tables.AbstractRow}

if isdefined(Base, :ComposedFunction) # Julia >= 1.6.0-DEV.85
    using Base: ComposedFunction
else
    const ComposedFunction = let h = identity ∘ convert
        @assert h.f === identity
        @assert h.g === convert
        getfield(parentmodule(typeof(h)), nameof(typeof(h)))
    end
    @assert identity ∘ convert isa ComposedFunction
end

const GenericInitializer = Union{typeof(Transducers.Init),Transducers.InitOf}

const InitializerFor{OP} = Union{GenericInitializer,InitialValues.GenericInitialValue{OP}}

# Just like `Function` but for defining some common methods.
abstract type _Function <: Function end

# Avoid `Function` fallbacks:
@nospecialize
Base.show(io::IO, ::MIME"text/plain", f::_Function) = show(io, f)
Base.print(io::IO, f::_Function) = show(io, f)
@specialize
