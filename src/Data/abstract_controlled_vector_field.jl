# =============================================================================
# AbstractControlledVectorField — abstract supertype for controlled vector fields
# =============================================================================

"""
$(TYPEDEF)

Abstract supertype for **controlled** vector-field functions together with their
time-dependence and variable-dependence traits.

A controlled vector field is a function `fc(t, x, u[, v])` returning the state
derivative, with an **explicit control argument** `u`. It is the state-space analogue
of [`CTBase.Data.AbstractPseudoHamiltonian`](@ref): where a pseudo-Hamiltonian carries
the control alongside the costate, a controlled vector field carries the control
alongside the state. It is always **out-of-place** (returns the derivative), so unlike
[`CTBase.Data.AbstractVectorField`](@ref) it has no mutability trait.

Composing a controlled vector field with an open-loop or closed-loop control law
eliminates the control and yields a plain [`CTBase.Data.ComposedVectorField`](@ref).

# Type Parameters
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Notes
- All controlled vector fields support both natural and uniform call signatures.
- The uniform signature `(t, x, u, v)` is used internally by composition.
- The dynamics trait is always `StateDynamics`.

See also: [`CTBase.Data.ControlledVectorField`](@ref), [`CTBase.Data.ComposedVectorField`](@ref),
[`CTBase.Data.AbstractPseudoHamiltonian`](@ref).
"""
abstract type AbstractControlledVectorField{
    TD<:Traits.TimeDependence,VD<:Traits.VariableDependence
} end

# =============================================================================
# Trait accessors
# =============================================================================

"""
$(TYPEDSIGNATURES)

Indicate that all `AbstractControlledVectorField` types support time-dependence queries.

See also: [`CTBase.Traits.time_dependence`](@ref).
"""
Traits.has_time_dependence_trait(::AbstractControlledVectorField) = true

"""
$(TYPEDSIGNATURES)

Indicate that all `AbstractControlledVectorField` types support variable-dependence queries.

See also: [`CTBase.Traits.variable_dependence`](@ref).
"""
Traits.has_variable_dependence_trait(::AbstractControlledVectorField) = true

"""
$(TYPEDSIGNATURES)

Return the time-dependence trait of a controlled vector field.

See also: [`CTBase.Traits.time_dependence`](@ref).
"""
function Traits.time_dependence(
    ::AbstractControlledVectorField{TD,<:Traits.VariableDependence}
) where {TD<:Traits.TimeDependence}
    return TD
end

"""
$(TYPEDSIGNATURES)

Return the variable-dependence trait of a controlled vector field.

See also: [`CTBase.Traits.variable_dependence`](@ref).
"""
function Traits.variable_dependence(
    ::AbstractControlledVectorField{<:Traits.TimeDependence,VD}
) where {VD<:Traits.VariableDependence}
    return VD
end

"""
$(TYPEDSIGNATURES)

Return the dynamics trait of an `AbstractControlledVectorField`, namely
[`CTBase.Traits.StateDynamics`](@ref).

See also: [`CTBase.Traits.dynamics_trait`](@ref).
"""
Traits.dynamics_trait(::AbstractControlledVectorField) = Traits.StateDynamics
