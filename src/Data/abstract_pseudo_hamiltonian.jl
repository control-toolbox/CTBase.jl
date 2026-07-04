# =============================================================================
# AbstractPseudoHamiltonian — abstract supertype for pseudo-Hamiltonian functions
# =============================================================================

"""
$(TYPEDEF)

Abstract supertype for scalar pseudo-Hamiltonian functions together with their
time-dependence and variable-dependence traits.

A pseudo-Hamiltonian is a scalar function `H̃(t, x, p, u[, v]) → ℝ` that extends
the standard Hamiltonian with an explicit control argument `u`. Unlike
[`CTBase.Data.AbstractHamiltonian`](@ref), which encodes the control implicitly, a
pseudo-Hamiltonian takes the control as an additional argument, enabling
dynamic closed-loop flows where the control is computed from the
pseudo-Hamiltonian's maximisation condition.

# Type Parameters
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Notes
- All pseudo-Hamiltonian types support both natural and uniform call signatures.
- The uniform signature `(t, x, p, u, v)` is used internally by flow integrators.
- The dynamics trait is always `HamiltonianDynamics`, as pseudo-Hamiltonians
  involve both state and costate.

See also: [`CTBase.Data.PseudoHamiltonian`](@ref), [`CTBase.Data.AbstractHamiltonian`](@ref),
[`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
abstract type AbstractPseudoHamiltonian{
    TD<:Traits.TimeDependence,VD<:Traits.VariableDependence
} end

# =============================================================================
# Trait accessors for AbstractPseudoHamiltonian
# =============================================================================

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractPseudoHamiltonian` types support time-dependence queries.

# Returns
- `true`: Always returns `true` for pseudo-Hamiltonian types.

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Data.AbstractPseudoHamiltonian`](@ref).
"""
function Traits.has_time_dependence_trait(::AbstractPseudoHamiltonian)
    return true
end

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractPseudoHamiltonian` types support variable-dependence queries.

# Returns
- `true`: Always returns `true` for pseudo-Hamiltonian types.

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Data.AbstractPseudoHamiltonian`](@ref).
"""
function Traits.has_variable_dependence_trait(::AbstractPseudoHamiltonian)
    return true
end

"""
$(TYPEDSIGNATURES)

Return the time-dependence trait of a pseudo-Hamiltonian.

# Arguments
- `h̃::AbstractPseudoHamiltonian`: The pseudo-Hamiltonian object.

# Returns
- `TD`: The time-dependence type (`Autonomous` or `NonAutonomous`).

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Traits.TimeDependence`](@ref).
"""
function Traits.time_dependence(
    ::AbstractPseudoHamiltonian{TD,<:Traits.VariableDependence}
) where {TD<:Traits.TimeDependence}
    return TD
end

"""
$(TYPEDSIGNATURES)

Return the variable-dependence trait of a pseudo-Hamiltonian.

# Arguments
- `h̃::AbstractPseudoHamiltonian`: The pseudo-Hamiltonian object.

# Returns
- `VD`: The variable-dependence type (`Fixed` or `NonFixed`).

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
function Traits.variable_dependence(
    ::AbstractPseudoHamiltonian{<:Traits.TimeDependence,VD}
) where {VD<:Traits.VariableDependence}
    return VD
end

"""
$(TYPEDSIGNATURES)

Return the dynamics trait of an `AbstractPseudoHamiltonian`, namely
[`CTBase.Traits.HamiltonianDynamics`](@ref).

# Returns
- `CTBase.Traits.HamiltonianDynamics`: The dynamics trait.

See also: [`CTBase.Traits.dynamics_trait`](@ref), [`CTBase.Data.AbstractPseudoHamiltonian`](@ref).
"""
Traits.dynamics_trait(::AbstractPseudoHamiltonian) = Traits.HamiltonianDynamics
