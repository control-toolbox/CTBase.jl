# =============================================================================
# Concrete Multiplier type
# =============================================================================

"""
$(TYPEDEF)

Parametric container for a path-constraint multiplier function together with its
time-dependence and variable-dependence traits.

The function returns the Lagrange multiplier `μ(t, x, p[, v])` associated with a
path constraint. It has the same call structure as a
[`CTBase.Data.Hamiltonian`](@ref).

# Type Parameters
- `F`: concrete type of the wrapped function.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Fields
- `f::F`: the multiplier function.

# Construction

Use the keyword constructor:

```julia
Multiplier(f; is_autonomous = true, is_variable = false)      # default: μ(x, p)
Multiplier((t, x, p) -> ...; is_autonomous = false)           # μ(t, x, p)
Multiplier((x, p, v) -> ...; is_variable = true)              # μ(x, p, v)
Multiplier((t, x, p, v) -> ...; is_autonomous = false, is_variable = true)
```

# Call Signatures

Every `Multiplier` is callable via its **natural** signature (matching the
traits), and via a **uniform** signature `(t, x, p, v)` that ignores the unused
arguments.

For Autonomous/Fixed: natural `μ(x, p)`, uniform `μ(t, x, p, v)`.
For NonAutonomous/Fixed: natural `μ(t, x, p)`, uniform `μ(t, x, p, v)`.
For Autonomous/NonFixed: natural `μ(x, p, v)`, uniform `μ(t, x, p, v)`.
For NonAutonomous/NonFixed: natural `μ(t, x, p, v)`, uniform `μ(t, x, p, v)`.

# Example
```julia-repl
julia> using CTBase.Data

julia> μ = Multiplier((x, p) -> x[1])
Multiplier: autonomous, fixed (no variable)
  natural call: μ(x, p)
  uniform call: μ(t, x, p, v)
```

See also: [`CTBase.Data.AbstractMultiplier`](@ref), [`CTBase.Data.Hamiltonian`](@ref),
[`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
struct Multiplier{
    F<:Function,TD<:Traits.TimeDependence,VD<:Traits.VariableDependence
} <: AbstractMultiplier{TD,VD}
    f::F
end

# =============================================================================
# Constructor
# =============================================================================

"""
$(TYPEDSIGNATURES)

Construct a `Multiplier` with trait flags.

# Arguments
- `f::Function`: The multiplier function.
- `is_autonomous::Bool`: If true, multiplier is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, multiplier depends on variable parameters (default: `__is_variable()`).

# Returns
- `Multiplier`: A multiplier with appropriate traits.

# Example
```julia-repl
julia> using CTBase.Data

julia> μ = Multiplier((x, p) -> x[1])
Multiplier: autonomous, fixed (no variable)
  natural call: μ(x, p)
  uniform call: μ(t, x, p, v)

julia> μ = Multiplier((t, x, p) -> t * x[1]; is_autonomous=false)
Multiplier: non-autonomous, fixed (no variable)
  natural call: μ(t, x, p)
  uniform call: μ(t, x, p, v)
```

See also: [`CTBase.Data.Multiplier`](@ref), [`CTBase.Traits.Autonomous`](@ref),
[`CTBase.Traits.NonAutonomous`](@ref), [`CTBase.Traits.Fixed`](@ref), [`CTBase.Traits.NonFixed`](@ref).
"""
function Multiplier(
    f; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
)
    TD = is_autonomous ? Traits.Autonomous : Traits.NonAutonomous
    VD = is_variable ? Traits.NonFixed : Traits.Fixed
    return Multiplier{typeof(f),TD,VD}(f)
end

# =============================================================================
# Typed constructor — calls struct inner constructor directly
# =============================================================================

"""
$(TYPEDSIGNATURES)

Typed constructor for `Multiplier` with explicit trait types.

See also: [`CTBase.Data.Multiplier`](@ref).
"""
function Multiplier(
    f, ::Type{TD}, ::Type{VD}
) where {TD<:Traits.TimeDependence,VD<:Traits.VariableDependence}
    return Multiplier{typeof(f),TD,VD}(f)
end

# =============================================================================
# Natural call signatures - one per trait combination
# =============================================================================

(m::Multiplier{<:Function,Traits.Autonomous,Traits.Fixed})(x, p) = m.f(x, p)
(m::Multiplier{<:Function,Traits.NonAutonomous,Traits.Fixed})(t, x, p) = m.f(t, x, p)
(m::Multiplier{<:Function,Traits.Autonomous,Traits.NonFixed})(x, p, v) = m.f(x, p, v)
function (m::Multiplier{<:Function,Traits.NonAutonomous,Traits.NonFixed})(t, x, p, v)
    return m.f(t, x, p, v)
end

# =============================================================================
# Uniform (t, x, p, v) call — used by flows.
# Every combination forwards to its natural call, ignoring unused args.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
# =============================================================================

(m::Multiplier{<:Function,Traits.Autonomous,Traits.Fixed})(_, x, p, _) = m.f(x, p)
(m::Multiplier{<:Function,Traits.NonAutonomous,Traits.Fixed})(t, x, p, _) = m.f(t, x, p)
(m::Multiplier{<:Function,Traits.Autonomous,Traits.NonFixed})(_, x, p, v) = m.f(x, p, v)

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a `Multiplier` showing its traits and call signatures.

# Arguments
- `io::IO`: The IO stream.
- `m::Multiplier`: The multiplier object.

# Output
Displays three lines:
- Header with time and variable dependence traits
- Natural call signature
- Uniform call signature

See also: [`CTBase.Data.Multiplier`](@ref).
"""
function Base.show(io::IO, ::Multiplier{F,TD,VD}) where {F,TD,VD}
    header = "Multiplier: $(_td_label(TD)), $(_vd_label(VD))"
    natural = _natural_sig_mult(TD, VD)
    uniform = _uniform_sig_mult()
    println(io, header)
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: ", uniform)
end

"""
$(TYPEDSIGNATURES)

Display a `Multiplier` in the REPL with the same format as the compact `show`.

This method is called automatically when displaying a multiplier in the Julia REPL.

# Arguments
- `io::IO`: The IO stream.
- `mime::MIME"text/plain"`: The MIME type.
- `m::Multiplier`: The multiplier object.

See also: [`CTBase.Data.Multiplier`](@ref).
"""
function Base.show(io::IO, ::MIME"text/plain", m::Multiplier{F,TD,VD}) where {F,TD,VD}
    return show(io, m)
end
