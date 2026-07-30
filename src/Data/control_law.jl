# =============================================================================
# Concrete ControlLaw type
# =============================================================================

"""
$(TYPEDEF)

Parametric container for a control law function together with its feedback,
time-dependence, and variable-dependence traits.

The function provides the control input `u(...)` for an optimal control problem.
The feedback trait determines which arguments the control law depends on (see
[`CTBase.Data.AbstractControlLaw`](@ref)).

# Type Parameters
- `F`: concrete type of the wrapped function.
- `FB <: AbstractFeedback`: `OpenLoopFeedback`, `ClosedLoopFeedback`, or `DynClosedLoopFeedback`.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Fields
- `f::F`: the control law function.

# Construction

Use the user-facing constructors `OpenLoop`, `ClosedLoop`, or `DynClosedLoop`:

```julia
OpenLoop(u; is_variable = false)                               # default: u(t)
ClosedLoop(u; is_autonomous = true, is_variable = false)      # default: u(x)
DynClosedLoop(u; is_autonomous = true, is_variable = false)   # default: u(x, p)
```

`OpenLoop`'s `is_autonomous` is not a real choice — an open-loop control is
unconditionally `NonAutonomous` and always depends on time (see
[`CTBase.Data.OpenLoop`](@ref)).

# Call Signatures

Every `ControlLaw` is callable via its **natural** signature (matching the
traits), and via a **uniform** signature that depends on the feedback trait:

| Feedback | Natural `(Aut, Fixed)` | Uniform |
|---|---|---|
| `OpenLoop` | `u(t)` (`Aut` is always `NonAutonomous`) | `u(t, v)` |
| `ClosedLoop` | `u(x)` | `u(t, x, v)` |
| `DynClosedLoop` | `u(x, p)` | `u(t, x, p, v)` |

The uniform signature is used by flow integrators. Unused arguments are ignored.

See also: [`CTBase.Data.AbstractControlLaw`](@ref), [`CTBase.Data.OpenLoop`](@ref),
[`CTBase.Data.ClosedLoop`](@ref), [`CTBase.Data.DynClosedLoop`](@ref),
[`CTBase.Traits.AbstractFeedback`](@ref).
"""
struct ControlLaw{
    F<:Function,
    FB<:Traits.AbstractFeedback,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
} <: AbstractControlLaw{FB,TD,VD}
    f::F
end

# =============================================================================
# Internal keyword constructor — requires explicit feedback type
# =============================================================================

"""
$(TYPEDSIGNATURES)

Internal constructor for `ControlLaw` with a specific feedback type and trait flags.

# Arguments
- `f::Function`: The control law function.
- `::Type{FB}`: The feedback trait type.
- `is_autonomous::Bool`: If true, control law is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, control law depends on variable (default: `__is_variable()`).

# Returns
- `ControlLaw`: A control law with appropriate traits.

See also: [`CTBase.Data.ControlLaw`](@ref), [`CTBase.Data.OpenLoop`](@ref),
[`CTBase.Data.ClosedLoop`](@ref), [`CTBase.Data.DynClosedLoop`](@ref).
"""
function ControlLaw(
    f, ::Type{FB}; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
) where {FB<:Traits.AbstractFeedback}
    TD = is_autonomous ? Traits.Autonomous : Traits.NonAutonomous
    VD = is_variable ? Traits.NonFixed : Traits.Fixed
    return ControlLaw{typeof(f),FB,TD,VD}(f)
end

"""
$(TYPEDSIGNATURES)

Internal constructor for an `OpenLoopFeedback` `ControlLaw`.

Unlike the generic internal keyword constructor above, this one has no
`is_autonomous` keyword: an `OpenLoop` control law always depends on time —
`TD` is unconditionally `Traits.NonAutonomous`. This is the low-level
constructor `OpenLoop` delegates to; it is more specific than the generic
`ControlLaw(f, ::Type{FB}; is_autonomous, is_variable)` method and so wins
dispatch whenever `FB` is exactly `Traits.OpenLoopFeedback`.

# Arguments
- `f::Function`: The control law function, `f(t)` or `f(t, v)`.
- `is_variable::Bool`: If true, control law depends on variable (default: `__is_variable()`).

# Returns
- `ControlLaw`: An open-loop control law.

See also: [`CTBase.Data.ControlLaw`](@ref), [`CTBase.Data.OpenLoop`](@ref).
"""
function ControlLaw(f, ::Type{Traits.OpenLoopFeedback}; is_variable::Bool=__is_variable())
    VD = is_variable ? Traits.NonFixed : Traits.Fixed
    return ControlLaw{typeof(f),Traits.OpenLoopFeedback,Traits.NonAutonomous,VD}(f)
