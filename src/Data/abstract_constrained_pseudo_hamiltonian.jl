# =============================================================================
# AbstractConstrainedPseudoHamiltonian — abstract supertype for constrained
# pseudo-Hamiltonian functions H(t, x, p, u, μ, v)
# =============================================================================

"""
$(TYPEDEF)

Abstract supertype for scalar **constrained** pseudo-Hamiltonian functions together with
their time-dependence and variable-dependence traits.

A constrained pseudo-Hamiltonian is the function of the maximum principle for a problem
with path constraints:

```math
H(t, x, p, u, \\mu, v) = \\tilde H(t, x, p, u, v) + \\mu \\cdot g(t, x, u, v),
```

where the multiplier `μ` is an **explicit argument**, like the control `u`. The extremals
are given by the partial derivatives of `H` with respect to `x` and `p`, at fixed `u` and
`μ`; see [`CTBase.Data.freeze_multiplier`](@extref).

It is not an [`CTBase.Data.AbstractPseudoHamiltonian`](@extref): its call signatures have
one more argument.

# Type Parameters
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Notes
- All constrained pseudo-Hamiltonian types support both natural and uniform call
  signatures.
- The uniform signature `(t, x, p, u, μ, v)` is used internally by flows.
- The dynamics trait is always `HamiltonianDynamics`.

See also: [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref),
[`CTBase.Data.AbstractPseudoHamiltonian`](@extref),
[`CTBase.Data.ComposedConstrainedHamiltonian`](@extref).
"""
abstract type AbstractConstrainedPseudoHamiltonian{
    TD<:Traits.TimeDependence,VD<:Traits.VariableDependence
} end

# =============================================================================
# Trait accessors for AbstractConstrainedPseudoHamiltonian
# =============================================================================

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractConstrainedPseudoHamiltonian` types support time-dependence
queries.

See also: [`CTBase.Traits.time_dependence`](@extref),
[`CTBase.Data.AbstractConstrainedPseudoHamiltonian`](@extref).
"""
function Traits.has_time_dependence_trait(::AbstractConstrainedPseudoHamiltonian)
    return true
end

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractConstrainedPseudoHamiltonian` types support
variable-dependence queries.

See also: [`CTBase.Traits.variable_dependence`](@extref),
[`CTBase.Data.AbstractConstrainedPseudoHamiltonian`](@extref).
"""
function Traits.has_variable_dependence_trait(::AbstractConstrainedPseudoHamiltonian)
    return true
end

"""
$(TYPEDSIGNATURES)

Return the time-dependence trait of a constrained pseudo-Hamiltonian.

# Returns
- `TD`: The time-dependence type (`Autonomous` or `NonAutonomous`).

See also: [`CTBase.Traits.time_dependence`](@extref), [`CTBase.Traits.TimeDependence`](@extref).
"""
function Traits.time_dependence(
    ::AbstractConstrainedPseudoHamiltonian{TD,<:Traits.VariableDependence}
) where {TD<:Traits.TimeDependence}
    return TD
end

"""
$(TYPEDSIGNATURES)

Return the variable-dependence trait of a constrained pseudo-Hamiltonian.

# Returns
- `VD`: The variable-dependence type (`Fixed` or `NonFixed`).

See also: [`CTBase.Traits.variable_dependence`](@extref), [`CTBase.Traits.VariableDependence`](@extref).
"""
function Traits.variable_dependence(
    ::AbstractConstrainedPseudoHamiltonian{<:Traits.TimeDependence,VD}
) where {VD<:Traits.VariableDependence}
    return VD
end

"""
$(TYPEDSIGNATURES)

Return the dynamics trait of an `AbstractConstrainedPseudoHamiltonian`, namely
[`CTBase.Traits.HamiltonianDynamics`](@extref).

See also: [`CTBase.Traits.dynamics_trait`](@extref),
[`CTBase.Data.AbstractConstrainedPseudoHamiltonian`](@extref).
"""
function Traits.dynamics_trait(::AbstractConstrainedPseudoHamiltonian)
    return Traits.HamiltonianDynamics
end
