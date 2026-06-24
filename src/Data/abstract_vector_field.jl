"""
$(TYPEDEF)

Abstract type for all vector fields in the control-toolbox ecosystem.

An `AbstractVectorField` represents a vector field function with time-dependence,
variable-dependence, and mutability traits encoded in the type parameters.

# Contract

All subtypes must have type parameters:
- `TD <: Traits.TimeDependence`: `Autonomous` or `NonAutonomous`
- `VD <: Traits.VariableDependence`: `Fixed` or `NonFixed`
- `MD <: Traits.AbstractMutabilityTrait`: `InPlace` or `OutOfPlace`

Trait accessors are implemented at the abstract level and work for all subtypes.

# Example

\`\`\`julia
using CTBase.Data
using CTBase.Traits

# Define a concrete vector field
struct MyVectorField{F, TD, VD, MD} <: AbstractVectorField{TD, VD, MD}
    f::F
end

# Trait accessors work automatically
vf = MyVectorField(x -> -x, Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace)
Traits.time_dependence(vf)  # Returns Autonomous
Traits.variable_dependence(vf)  # Returns Fixed
Traits.mutability(vf)  # Returns OutOfPlace
\`\`\`

See also: [`CTBase.Data.VectorField`](@ref), [`CTBase.Data.HamiltonianVectorField`](@ref), [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Traits.mutability`](@ref).
"""
abstract type AbstractVectorField{TD<:Traits.TimeDependence, VD<:Traits.VariableDependence, MD<:Traits.AbstractMutabilityTrait} end

# =============================================================================
# Trait accessors for AbstractVectorField
# =============================================================================

"""
$(TYPEDSIGNATURES)

Indicate that `AbstractVectorField` has the time-dependence trait.

This implementation declares that all vector fields support time-dependence queries.
Concrete `AbstractVectorField` instances have their time dependence encoded in the type parameter `TD`.

See also: [`CTBase.Traits.time_dependence`](@ref), [`CTBase.Data.AbstractVectorField`](@ref).
"""
function Traits.has_time_dependence_trait(::AbstractVectorField)
    return true
end

"""
$(TYPEDSIGNATURES)

Indicate that `AbstractVectorField` has the variable-dependence trait.

This implementation declares that all vector fields support variable-dependence queries.
Concrete `AbstractVectorField` instances have their variable dependence encoded in the type parameter `VD`.

See also: [`CTBase.Traits.variable_dependence`](@ref), [`CTBase.Data.AbstractVectorField`](@ref).
"""
function Traits.has_variable_dependence_trait(::AbstractVectorField)
    return true
end

"""
$(TYPEDSIGNATURES)

Indicate that `AbstractVectorField` has the mutability trait.

This implementation declares that all vector fields support mutability queries.
Concrete `AbstractVectorField` instances have their mutability encoded in the type parameter `MD`.

See also: [`CTBase.Traits.mutability`](@ref), [`CTBase.Data.AbstractVectorField`](@ref).
"""
function Traits.has_mutability_trait(::AbstractVectorField)
    return true
end

"""
$(TYPEDSIGNATURES)

Extract the time dependence trait from an AbstractVectorField.

# Returns
- `Type{<:TimeDependence}`: The time dependence trait type (Autonomous or NonAutonomous).

# Example
\`\`\`julia
using CTBase.Data
using CTBase.Traits

vf = Data.VectorField(x -> -x; is_autonomous=true)
Traits.time_dependence(vf)  # Returns Autonomous

hvf = Data.HamiltonianVectorField((t, x, p) -> (x, -p); is_autonomous=false)
Traits.time_dependence(hvf)  # Returns NonAutonomous
\`\`\`

See also: [`CTBase.Traits.has_time_dependence_trait`](@ref), `is_autonomous`.
"""
function Traits.time_dependence(vf::AbstractVectorField{TD, <:Traits.VariableDependence, <:Traits.AbstractMutabilityTrait}) where {TD <: Traits.TimeDependence}
    return TD
end

"""
$(TYPEDSIGNATURES)

Extract the variable dependence trait from an AbstractVectorField.

# Returns
- `Type{<:VariableDependence}`: The variable dependence trait type (Fixed or NonFixed).

# Example
\`\`\`julia
using CTBase.Data
using CTBase.Traits

vf = Data.VectorField(x -> -x; is_variable=false)
Traits.variable_dependence(vf)  # Returns Fixed

hvf = Data.HamiltonianVectorField((x, p, v) -> (x .* v, -p); is_variable=true)
Traits.variable_dependence(hvf)  # Returns NonFixed
\`\`\`

See also: [`CTBase.Traits.has_variable_dependence_trait`](@ref), `is_variable`.
"""
function Traits.variable_dependence(vf::AbstractVectorField{<:Traits.TimeDependence, VD, <:Traits.AbstractMutabilityTrait}) where {VD <: Traits.VariableDependence}
    return VD
end

"""
$(TYPEDSIGNATURES)

Extract the mutability trait from an AbstractVectorField.

# Returns
- `Type{<:AbstractMutabilityTrait}`: The mutability trait type (InPlace or OutOfPlace).

# Example
\`\`\`julia
using CTBase.Data
using CTBase.Traits

vf = Data.VectorField((dx, x) -> (dx .= -x; nothing))
Traits.mutability(vf)  # Returns InPlace

vf2 = Data.VectorField(x -> -x)
Traits.mutability(vf2)  # Returns OutOfPlace
\`\`\`

See also: [`CTBase.Traits.has_mutability_trait`](@ref), [`CTBase.Traits.is_inplace`](@ref).
"""
function Traits.mutability(vf::AbstractVectorField{<:Traits.TimeDependence, <:Traits.VariableDependence, MD}) where {MD <: Traits.AbstractMutabilityTrait}
    return MD
end

"""
$(TYPEDSIGNATURES)

Return the dynamics trait of an `AbstractVectorField`, namely [`CTBase.Traits.StateDynamics`](@ref).

See also: [`CTBase.Traits.dynamics_trait`](@ref), [`CTBase.Data.AbstractVectorField`](@ref).
"""
Traits.dynamics_trait(::AbstractVectorField) = Traits.StateDynamics
