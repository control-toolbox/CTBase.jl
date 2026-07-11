# =============================================================================
# Call methods
# =============================================================================

# Linear interpolation with flat extrapolation outside [x[1], x[end]].
function (interp::Interpolant{Linear})(t)
    x, f = interp.x, interp.f
    if t < x[1]
        return f[1]
    elseif t >= x[end]
        return f[end]
    else
        i = searchsortedlast(x, t)
        i == length(x) && return f[end]
        α = (t - x[i]) / (x[i + 1] - x[i])
        return f[i] + α * (f[i + 1] - f[i])
    end
end

# Right-continuous piecewise-constant (steppost) interpolation.
function (interp::Interpolant{Constant})(t)
    x, f = interp.x, interp.f
    if t < x[1]
        return f[1]
    elseif t >= x[end]
        return f[end]
    else
        return f[searchsortedlast(x, t)]
    end
end

# =============================================================================
# Factories (public API)
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return a linear interpolation function for the data `f` defined at points `x`.

This creates a one-dimensional linear [`Interpolant`](@ref) with flat extrapolation beyond
the bounds of `x` (returns `f[1]` for `t < x[1]` and `f[end]` for `t >= x[end]`).

# Arguments
- `x`: A vector of points at which the values `f` are defined.
- `f`: A vector of values to interpolate.

# Returns
A callable [`Interpolant{Linear}`](@ref) that can be evaluated at new points.

# Example
```julia-repl
julia> x = [0.0, 1.0, 2.0]
julia> f = [1.0, 2.0, 3.0]
julia> interp = ctinterpolate(x, f)
julia> interp(0.5)  # Returns 1.5 (linear interpolation)
julia> interp(-1.0)  # Returns 1.0 (flat extrapolation)
julia> interp(3.0)  # Returns 3.0 (flat extrapolation)
```
"""
ctinterpolate(x, f) = Interpolant{Linear}(x, f)

"""
$(TYPEDSIGNATURES)

Return a piecewise-constant interpolation function for the data `f` defined at points `x`.

This creates a right-continuous piecewise-constant [`Interpolant`](@ref): the value at knot
`x[i]` is held constant on the interval `[x[i], x[i+1})`.

This implements the standard steppost behavior for optimal control:
- `u(t_i) = u_i` (value at the knot)
- `u(t) = u_i` for all `t ∈ [t_i, t_{i+1})`
- Right-continuous: `lim_{t→t_i^+} u(t) = u(t_i)`

# Arguments
- `x`: A vector of points at which the values `f` are defined.
- `f`: A vector of values to interpolate.

# Returns
A callable [`Interpolant{Constant}`](@ref) that can be evaluated at new points.

# Example
```julia-repl
julia> x = [0.0, 1.0, 2.0]
julia> f = [1.0, 2.0, 3.0]
julia> interp = ctinterpolate_constant(x, f)
julia> interp(0.0)  # Returns 1.0 (value at x[1])
julia> interp(0.5)  # Returns 1.0 (held from x[1] on [0.0, 1.0))
julia> interp(1.0)  # Returns 2.0 (value at x[2], right-continuous)
julia> interp(1.5)  # Returns 2.0 (held from x[2] on [1.0, 2.0))
```
"""
ctinterpolate_constant(x, f) = Interpolant{Constant}(x, f)
