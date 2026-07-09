"""
$(TYPEDEF)

Abstract supertype for path-constraint multiplier functions together with their
time-dependence and variable-dependence traits.

A multiplier is a function `μ(t, x, p[, v])` returning the Lagrange multiplier
associated with a path constraint. It has the same call structure as a
[`CTBase.Data.AbstractHamiltonian`](@ref) (it depends on the state and costate), but
carries no dynamics semantics of its own.

# Type Parameters
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Notes
- All multiplier types support both natural and uniform call signatures.
- The uniform signature `(t, x, p, v)` is used internally by flows.

See also: [`CTBase.Data.Multiplier`](@ref), [`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
abstract type AbstractMultiplier{TD<:Traits.TimeDependence,VD<:Traits.VariableDependence} end

# =============================================================================
# Trait accessors for AbstractMultiplier
# =============================================================================

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractMultiplier` types support time-dependence queries.

# Returns
- `true`: Always returns `true` for multiplier types.

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Data.AbstractMultiplier`](@ref).
"""
function Traits.has_time_dependence_trait(::AbstractMultiplier)
    return true
end

"""
$(TYPEDSIGNATURES)

Indicates that all `AbstractMultiplier` types support variable-dependence queries.

# Returns
- `true`: Always returns `true` for multiplier types.

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Data.AbstractMultiplier`](@ref).
"""
function Traits.has_variable_dependence_trait(::AbstractMultiplier)
    return true
end

"""
$(TYPEDSIGNATURES)

Return the time-dependence trait of a multiplier.

# Arguments
- `m::AbstractMultiplier`: The multiplier object.

# Returns
- `TD`: The time-dependence type (`Autonomous` or `NonAutonomous`).

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Traits.TimeDependence`](@ref).
"""
function Traits.time_dependence(
    ::AbstractMultiplier{TD,<:Traits.VariableDependence}
) where {TD<:Traits.TimeDependence}
    return TD
end

"""
$(TYPEDSIGNATURES)

Return the variable-dependence trait of a multiplier.

# Arguments
- `m::AbstractMultiplier`: The multiplier object.

# Returns
- `VD`: The variable-dependence type (`Fixed` or `NonFixed`).

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
function Traits.variable_dependence(
    ::AbstractMultiplier{<:Traits.TimeDependence,VD}
) where {VD<:Traits.VariableDependence}
    return VD
end
