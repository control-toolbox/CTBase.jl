# =============================================================================
# Default values for trait-carrying object constructors (VectorField,
# Hamiltonian, HamiltonianVectorField). Moved from CTFlows.Common so that
# CTBase.Data is self-contained.
# =============================================================================

"""
$(TYPEDSIGNATURES)

Default value for the autonomous flag in time-dependent object constructors.

Returns `true` by default, meaning objects do not explicitly depend on time
unless specified otherwise.
"""
__is_autonomous()::Bool = true

"""
$(TYPEDSIGNATURES)

Default value for the variable flag in time-dependent object constructors.

Returns `false` by default, meaning objects have fixed parameters unless
specified otherwise.
"""
__is_variable()::Bool = false

"""
$(TYPEDSIGNATURES)

Default value for the in-place flag in vector field constructors.

Returns `nothing` by default, meaning mutability is auto-detected from the
function signature unless specified otherwise.

# Returns
- `Nothing`: The default value for the `is_inplace` parameter.

See also: [`CTBase.Data.VectorField`](@ref), [`CTBase.Data.HamiltonianVectorField`](@ref).
"""
__is_inplace() = nothing
