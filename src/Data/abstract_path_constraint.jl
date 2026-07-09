# =============================================================================
# AbstractPathConstraint — abstract supertype for path constraints
# =============================================================================

"""
$(TYPEDEF)

Abstract supertype for path constraints together with their constraint-kind,
time-dependence, and variable-dependence traits.

A path constraint is a function `g(...)` evaluated along the trajectory of an
optimal control problem. The constraint-kind trait
([`CTBase.Traits.AbstractConstraintKind`](@ref)) determines which primal variables the
constraint depends on:

- **State**: `g(x)` — depends on the state (and optionally time and variable).
- **Control**: `g(u)` — depends on the control (and optionally time and variable).
- **Mixed**: `g(x, u)` — depends on both state and control.

# Type Parameters
- `K <: AbstractConstraintKind`: `StateConstraintKind`, `ControlConstraintKind`, or `MixedConstraintKind`.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Notes
- All path constraint types support both natural and uniform call signatures.
- The uniform signature is always `g(t, x, u, v)`, ignoring the unused arguments.

See also: [`CTBase.Data.PathConstraint`](@ref), [`CTBase.Traits.AbstractConstraintKind`](@ref),
[`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
abstract type AbstractPathConstraint{
    K<:Traits.AbstractConstraintKind,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
} end

# =============================================================================
# Trait accessors for AbstractPathConstraint
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return the constraint-kind trait of a path constraint.

# Returns
- `K`: The constraint-kind type (`StateConstraintKind`, `ControlConstraintKind`, or `MixedConstraintKind`).

See also: [`CTBase.Traits.constraint_kind`](@ref), [`CTBase.Traits.AbstractConstraintKind`](@ref).
"""
function Traits.constraint_kind(
    ::AbstractPathConstraint{K,<:Any,<:Any}
) where {K<:Traits.AbstractConstraintKind}
    return K
end

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractPathConstraint` types support time-dependence queries.

# Returns
- `true`: Always returns `true` for path constraint types.

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Data.AbstractPathConstraint`](@ref).
"""
function Traits.has_time_dependence_trait(::AbstractPathConstraint)
    return true
end

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractPathConstraint` types support variable-dependence queries.

# Returns
- `true`: Always returns `true` for path constraint types.

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Data.AbstractPathConstraint`](@ref).
"""
function Traits.has_variable_dependence_trait(::AbstractPathConstraint)
    return true
end

"""
$(TYPEDSIGNATURES)

Return the time-dependence trait of a path constraint.

# Arguments
- `pc::AbstractPathConstraint`: The path constraint object.

# Returns
- `TD`: The time-dependence type (`Autonomous` or `NonAutonomous`).

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Traits.TimeDependence`](@ref).
"""
function Traits.time_dependence(
    ::AbstractPathConstraint{<:Any,TD,<:Traits.VariableDependence}
) where {TD<:Traits.TimeDependence}
    return TD
end

"""
$(TYPEDSIGNATURES)

Return the variable-dependence trait of a path constraint.

# Arguments
- `pc::AbstractPathConstraint`: The path constraint object.

# Returns
- `VD`: The variable-dependence type (`Fixed` or `NonFixed`).

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
function Traits.variable_dependence(
    ::AbstractPathConstraint{<:Any,<:Traits.TimeDependence,VD}
) where {VD<:Traits.VariableDependence}
    return VD
end

# =============================================================================
# Constraint-kind predicates — dispatch on the K type parameter
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return `true` if the path constraint is a pure state constraint, `false` otherwise.

# Returns
- `Bool`: `true` if the constraint-kind trait is `StateConstraintKind`, `false` otherwise.

See also: [`CTBase.Traits.StateConstraintKind`](@ref), [`CTBase.Traits.constraint_kind`](@ref).
"""
Traits.is_state_constraint(::AbstractPathConstraint) = false
Traits.is_state_constraint(::AbstractPathConstraint{<:Traits.StateConstraintKind}) = true

"""
$(TYPEDSIGNATURES)

Return `true` if the path constraint is a pure control constraint, `false` otherwise.

# Returns
- `Bool`: `true` if the constraint-kind trait is `ControlConstraintKind`, `false` otherwise.

See also: [`CTBase.Traits.ControlConstraintKind`](@ref), [`CTBase.Traits.constraint_kind`](@ref).
"""
Traits.is_control_constraint(::AbstractPathConstraint) = false
Traits.is_control_constraint(::AbstractPathConstraint{<:Traits.ControlConstraintKind}) = true

"""
$(TYPEDSIGNATURES)

Return `true` if the path constraint is a mixed state–control constraint, `false` otherwise.

# Returns
- `Bool`: `true` if the constraint-kind trait is `MixedConstraintKind`, `false` otherwise.

See also: [`CTBase.Traits.MixedConstraintKind`](@ref), [`CTBase.Traits.constraint_kind`](@ref).
"""
Traits.is_mixed_constraint(::AbstractPathConstraint) = false
Traits.is_mixed_constraint(::AbstractPathConstraint{<:Traits.MixedConstraintKind}) = true
