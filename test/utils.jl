"""
    ==ₜ(x, y)

Check that _type_ and value of `x` and `y` are equal.
"""
==ₜ(_, _) = false
==ₜ(x::T, y::T) where T = x == y

"""
    ==ₛ(a::AbstractString, b::AbstractString)

Equality check ignoring white spaces
"""
==ₛ(a::AbstractString, b::AbstractString) =
    replace(a, r"\s" => "") == replace(b, r"\s" => "")

"""
    ==ᵣ(a::AbstractString, b::AbstractString)

Equality check appropriate for comparing `repr` output.
"""
==ᵣ
if VERSION >= v"1.6-"
    const ==ᵣ = ==ₛ
else
    const ==ᵣ = ==
end
