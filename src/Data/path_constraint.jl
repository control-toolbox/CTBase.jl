# =============================================================================
# Concrete PathConstraint type
# =============================================================================

"""
$(TYPEDEF)

Parametric container for a path-constraint function together with its
constraint-kind, time-dependence, and variable-dependence traits.

The function returns the value `g(...)` of a path constraint evaluated along the
trajectory of an optimal control problem. The constraint-kind trait determines
which primal variables the constraint depends on (see
[`CTBase.Data.AbstractPathConstraint`](@ref)).

# Type Parameters
- `F`: concrete type of the wrapped function.
- `K <: AbstractConstraintKind`: `StateConstraintKind`, `ControlConstraintKind`, or `MixedConstraintKind`.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Fields
- `f::F`: the path-constraint function.

# Construction

Use the user-facing constructors `StateConstraint`, `ControlConstraint`, or `MixedConstraint`:

```julia
StateConstraint(g; is_autonomous = true, is_variable = false)     # default: g(x)
ControlConstraint(g; is_autonomous = true, is_variable = false)   # default: g(u)
MixedConstraint(g; is_autonomous = true, is_variable = false)     # default: g(x, u)
```

# Call Signatures

Every `PathConstraint` is callable via its **natural** signature (matching the
traits), and via the **uniform** signature `g(t, x, u, v)` (ignoring unused
arguments), used by flow integrators:

| Kind | Natural `(Aut, Fixed)` | Uniform |
|---|---|---|
| `StateConstraint` | `g(x)` | `g(t, x, u, v)` |
| `ControlConstraint` | `g(u)` | `g(t, x, u, v)` |
| `MixedConstraint` | `g(x, u)` | `g(t, x, u, v)` |

See also: [`CTBase.Data.AbstractPathConstraint`](@ref), [`CTBase.Data.StateConstraint`](@ref),
[`CTBase.Data.ControlConstraint`](@ref), [`CTBase.Data.MixedConstraint`](@ref),
[`CTBase.Traits.AbstractConstraintKind`](@ref).
"""
struct PathConstraint{
    F<:Function,
    K<:Traits.AbstractConstraintKind,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
} <: AbstractPathConstraint{K,TD,VD}
    f::F
end

# =============================================================================
# Internal keyword constructor — requires explicit constraint-kind type
# =============================================================================

"""
$(TYPEDSIGNATURES)

Internal constructor for `PathConstraint` with a specific constraint-kind type and trait flags.

# Arguments
- `f::Function`: The path-constraint function.
- `::Type{K}`: The constraint-kind trait type.
- `is_autonomous::Bool`: If true, constraint is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, constraint depends on variable (default: `__is_variable()`).

# Returns
- `PathConstraint`: A path constraint with appropriate traits.

See also: [`CTBase.Data.PathConstraint`](@ref), [`CTBase.Data.StateConstraint`](@ref),
[`CTBase.Data.ControlConstraint`](@ref), [`CTBase.Data.MixedConstraint`](@ref).
"""
function PathConstraint(
    f, ::Type{K}; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
) where {K<:Traits.AbstractConstraintKind}
    TD = is_autonomous ? Traits.Autonomous : Traits.NonAutonomous
    VD = is_variable ? Traits.NonFixed : Traits.Fixed
    return PathConstraint{typeof(f),K,TD,VD}(f)
end

# =============================================================================
# Typed constructor — trait types passed positionally
# =============================================================================

"""
$(TYPEDSIGNATURES)

Typed constructor for `PathConstraint` with explicit trait types.

# Arguments
- `f`: The path-constraint function.
- `::Type{K}`: The constraint-kind trait type.
- `::Type{TD}`: The time-dependence trait type.
- `::Type{VD}`: The variable-dependence trait type.

# Returns
- `PathConstraint`: A path constraint with the specified traits.

See also: [`CTBase.Data.PathConstraint`](@ref).
"""
function PathConstraint(
    f, ::Type{K}, ::Type{TD}, ::Type{VD}
) where {
    K<:Traits.AbstractConstraintKind,TD<:Traits.TimeDependence,VD<:Traits.VariableDependence
}
    return PathConstraint{typeof(f),K,TD,VD}(f)
end

# =============================================================================
# User-facing constructors
# =============================================================================

