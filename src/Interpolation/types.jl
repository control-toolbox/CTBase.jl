"""
$(TYPEDEF)

Abstract interpolation method (trait).

Concrete subtypes (`Linear`, `Constant`) are singleton trait values carried as a type
parameter of [`Interpolant`](@ref), so the call method is resolved statically.
"""
abstract type AbstractInterpolation end

"""
$(TYPEDEF)

Linear interpolation method (with flat extrapolation outside the node range).
"""
struct Linear <: AbstractInterpolation end

"""
$(TYPEDEF)

Piecewise-constant (right-continuous steppost) interpolation method.
"""
struct Constant <: AbstractInterpolation end

"""
$(TYPEDEF)

Callable interpolant of method `M` over nodes `x` with values `f`.

`Interpolant` subtypes `Function`: an instance `interp` is evaluated as `interp(t)`. The
method `M` (a subtype of [`AbstractInterpolation`](@ref)) is a compile-time trait parameter
that selects the evaluation rule, so the call is type-stable.

# Fields
- `x::TX`: nodes at which the values are defined.
- `f::TF`: values to interpolate.

# Construction
Build instances through the factories [`ctinterpolate`](@ref) (linear) and
[`ctinterpolate_constant`](@ref) (piecewise-constant).
"""
struct Interpolant{M<:AbstractInterpolation,TX,TF} <: Function
    x::TX
    f::TF
end

# Outer constructor: infer TX, TF from the arguments.
function Interpolant{M}(x::TX, f::TF) where {M<:AbstractInterpolation,TX,TF}
    return Interpolant{M,TX,TF}(x, f)
end

"""
$(TYPEDSIGNATURES)

Return the interpolation method (a subtype of [`AbstractInterpolation`](@ref)) of `interp`.
"""
method(::Interpolant{M}) where {M} = M
