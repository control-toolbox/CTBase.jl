"""
$(TYPEDEF)

Abstract supertype for scalar Hamiltonian functions together with their
time-dependence and variable-dependence traits.

A Hamiltonian is a scalar function `H(t, x, p[, v]) → ℝ` from which a
Hamiltonian vector field can be derived via automatic differentiation.
Unlike vector fields, a Hamiltonian has no mutability trait (in-place vs
out-of-place) because a scalar return has no meaningful in-place form.

# Type Parameters
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Notes
- All Hamiltonian types support both natural and uniform call signatures.
- The uniform signature `(t, x, p, v)` is used internally by systems.

See also: [`CTBase.Data.Hamiltonian`](@ref), [`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
abstract type AbstractHamiltonian{TD<:Traits.TimeDependence,VD<:Traits.VariableDependence} end

# =============================================================================
# Trait accessors for AbstractHamiltonian
# =============================================================================

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractHamiltonian` types support time-dependence queries.

# Returns
- `true`: Always returns `true` for Hamiltonian types.

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Data.AbstractHamiltonian`](@ref).
"""
function Traits.has_time_dependence_trait(::AbstractHamiltonian)
    return true
end

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractHamiltonian` types support variable-dependence queries.

# Returns
- `true`: Always returns `true` for Hamiltonian types.

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Data.AbstractHamiltonian`](@ref).
"""
function Traits.has_variable_dependence_trait(::AbstractHamiltonian)
    return true
end

"""
$(TYPEDSIGNATURES)

Return the time-dependence trait of a Hamiltonian.

# Arguments
- `h::AbstractHamiltonian`: The Hamiltonian object.

# Returns
- `TD`: The time-dependence type (`Autonomous` or `NonAutonomous`).

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Traits.TimeDependence`](@ref).
"""
function Traits.time_dependence(
    ::AbstractHamiltonian{TD,<:Traits.VariableDependence}
) where {TD<:Traits.TimeDependence}
    return TD
end

"""
$(TYPEDSIGNATURES)

Return the variable-dependence trait of a Hamiltonian.

# Arguments
- `h::AbstractHamiltonian`: The Hamiltonian object.

# Returns
- `VD`: The variable-dependence type (`Fixed` or `NonFixed`).

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
function Traits.variable_dependence(
    ::AbstractHamiltonian{<:Traits.TimeDependence,VD}
) where {VD<:Traits.VariableDependence}
    return VD
end

"""
$(TYPEDSIGNATURES)

Return the dynamics trait of an `AbstractHamiltonian`, namely [`CTBase.Traits.HamiltonianDynamics`](@ref).

See also: [`CTBase.Traits.dynamics_trait`](@ref), [`CTBase.Data.AbstractHamiltonian`](@ref).
"""
Traits.dynamics_trait(::AbstractHamiltonian) = Traits.HamiltonianDynamics
