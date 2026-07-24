# =============================================================================
# AbstractPseudoHamiltonianVectorField — Abstract type for pseudo-Hamiltonian
# vector fields
# =============================================================================

"""
$(TYPEDEF)

Abstract supertype for pseudo-Hamiltonian vector fields.

A pseudo-Hamiltonian vector field represents the already-differentiated dynamics
`(ẋ, ṗ) = (dx, dp)(t, x, p, u[, v])` of a pseudo-Hamiltonian system, with an explicit
control argument `u` — the vector-field analogue of
[`CTBase.Data.AbstractPseudoHamiltonian`](@ref), exactly as
[`CTBase.Data.AbstractHamiltonianVectorField`](@ref) is the vector-field analogue of
[`CTBase.Data.AbstractHamiltonian`](@ref). It extends `AbstractVectorField` with the
additional structure required for Hamiltonian mechanics.

`AbstractPseudoHamiltonianVectorField` is a **sibling** of
[`CTBase.Data.AbstractHamiltonianVectorField`](@ref), not a subtype of it — mirroring how
[`CTBase.Data.AbstractPseudoHamiltonian`](@ref) is a sibling of, not a subtype of,
[`CTBase.Data.AbstractHamiltonian`](@ref): a pseudo-Hamiltonian vector field's natural
call signature carries an extra control argument `u` that a plain Hamiltonian vector
field does not have.

# Type Parameters
- `TD <: TimeDependence`: Time dependence trait (Autonomous or NonAutonomous)
- `VD <: VariableDependence`: Variable dependence trait (Fixed or NonFixed)
- `MD <: AbstractMutabilityTrait`: Mutability trait (InPlace or OutOfPlace)

# Interface Requirements

All subtypes must implement:
- Call signature: `(t, x, p, u)` or `(x, p, u)` depending on time dependence, plus `v`
  for non-fixed problems.
- Returns the combined state-costate derivative `(dx, dp)`.

See also: [`CTBase.Data.AbstractVectorField`](@ref), [`CTBase.Data.PseudoHamiltonianVectorField`](@ref),
[`CTBase.Data.AbstractHamiltonianVectorField`](@ref), [`CTBase.Data.AbstractPseudoHamiltonian`](@ref).
"""
abstract type AbstractPseudoHamiltonianVectorField{
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
} <: AbstractVectorField{TD,VD,MD} end

"""
$(TYPEDSIGNATURES)

Return the dynamics trait of an `AbstractPseudoHamiltonianVectorField`, namely
[`CTBase.Traits.HamiltonianDynamics`](@ref).

See also: [`CTBase.Traits.dynamics_trait`](@ref), [`CTBase.Data.AbstractPseudoHamiltonianVectorField`](@ref).
"""
Traits.dynamics_trait(::AbstractPseudoHamiltonianVectorField) = Traits.HamiltonianDynamics
