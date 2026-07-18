# ==============================================================================
# DifferentiationInterface — Concrete AD Backend Strategy
# ==============================================================================

"""
$(TYPEDEF)

Concrete AD backend strategy wrapping DifferentiationInterface.jl backends.

`DifferentiationInterface` stores a `:ad_backend` option (e.g., `AutoForwardDiff()`,
`AutoZygote()`) and uses it to compute gradients via the DifferentiationInterface.jl
ecosystem.

Parameterized on the execution device `P`:
- `DifferentiationInterface{CPU}`: default backend `AutoForwardDiff()` (default device);
- `DifferentiationInterface{GPU}`: default backend `AutoZygote()` (GPU-capable AD).

`DifferentiationInterface(...)` builds a `DifferentiationInterface{CPU}` — the device
parameterization is fully backward compatible with existing call sites.

# Arguments
- `backend`: The DifferentiationInterface.jl backend to use. Defaults to the device default
  (`AutoForwardDiff()` on CPU, `AutoZygote()` on GPU) from `ADTypes.jl` (a hard dependency).
- `kwargs...`: Additional options passed to `StrategyOptions`.

# Notes
 - `ADTypes.jl` is a hard dependency, so the default backend markers are always available in core;
   `AutoZygote()` is a marker type and needs no Zygote loaded to construct.
 - Gradient computation requires the `CTBaseDifferentiationInterface` extension.
 - Without the extension, the gradient methods throw `NotImplemented` with a helpful message.

See also: [`CTBase.Differentiation.AbstractADBackend`](@ref),
[`CTBase.Differentiation.hamiltonian_gradient`](@ref),
[`CTBase.Differentiation.variable_gradient`](@ref).
"""
struct DifferentiationInterface{
    P<:Union{Strategies.CPU,Strategies.GPU},O<:Strategies.StrategyOptions
} <: AbstractADBackend
    options::O
end

"""
$(TYPEDSIGNATURES)

Construct a `DifferentiationInterface{CPU}` (the default device). Equivalent to
`DifferentiationInterface{CPU}(...)`; delegates through
[`CTBase.Strategies.default_parameter`](@ref).

# Arguments
- `mode::Symbol=:strict`: Validation mode forwarded to `build_strategy_options`.
- `kwargs...`: Options passed to `StrategyOptions`. The AD backend is set through the
  `:ad_backend` option (aliases `backend` and `ad`), e.g. `backend=AutoForwardDiff()`;
  it defaults to the device default (`AutoForwardDiff()` on CPU).

# Returns
- `DifferentiationInterface{CPU}`: A new backend strategy instance.
"""
function DifferentiationInterface(; mode::Symbol=:strict, kwargs...)
    P = Strategies.default_parameter(DifferentiationInterface)
    return DifferentiationInterface{P}(; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Construct a parameterized `DifferentiationInterface{P}` for the execution device `P`
(`CPU` or `GPU`). The default `:ad_backend` is device-aware (`AutoForwardDiff()` on CPU,
`AutoZygote()` on GPU) and can be overridden through the `:ad_backend` option.

# Arguments
- `mode::Symbol=:strict`: Validation mode forwarded to `build_strategy_options`.
- `kwargs...`: Options passed to `StrategyOptions` (`:ad_backend`, aliases `backend`/`ad`).

# Returns
- `DifferentiationInterface{P}`: A new backend strategy instance.
"""
function DifferentiationInterface{P}(;
    mode::Symbol=:strict, kwargs...
) where {P<:Strategies.AbstractStrategyParameter}
    opts = Strategies.build_strategy_options(
        DifferentiationInterface{P}; mode=mode, kwargs...
    )
    return DifferentiationInterface{P,typeof(opts)}(opts)
end

# ==============================================================================
# CTBase.Strategies Contract
# ==============================================================================

"""
$(TYPEDSIGNATURES)

Return the strategy identifier for `DifferentiationInterface`.
"""
Strategies.id(::Type{<:DifferentiationInterface}) = :di

"""
$(TYPEDSIGNATURES)

Return the execution parameter type of a `DifferentiationInterface` strategy.

Extracts `P` from `DifferentiationInterface{P}` (`CPU` or `GPU`). Overrides the
`AbstractADBackend` family default (`nothing`) since this strategy is device-parameterized.

# Returns
- `Type{<:Union{CPU,GPU}}`: the execution parameter type.

See also: [`CTBase.Strategies.CPU`](@ref), [`CTBase.Strategies.GPU`](@ref)
"""
Strategies.parameter(
    ::Type{<:DifferentiationInterface{P}}
) where {P<:Union{Strategies.CPU,Strategies.GPU}} = P

"""
$(TYPEDSIGNATURES)

Return the default execution parameter for `DifferentiationInterface` when none is specified.

Returns `CPU`, so `DifferentiationInterface(...)` builds a `DifferentiationInterface{CPU}` and
every existing call site is unaffected by the device parameterization.

See also: [`CTBase.Strategies.CPU`](@ref)
"""
Strategies.default_parameter(::Type{<:DifferentiationInterface}) = Strategies.CPU

"""
$(TYPEDSIGNATURES)

Return a human-readable description of the `DifferentiationInterface` strategy.
"""
function Strategies.description(::Type{<:DifferentiationInterface})
    return "AD backend wrapping DifferentiationInterface.jl backends (e.g., AutoForwardDiff)."
end

"""
$(TYPEDSIGNATURES)

Return metadata defining `DifferentiationInterface{P}` options and their specifications.

The `:ad_backend` default is device-aware: `AutoForwardDiff()` on `CPU`, `AutoZygote()` on `GPU`
(via [`CTBase.Differentiation.__ad_backend`](@ref)). The bare `metadata(DifferentiationInterface)`
delegates here through `DifferentiationInterface{CPU}`.
"""
function Strategies.metadata(
    ::Type{<:DifferentiationInterface{P}}
) where {P<:Union{Strategies.CPU,Strategies.GPU}}
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:ad_backend,
            type=ADTypes.AbstractADType,
            default=__ad_backend(P),
            computed=true,  # Default is computed from parameter P (CPU→ForwardDiff, GPU→Zygote)
            description="DifferentiationInterface.jl backend (e.g. AutoForwardDiff() on CPU, AutoZygote() on GPU).",
            aliases=(:backend, :ad),
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Fallback for the non-parameterized `DifferentiationInterface` type that delegates to
`DifferentiationInterface{CPU}`. Preserves backward compatibility for
`metadata(DifferentiationInterface)`.
"""
function Strategies.metadata(::Type{DifferentiationInterface})
    return Strategies.metadata(
        DifferentiationInterface{Strategies.default_parameter(DifferentiationInterface)}
    )
end

"""
$(TYPEDSIGNATURES)

Extract the AD backend from a `DifferentiationInterface` strategy.

# Arguments
- `backend::DifferentiationInterface`: The AD backend.

# Returns
- `ADTypes.AbstractADType`: The concrete AD backend from the `:ad_backend` option.

# Notes
 - This extracts the `:ad_backend` option from the strategy's options.
 - Used by Hamiltonian vector-field getters to delegate to the AD-backed getter.

See also: [`CTBase.Differentiation.ad_backend`](@ref).
"""
function ad_backend(backend::DifferentiationInterface)
    return Base.get(Strategies.options(backend), Val(:ad_backend))
end
