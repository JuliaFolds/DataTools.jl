"""
    ==ₜ(x, y)

Check that _type_ and value of `x` and `y` are equal.
"""
==ₜ(_, _) = false
==ₜ(x::T, y::T) where T = x == y