end

# =============================================================================
# Typed constructor — trait types passed positionally
# =============================================================================

"""
$(TYPEDSIGNATURES)

Typed constructor for `ControlLaw` with explicit trait types.

# Arguments
- `f`: The control law function.
- `::Type{FB}`: The feedback trait type.
- `::Type{TD}`: The time-dependence trait type.
- `::Type{VD}`: The variable-dependence trait type.

# Returns
- `ControlLaw`: A control law with the specified traits.

See also: [`CTBase.Data.ControlLaw`](@ref).
"""
function ControlLaw(
    f, ::Type{FB}, ::Type{TD}, ::Type{VD}
) where {
    FB<:Traits.AbstractFeedback,TD<:Traits.TimeDependence,VD<:Traits.VariableDependence
}
    return ControlLaw{typeof(f),FB,TD,VD}(f)
end

"""
$(TYPEDSIGNATURES)

Reject an `Autonomous` `OpenLoopFeedback` control law.

An open-loop control law always depends on time — `u(t)` (or `u(t, v)`) — so
`OpenLoopFeedback` combined with `Autonomous` is not a valid combination of
traits: autonomy is a property of the OCP, not of an open-loop control (see
control-toolbox/CTBase.jl#515).

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): Always.

See also: [`CTBase.Data.ControlLaw`](@ref), [`CTBase.Data.OpenLoop`](@ref).
"""
function ControlLaw(
    _f, ::Type{Traits.OpenLoopFeedback}, ::Type{Traits.Autonomous}, ::Type{VD}
) where {VD<:Traits.VariableDependence}
    throw(
        Exceptions.IncorrectArgument(
            "OpenLoop control laws cannot be Autonomous: an open-loop control always depends on time, u(t) (or u(t, v))";
            suggestion="Use OpenLoop(f; is_variable).",
            context="ControlLaw typed constructor — OpenLoopFeedback",
        ),
    )
end

# =============================================================================
# User-facing constructors
# =============================================================================

"""
$(TYPEDSIGNATURES)

Construct an open-loop `ControlLaw`.

An open-loop control law always depends on time (and optionally the
variable) — `u(t)` or `u(t, v)` — never on the state or costate. Unlike
`ClosedLoop`/`DynClosedLoop`, `OpenLoop` is unconditionally `NonAutonomous`:
autonomy is a property of the OCP, not of an open-loop control (see
control-toolbox/CTBase.jl#515), so `is_autonomous` is not offered as a real
choice at construction (see the `is_autonomous` keyword below) — but
`Traits.time_dependence`/`Traits.is_autonomous` still answer normally on the
constructed law, always `NonAutonomous`/`false`.

# Arguments
- `f::Function`: The control law function, `f(t)` or `f(t, v)`.
- `is_autonomous`: **Misuse detector only** — has no effect on the constructed
  law. Left at its default (`CTBase.Core.NotProvided`), nothing happens.
  Passed explicitly (`true` or `false`), a warning is emitted explaining that
  `OpenLoop` always depends on time.
- `is_variable::Bool`: If true, control law depends on variable (default: `__is_variable()`).

# Example
```julia-repl
julia> using CTBase.Data

julia> u = OpenLoop(t -> 1.0)
ControlLaw: open-loop, fixed (no variable)
  natural call: u(t)
  uniform call: u(t, v)

julia> u = OpenLoop((t, v) -> t * v; is_variable=true)
ControlLaw: open-loop, variable
  natural call: u(t, v)
  uniform call: u(t, v)
```

See also: [`CTBase.Data.ClosedLoop`](@ref), [`CTBase.Data.DynClosedLoop`](@ref),
[`CTBase.Data.ControlLaw`](@ref).
"""
function OpenLoop(
    f;
    is_autonomous::Union{Core.NotProvidedType,Bool}=Core.NotProvided,
    is_variable::Bool=__is_variable(),
)
    if is_autonomous !== Core.NotProvided
        @warn """
        `is_autonomous` has no effect on OpenLoop

        Unlike ClosedLoop and DynClosedLoop, an open-loop control always depends on time: u(t) (or u(t, v)). Autonomy is a property of the OCP, not of an open-loop control, so this keyword is ignored.

        See control-toolbox/CTBase.jl#515.
        """
    end
    return ControlLaw(f, Traits.OpenLoopFeedback; is_variable=is_variable)
end

