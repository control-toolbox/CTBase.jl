# =============================================================================
# Default values for the Differentiation module
# =============================================================================

"""
$(TYPEDSIGNATURES)

Default AD backend for CPU execution: `AutoForwardDiff()`.

See also: [`CTBase.Differentiation.DifferentiationInterface`](@ref), [`CTBase.Strategies.CPU`](@ref).
"""
__ad_backend(::Type{Strategies.CPU}) = ADTypes.AutoForwardDiff()

"""
$(TYPEDSIGNATURES)

Default AD backend for GPU execution: `AutoMooncake()`.

`AutoMooncake` was validated end-to-end on `CuArray` inputs, including through a mutating
in-place right-hand side (the OCP Hamiltonian's `dynamics!` shape) — see
[CTFlows PR #353](https://github.com/control-toolbox/CTFlows.jl/pull/353). `AutoZygote` was the
prior default; it is GPU-capable for some call shapes but was found to fail unexpectedly on
others (a non-mutating `hamiltonian_gradient` call), so it is no longer the default (still
selectable explicitly). The marker type comes from `ADTypes` (a hard dependency) and needs no
Mooncake loaded to construct; Mooncake is required only when a gradient is actually evaluated.

See also: [`CTBase.Differentiation.DifferentiationInterface`](@ref), [`CTBase.Strategies.GPU`](@ref).
"""
__ad_backend(::Type{Strategies.GPU}) = ADTypes.AutoMooncake()
