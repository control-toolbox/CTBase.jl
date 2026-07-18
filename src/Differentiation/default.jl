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

"""
$(TYPEDSIGNATURES)

Default AD backend for CPU execution: `AutoForwardDiff()`.

See also: [`CTBase.Differentiation.DifferentiationInterface`](@ref), [`CTBase.Strategies.CPU`](@ref).
"""
__ad_backend(::Type{Strategies.CPU}) = ADTypes.AutoForwardDiff()

"""
$(TYPEDSIGNATURES)

Default AD backend for GPU execution: `AutoZygote()`.

`AutoZygote` is a GPU-capable AD backend (measured correct on `CuArray` inputs). The marker
type comes from `ADTypes` (a hard dependency) and needs no Zygote loaded to construct; Zygote
is required only when a gradient is actually evaluated.

See also: [`CTBase.Differentiation.DifferentiationInterface`](@ref), [`CTBase.Strategies.GPU`](@ref).
"""
__ad_backend(::Type{Strategies.GPU}) = ADTypes.AutoZygote()
