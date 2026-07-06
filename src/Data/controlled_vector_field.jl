# =============================================================================
# Concrete ControlledVectorField type
# =============================================================================

"""
$(TYPEDEF)

Parametric container for a **controlled** vector-field function together with its
time-dependence and variable-dependence traits.

The function returns the state derivative `fc(t, x, u[, v])` with an explicit control
argument `u`, out-of-place. It is the state-space analogue of
[`CTBase.Data.PseudoHamiltonian`](@ref), and composing it with an open-loop or
closed-loop control law gives a [`CTBase.Data.ComposedVectorField`](@ref).

# Type Parameters
- `F`: concrete type of the wrapped function.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Fields
- `f::F`: the controlled vector-field function.

# Construction
```julia
ControlledVectorField(f; is_autonomous = true, is_variable = false)   # default: fc(x, u)
ControlledVectorField((t, x, u) -> ...; is_autonomous = false)        # fc(t, x, u)
ControlledVectorField((x, u, v) -> ...; is_variable = true)           # fc(x, u, v)
```

# Call Signatures

Callable via its **natural** signature (matching the traits) and via a **uniform**
signature `(t, x, u, v)` that ignores unused arguments.

| `(TD, VD)` | natural | uniform |
|---|---|---|
| `(Autonomous, Fixed)` | `fc(x, u)` | `fc(t, x, u, v)` |
| `(NonAutonomous, Fixed)` | `fc(t, x, u)` | `fc(t, x, u, v)` |
| `(Autonomous, NonFixed)` | `fc(x, u, v)` | `fc(t, x, u, v)` |
| `(NonAutonomous, NonFixed)` | `fc(t, x, u, v)` | `fc(t, x, u, v)` |

See also: [`CTBase.Data.AbstractControlledVectorField`](@ref),
[`CTBase.Data.ComposedVectorField`](@ref), [`CTBase.Data.PseudoHamiltonian`](@ref).
"""
struct ControlledVectorField{F<:Function,TD,VD} <: AbstractControlledVectorField{TD,VD}
    f::F
end

# =============================================================================
# Keyword constructor
# =============================================================================

"""
$(TYPEDSIGNATURES)

Construct a `ControlledVectorField` with trait flags.

# Arguments
- `f::Function`: The controlled vector-field function.
- `is_autonomous::Bool`: If true, autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, depends on the variable (default: `__is_variable()`).

See also: [`CTBase.Data.ControlledVectorField`](@ref).
"""
function ControlledVectorField(
    f; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
)
    TD = is_autonomous ? Traits.Autonomous : Traits.NonAutonomous
    VD = is_variable ? Traits.NonFixed : Traits.Fixed
    return ControlledVectorField{typeof(f),TD,VD}(f)
end

# =============================================================================
# Typed constructor
# =============================================================================

"""
$(TYPEDSIGNATURES)

Typed constructor for `ControlledVectorField` with explicit trait types.

See also: [`CTBase.Data.ControlledVectorField`](@ref).
"""
function ControlledVectorField(
    f, ::Type{TD}, ::Type{VD}
) where {TD<:Traits.TimeDependence,VD<:Traits.VariableDependence}
    return ControlledVectorField{typeof(f),TD,VD}(f)
end

# =============================================================================
# Natural call signatures — one per trait combination
# =============================================================================

(fc::ControlledVectorField{<:Function,Traits.Autonomous,Traits.Fixed})(x, u) = fc.f(x, u)
function (fc::ControlledVectorField{<:Function,Traits.NonAutonomous,Traits.Fixed})(t, x, u)
    return fc.f(t, x, u)
end
function (fc::ControlledVectorField{<:Function,Traits.Autonomous,Traits.NonFixed})(x, u, v)
    return fc.f(x, u, v)
end
function (fc::ControlledVectorField{<:Function,Traits.NonAutonomous,Traits.NonFixed})(
    t, x, u, v
)
    return fc.f(t, x, u, v)
end

# =============================================================================
# Uniform (t, x, u, v) call — used by composition.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
# =============================================================================

function (fc::ControlledVectorField{<:Function,Traits.Autonomous,Traits.Fixed})(t, x, u, v)
    return fc.f(x, u)
end
function (fc::ControlledVectorField{<:Function,Traits.NonAutonomous,Traits.Fixed})(
    t, x, u, v
)
    return fc.f(t, x, u)
end
function (fc::ControlledVectorField{<:Function,Traits.Autonomous,Traits.NonFixed})(
    t, x, u, v
)
    return fc.f(x, u, v)
end
# NonAutonomous, NonFixed — already covered by natural 4-arg

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a `ControlledVectorField`.

See also: [`CTBase.Data.ControlledVectorField`](@ref).
"""
function Base.show(io::IO, ::ControlledVectorField{F,TD,VD}) where {F,TD,VD}
    natural = if TD === Traits.Autonomous && VD === Traits.Fixed
        "fc(x, u)"
    elseif TD === Traits.NonAutonomous && VD === Traits.Fixed
        "fc(t, x, u)"
    elseif TD === Traits.Autonomous && VD === Traits.NonFixed
        "fc(x, u, v)"
    else
        "fc(t, x, u, v)"
    end
    println(io, "ControlledVectorField: $(_td_label(TD)), $(_vd_label(VD))")
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: fc(t, x, u, v)")
end

function Base.show(io::IO, ::MIME"text/plain", fc::ControlledVectorField)
    return show(io, fc)
end
