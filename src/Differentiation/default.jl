# =============================================================================
# Default values for the Differentiation module
# =============================================================================

"""
$(TYPEDSIGNATURES)

Default AD backend type for gradient computation.

Returns `AutoForwardDiff()` by default, meaning gradient getters use ForwardDiff
for differentiation unless specified otherwise.

# Returns
- `ADTypes.AutoForwardDiff`: the default automatic differentiation backend.

See also: [`CTBase.Differentiation.DifferentiationInterface`](@ref).
"""
__ad_backend() = ADTypes.AutoForwardDiff()
