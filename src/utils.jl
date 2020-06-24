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
