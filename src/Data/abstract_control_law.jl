# =============================================================================
# AbstractControlLaw — abstract supertype for control laws
# =============================================================================

"""
$(TYPEDEF)

Abstract supertype for control laws together with their feedback,
time-dependence, and variable-dependence traits.

A control law is a function `u(...)` that provides the control input for an
optimal control problem. The feedback trait ([`CTBase.Traits.AbstractFeedback`](@ref))
determines which arguments the control law depends on:

- **Open-loop**: `u(t[, v])` — depends on time (and variable) only.
- **Closed-loop**: `u(t, x[, v])` — depends on time and state.
- **Dynamic closed-loop**: `u(t, x, p[, v])` — depends on time, state, and costate.

# Type Parameters
- `FB <: AbstractFeedback`: `OpenLoopFeedback`, `ClosedLoopFeedback`, or `DynClosedLoopFeedback`.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Notes
- All control law types support both natural and uniform call signatures.
- The uniform signature depends on the feedback trait:
  - OpenLoop: `u(t, v)` — no state, no costate.
  - ClosedLoop: `u(t, x, v)` — state but no costate.
  - DynClosedLoop: `u(t, x, p, v)` — state and costate.

See also: [`CTBase.Data.ControlLaw`](@ref), [`CTBase.Traits.AbstractFeedback`](@ref),
[`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
abstract type AbstractControlLaw{
    FB<:Traits.AbstractFeedback,TD<:Traits.TimeDependence,VD<:Traits.VariableDependence
} end

# =============================================================================
# Trait accessors for AbstractControlLaw
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return the feedback trait of a control law.

# Returns
- `FB`: The feedback type (`OpenLoopFeedback`, `ClosedLoopFeedback`, or `DynClosedLoopFeedback`).

See also: [`CTBase.Traits.feedback`](@ref), [`CTBase.Traits.AbstractFeedback`](@ref).
"""
function Traits.feedback(
    ::AbstractControlLaw{FB,<:Any,<:Any}
) where {FB<:Traits.AbstractFeedback}
    return FB
end

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractControlLaw` types support time-dependence queries.

# Returns
- `true`: Always returns `true` for control law types.

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Data.AbstractControlLaw`](@ref).
"""
function Traits.has_time_dependence_trait(::AbstractControlLaw)
    return true
end

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractControlLaw` types support variable-dependence queries.

# Returns
- `true`: Always returns `true` for control law types.

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Data.AbstractControlLaw`](@ref).
"""
function Traits.has_variable_dependence_trait(::AbstractControlLaw)
    return true
end

"""
$(TYPEDSIGNATURES)

Return the time-dependence trait of a control law.

# Arguments
- `cl::AbstractControlLaw`: The control law object.

# Returns
- `TD`: The time-dependence type (`Autonomous` or `NonAutonomous`).

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Traits.TimeDependence`](@ref).
"""
function Traits.time_dependence(
    ::AbstractControlLaw{<:Any,TD,<:Traits.VariableDependence}
) where {TD<:Traits.TimeDependence}
    return TD
end

"""
$(TYPEDSIGNATURES)

Return the variable-dependence trait of a control law.

# Arguments
- `cl::AbstractControlLaw`: The control law object.

# Returns
- `VD`: The variable-dependence type (`Fixed` or `NonFixed`).

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
function Traits.variable_dependence(
    ::AbstractControlLaw{<:Any,<:Traits.TimeDependence,VD}
) where {VD<:Traits.VariableDependence}
    return VD
end

# =============================================================================
# Dynamics trait — depends on feedback kind
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return the dynamics trait of an open-loop control law, namely [`CTBase.Traits.StateDynamics`](@ref).

Open-loop and closed-loop control laws do not involve the costate, so they are
associated with state dynamics.

# Returns
- `CTBase.Traits.StateDynamics`: The dynamics trait.

See also: [`CTBase.Traits.dynamics_trait`](@ref), [`CTBase.Traits.StateDynamics`](@ref).
"""
function Traits.dynamics_trait(::AbstractControlLaw{<:Traits.OpenLoopFeedback})
    return Traits.StateDynamics
end

"""
$(TYPEDSIGNATURES)

Return the dynamics trait of a closed-loop control law, namely [`CTBase.Traits.StateDynamics`](@ref).

# Returns
- `CTBase.Traits.StateDynamics`: The dynamics trait.

See also: [`CTBase.Traits.dynamics_trait`](@ref), [`CTBase.Traits.StateDynamics`](@ref).
"""
function Traits.dynamics_trait(::AbstractControlLaw{<:Traits.ClosedLoopFeedback})
    return Traits.StateDynamics
end

"""
$(TYPEDSIGNATURES)

Return the dynamics trait of a dynamic closed-loop control law, namely [`CTBase.Traits.HamiltonianDynamics`](@ref).

Dynamic closed-loop control laws depend on the costate, so they are associated
with Hamiltonian dynamics.

# Returns
- `CTBase.Traits.HamiltonianDynamics`: The dynamics trait.

See also: [`CTBase.Traits.dynamics_trait`](@ref), [`CTBase.Traits.HamiltonianDynamics`](@ref).
"""
function Traits.dynamics_trait(::AbstractControlLaw{<:Traits.DynClosedLoopFeedback})
    return Traits.HamiltonianDynamics
end

# =============================================================================
# Feedback predicates — dispatch on the FB type parameter
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return `true` if the control law is open-loop, `false` otherwise.

# Returns
- `Bool`: `true` if the feedback trait is `OpenLoopFeedback`, `false` otherwise.

See also: [`CTBase.Traits.OpenLoopFeedback`](@ref), [`CTBase.Traits.feedback`](@ref).
"""
Traits.is_open_loop(::AbstractControlLaw) = false
Traits.is_open_loop(::AbstractControlLaw{<:Traits.OpenLoopFeedback}) = true

"""
$(TYPEDSIGNATURES)

Return `true` if the control law is closed-loop, `false` otherwise.

# Returns
- `Bool`: `true` if the feedback trait is `ClosedLoopFeedback`, `false` otherwise.

See also: [`CTBase.Traits.ClosedLoopFeedback`](@ref), [`CTBase.Traits.feedback`](@ref).
"""
Traits.is_closed_loop(::AbstractControlLaw) = false
Traits.is_closed_loop(::AbstractControlLaw{<:Traits.ClosedLoopFeedback}) = true

"""
$(TYPEDSIGNATURES)

Return `true` if the control law is dynamic closed-loop, `false` otherwise.

# Returns
- `Bool`: `true` if the feedback trait is `DynClosedLoopFeedback`, `false` otherwise.

See also: [`CTBase.Traits.DynClosedLoopFeedback`](@ref), [`CTBase.Traits.feedback`](@ref).
"""
Traits.is_dyn_closed_loop(::AbstractControlLaw) = false
Traits.is_dyn_closed_loop(::AbstractControlLaw{<:Traits.DynClosedLoopFeedback}) = true