"""
$(TYPEDSIGNATURES)

Construct a closed-loop `ControlLaw`.

A closed-loop control law depends on the state (and optionally time and
variable), but not on the costate.

# Arguments
- `f::Function`: The control law function.
- `is_autonomous::Bool`: If true, control law is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, control law depends on variable (default: `__is_variable()`).

# Example
```julia-repl
julia> using CTBase.Data

julia> u = ClosedLoop(x -> -x)
ControlLaw: closed-loop, autonomous, fixed (no variable)
  natural call: u(x)
  uniform call: u(t, x, v)
```

See also: [`CTBase.Data.OpenLoop`](@ref), [`CTBase.Data.DynClosedLoop`](@ref),
[`CTBase.Data.ControlLaw`](@ref).
"""
function ClosedLoop(
    f; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
)
    return ControlLaw(
        f, Traits.ClosedLoopFeedback; is_autonomous=is_autonomous, is_variable=is_variable
    )
end

"""
$(TYPEDSIGNATURES)

Construct a dynamic closed-loop `ControlLaw`.

A dynamic closed-loop control law depends on both the state and the costate
(and optionally time and variable).

# Arguments
- `f::Function`: The control law function.
- `is_autonomous::Bool`: If true, control law is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, control law depends on variable (default: `__is_variable()`).

# Example
```julia-repl
julia> using CTBase.Data

julia> u = DynClosedLoop((x, p) -> -x - p)
ControlLaw: dyn-closed-loop, autonomous, fixed (no variable)
  natural call: u(x, p)
  uniform call: u(t, x, p, v)
```

See also: [`CTBase.Data.OpenLoop`](@ref), [`CTBase.Data.ClosedLoop`](@ref),
[`CTBase.Data.ControlLaw`](@ref).
"""
function DynClosedLoop(
    f; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
)
    return ControlLaw(
        f,
        Traits.DynClosedLoopFeedback;
        is_autonomous=is_autonomous,
        is_variable=is_variable,
    )
end

# =============================================================================
# Natural call signatures — OpenLoop
# OpenLoop's TimeDependence trait is fixed to NonAutonomous (see the
# OpenLoopFeedback constructors above), so only these two methods exist —
# there is no Autonomous/zero-argument form.
# =============================================================================

function (cl::ControlLaw{
    <:Function,Traits.OpenLoopFeedback,Traits.NonAutonomous,Traits.Fixed
})(
    t
)
    return cl.f(t)
end
function (cl::ControlLaw{
    <:Function,Traits.OpenLoopFeedback,Traits.NonAutonomous,Traits.NonFixed
})(
    t, v
)
    return cl.f(t, v)
end

# =============================================================================
# Natural call signatures — ClosedLoop
# =============================================================================

function (cl::ControlLaw{
    <:Function,Traits.ClosedLoopFeedback,Traits.Autonomous,Traits.Fixed
})(
    x
)
    return cl.f(x)
end
function (cl::ControlLaw{
    <:Function,Traits.ClosedLoopFeedback,Traits.NonAutonomous,Traits.Fixed
})(
    t, x
)
    return cl.f(t, x)
end
function (cl::ControlLaw{
    <:Function,Traits.ClosedLoopFeedback,Traits.Autonomous,Traits.NonFixed
})(
    x, v
)
    return cl.f(x, v)
end
function (cl::ControlLaw{
    <:Function,Traits.ClosedLoopFeedback,Traits.NonAutonomous,Traits.NonFixed
})(
    t, x, v
)
    return cl.f(t, x, v)
end

# =============================================================================
# Natural call signatures — DynClosedLoop
# =============================================================================

function (cl::ControlLaw{
    <:Function,Traits.DynClosedLoopFeedback,Traits.Autonomous,Traits.Fixed
})(
    x, p
)
    return cl.f(x, p)
end
function (cl::ControlLaw{
    <:Function,Traits.DynClosedLoopFeedback,Traits.NonAutonomous,Traits.Fixed
})(
    t, x, p
)
    return cl.f(t, x, p)
end
function (cl::ControlLaw{
    <:Function,Traits.DynClosedLoopFeedback,Traits.Autonomous,Traits.NonFixed
})(
    x, p, v
)
    return cl.f(x, p, v)
end
function (cl::ControlLaw{
    <:Function,Traits.DynClosedLoopFeedback,Traits.NonAutonomous,Traits.NonFixed
})(
    t, x, p, v
)
    return cl.f(t, x, p, v)
end