"""
$(TYPEDSIGNATURES)

Construct a pure state `PathConstraint`.

A state constraint depends on the state (and optionally time and variable), but
not on the control.

# Arguments
- `f::Function`: The path-constraint function.
- `is_autonomous::Bool`: If true, constraint is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, constraint depends on variable (default: `__is_variable()`).

# Example
```julia-repl
julia> using CTBase.Data

julia> g = StateConstraint(x -> x[1])
PathConstraint: state, autonomous, fixed (no variable)
  natural call: g(x)
  uniform call: g(t, x, u, v)
```

See also: [`CTBase.Data.ControlConstraint`](@ref), [`CTBase.Data.MixedConstraint`](@ref),
[`CTBase.Data.PathConstraint`](@ref).
"""
function StateConstraint(
    f; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
)
    return PathConstraint(
        f, Traits.StateConstraintKind; is_autonomous=is_autonomous, is_variable=is_variable
    )
end

"""
$(TYPEDSIGNATURES)

Construct a pure control `PathConstraint`.

A control constraint depends on the control (and optionally time and variable),
but not on the state.

# Arguments
- `f::Function`: The path-constraint function.
- `is_autonomous::Bool`: If true, constraint is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, constraint depends on variable (default: `__is_variable()`).

# Example
```julia-repl
julia> using CTBase.Data

julia> g = ControlConstraint(u -> u[1])
PathConstraint: control, autonomous, fixed (no variable)
  natural call: g(u)
  uniform call: g(t, x, u, v)
```

See also: [`CTBase.Data.StateConstraint`](@ref), [`CTBase.Data.MixedConstraint`](@ref),
[`CTBase.Data.PathConstraint`](@ref).
"""
function ControlConstraint(
    f; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
)
    return PathConstraint(
        f,
        Traits.ControlConstraintKind;
        is_autonomous=is_autonomous,
        is_variable=is_variable,
    )
end

"""
$(TYPEDSIGNATURES)

Construct a mixed state–control `PathConstraint`.

A mixed constraint depends on both the state and the control (and optionally
time and variable).

# Arguments
- `f::Function`: The path-constraint function.
- `is_autonomous::Bool`: If true, constraint is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, constraint depends on variable (default: `__is_variable()`).

# Example
```julia-repl
julia> using CTBase.Data

julia> g = MixedConstraint((x, u) -> x[1] + u[1])
PathConstraint: mixed, autonomous, fixed (no variable)
  natural call: g(x, u)
  uniform call: g(t, x, u, v)
```

See also: [`CTBase.Data.StateConstraint`](@ref), [`CTBase.Data.ControlConstraint`](@ref),
[`CTBase.Data.PathConstraint`](@ref).
"""
function MixedConstraint(
    f; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
)
    return PathConstraint(
        f, Traits.MixedConstraintKind; is_autonomous=is_autonomous, is_variable=is_variable
    )
end

# =============================================================================
# Natural call signatures — StateConstraint: g([t, ]x[, v])
# =============================================================================

function (g::PathConstraint{
    <:Function,Traits.StateConstraintKind,Traits.Autonomous,Traits.Fixed
})(
    x
)
    return g.f(x)
end
function (g::PathConstraint{
    <:Function,Traits.StateConstraintKind,Traits.NonAutonomous,Traits.Fixed
})(
    t, x
)
    return g.f(t, x)
end
function (g::PathConstraint{
    <:Function,Traits.StateConstraintKind,Traits.Autonomous,Traits.NonFixed
})(
    x, v
)
    return g.f(x, v)
end
function (g::PathConstraint{
    <:Function,Traits.StateConstraintKind,Traits.NonAutonomous,Traits.NonFixed
})(
    t, x, v
)
    return g.f(t, x, v)
end

# =============================================================================
# Natural call signatures — ControlConstraint: g([t, ]u[, v])
# =============================================================================

function (g::PathConstraint{
    <:Function,Traits.ControlConstraintKind,Traits.Autonomous,Traits.Fixed
})(
    u
)
    return g.f(u)
end
function (g::PathConstraint{
    <:Function,Traits.ControlConstraintKind,Traits.NonAutonomous,Traits.Fixed
})(
    t, u
)
    return g.f(t, u)
end
function (g::PathConstraint{
    <:Function,Traits.ControlConstraintKind,Traits.Autonomous,Traits.NonFixed
})(
    u, v
)
    return g.f(u, v)
end
function (g::PathConstraint{
    <:Function,Traits.ControlConstraintKind,Traits.NonAutonomous,Traits.NonFixed
})(
    t, u, v
)
    return g.f(t, u, v)
end

# =============================================================================
# Natural call signatures — MixedConstraint: g([t, ]x, u[, v])
# =============================================================================

function (g::PathConstraint{
    <:Function,Traits.MixedConstraintKind,Traits.Autonomous,Traits.Fixed
})(
    x, u
)
    return g.f(x, u)
end
function (g::PathConstraint{
    <:Function,Traits.MixedConstraintKind,Traits.NonAutonomous,Traits.Fixed
})(
    t, x, u
)
    return g.f(t, x, u)
end
function (g::PathConstraint{
    <:Function,Traits.MixedConstraintKind,Traits.Autonomous,Traits.NonFixed
})(
    x, u, v
)
    return g.f(x, u, v)
end
function (g::PathConstraint{
    <:Function,Traits.MixedConstraintKind,Traits.NonAutonomous,Traits.NonFixed
})(
    t, x, u, v
)
    return g.f(t, x, u, v)
end

# =============================================================================
# Uniform (t, x, u, v) call — used by flow integrators.
# Every combination forwards to its natural call, ignoring unused args.
# (Mixed, NonAutonomous, NonFixed) is already covered by the natural signature.
# =============================================================================

# StateConstraint — uniform (t, x, u, v), no control
function (g::PathConstraint{
    <:Function,Traits.StateConstraintKind,Traits.Autonomous,Traits.Fixed
})(
    _, x, _, _
)
    return g.f(x)
end
function (g::PathConstraint{
    <:Function,Traits.StateConstraintKind,Traits.NonAutonomous,Traits.Fixed
})(
    t, x, _, _
)
    return g.f(t, x)
end
function (g::PathConstraint{
    <:Function,Traits.StateConstraintKind,Traits.Autonomous,Traits.NonFixed
})(
    _, x, _, v
)
    return g.f(x, v)
end
function (g::PathConstraint{
    <:Function,Traits.StateConstraintKind,Traits.NonAutonomous,Traits.NonFixed
})(
    t, x, _, v
)
    return g.f(t, x, v)
end

# ControlConstraint — uniform (t, x, u, v), no state
function (g::PathConstraint{
    <:Function,Traits.ControlConstraintKind,Traits.Autonomous,Traits.Fixed
})(
    _, _, u, _
)
    return g.f(u)
end
function (g::PathConstraint{
    <:Function,Traits.ControlConstraintKind,Traits.NonAutonomous,Traits.Fixed
})(
    t, _, u, _
)
    return g.f(t, u)
end
function (g::PathConstraint{
    <:Function,Traits.ControlConstraintKind,Traits.Autonomous,Traits.NonFixed
})(
    _, _, u, v
)
    return g.f(u, v)
end
function (g::PathConstraint{
    <:Function,Traits.ControlConstraintKind,Traits.NonAutonomous,Traits.NonFixed
})(
    t, _, u, v
)
    return g.f(t, u, v)
end

# MixedConstraint — uniform (t, x, u, v)
function (g::PathConstraint{
    <:Function,Traits.MixedConstraintKind,Traits.Autonomous,Traits.Fixed
})(
    _, x, u, _
)
    return g.f(x, u)
end
function (g::PathConstraint{
    <:Function,Traits.MixedConstraintKind,Traits.NonAutonomous,Traits.Fixed
})(
    t, x, u, _
)
    return g.f(t, x, u)
end
function (g::PathConstraint{
    <:Function,Traits.MixedConstraintKind,Traits.Autonomous,Traits.NonFixed
})(
    _, x, u, v
)
    return g.f(x, u, v)
end
# (Mixed, NonAutonomous, NonFixed) — already covered by natural 4-arg

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a `PathConstraint` showing its traits and call signatures.

# Arguments
- `io::IO`: The IO stream.
- `pc::PathConstraint`: The path constraint object.

# Output
Displays three lines:
- Header with constraint-kind, time, and variable dependence traits
- Natural call signature
- Uniform call signature

See also: [`CTBase.Data.PathConstraint`](@ref).
"""
function Base.show(io::IO, ::PathConstraint{F,K,TD,VD}) where {F,K,TD,VD}
    header = "PathConstraint: $(_kind_label(K)), $(_td_label(TD)), $(_vd_label(VD))"
    natural = _natural_sig_pc(K, TD, VD)
    uniform = _uniform_sig_pc()
    println(io, header)
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: ", uniform)
end

"""
$(TYPEDSIGNATURES)

Display a `PathConstraint` in the REPL with the same format as the compact `show`.

This method is called automatically when displaying a path constraint in the Julia REPL.

# Arguments
- `io::IO`: The IO stream.
- `mime::MIME"text/plain"`: The MIME type.
- `pc::PathConstraint`: The path constraint object.

See also: [`CTBase.Data.PathConstraint`](@ref).
"""
function Base.show(
    io::IO, ::MIME"text/plain", pc::PathConstraint{F,K,TD,VD}
) where {F,K,TD,VD}
    return show(io, pc)
end