# =============================================================================
# Uniform call — used by flow integrators
# OpenLoop: u(t, v) — no state, no costate (open-loop by definition)
# ClosedLoop: u(t, x, v) — state but no costate (controlled dynamics flow)
# DynClosedLoop: u(t, x, p, v) — costate needed (Hamiltonian flow)
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
# =============================================================================

# OpenLoop — uniform (t, v), no state (open-loop by definition). TD is
# unconditionally NonAutonomous for OpenLoop, so only the Fixed case needs an
# explicit uniform method; NonFixed is already covered by the natural 2-arg
# method above.
function (cl::ControlLaw{
    <:Function,Traits.OpenLoopFeedback,Traits.NonAutonomous,Traits.Fixed
})(
    t, v
)
    return cl.f(t)
end
# NonAutonomous, NonFixed — already covered by natural 2-arg

# ClosedLoop — uniform (t, x, v)
function (cl::ControlLaw{
    <:Function,Traits.ClosedLoopFeedback,Traits.Autonomous,Traits.Fixed
})(
    t, x, v
)
    return cl.f(x)
end
function (cl::ControlLaw{
    <:Function,Traits.ClosedLoopFeedback,Traits.NonAutonomous,Traits.Fixed
})(
    t, x, v
)
    return cl.f(t, x)
end
function (cl::ControlLaw{
    <:Function,Traits.ClosedLoopFeedback,Traits.Autonomous,Traits.NonFixed
})(
    t, x, v
)
    return cl.f(x, v)
end
# NonAutonomous, NonFixed — already covered by natural 3-arg

# DynClosedLoop — uniform (t, x, p, v)
function (cl::ControlLaw{
    <:Function,Traits.DynClosedLoopFeedback,Traits.Autonomous,Traits.Fixed
})(
    t, x, p, v
)
    return cl.f(x, p)
end
function (cl::ControlLaw{
    <:Function,Traits.DynClosedLoopFeedback,Traits.NonAutonomous,Traits.Fixed
})(
    t, x, p, v
)
    return cl.f(t, x, p)
end
function (cl::ControlLaw{
    <:Function,Traits.DynClosedLoopFeedback,Traits.Autonomous,Traits.NonFixed
})(
    t, x, p, v
)
    return cl.f(x, p, v)
end
# NonAutonomous, NonFixed — already covered by natural 4-arg

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a `ControlLaw` showing its traits and call signatures.

# Arguments
- `io::IO`: The IO stream.
- `cl::ControlLaw`: The control law object.

# Output
Displays three lines:
- Header with feedback, time, and variable dependence traits
- Natural call signature
- Uniform call signature

See also: [`CTBase.Data.ControlLaw`](@ref).
"""
function Base.show(
    io::IO, ::ControlLaw{F,FB,TD,VD}
) where {
    F<:Function,
    FB<:Traits.AbstractFeedback,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
}
    header = "ControlLaw: $(_fb_label(FB)), $(_td_label(TD)), $(_vd_label(VD))"
    natural = _natural_sig_cl(FB, TD, VD)
    uniform = _uniform_sig_cl(FB)
    println(io, header)
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: ", uniform)
end

"""
$(TYPEDSIGNATURES)

Display a compact representation of an `OpenLoop` `ControlLaw`.

More specific than the generic `Base.show` above: `OpenLoop`'s
`TimeDependence` is fixed to `NonAutonomous` and therefore uninformative to
display, so the header omits the time-dependence label (unlike
`ClosedLoop`/`DynClosedLoop`, where it is a real choice).

See also: [`CTBase.Data.ControlLaw`](@ref), [`CTBase.Data.OpenLoop`](@ref).
"""
function Base.show(
    io::IO, ::ControlLaw{F,FB,TD,VD}
) where {
    F<:Function,
    FB<:Traits.OpenLoopFeedback,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
}
    header = "ControlLaw: $(_fb_label(FB)), $(_vd_label(VD))"
    natural = _natural_sig_cl(FB, TD, VD)
    uniform = _uniform_sig_cl(FB)
    println(io, header)
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: ", uniform)
end

"""
$(TYPEDSIGNATURES)

Display a `ControlLaw` in the REPL with the same format as the compact `show`.

This method is called automatically when displaying a control law in the Julia REPL.

# Arguments
- `io::IO`: The IO stream.
- `mime::MIME"text/plain"`: The MIME type.
- `cl::ControlLaw`: The control law object.

See also: [`CTBase.Data.ControlLaw`](@ref).
"""
function Base.show(
    io::IO, ::MIME"text/plain", cl::ControlLaw{F,FB,TD,VD}
) where {
    F<:Function,
    FB<:Traits.AbstractFeedback,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
}
    return show(io, cl)
end
