# ==============================================================================
# DifferentiationInterface — Concrete AD Backend Strategy
# ==============================================================================

"""
$(TYPEDEF)

Concrete AD backend strategy wrapping DifferentiationInterface.jl backends.

`DifferentiationInterface` stores a `:ad_backend` option (e.g., `AutoForwardDiff()`,
`AutoZygote()`) and uses it to compute gradients via the DifferentiationInterface.jl
ecosystem.

# Arguments
- `backend=AutoForwardDiff()`: The DifferentiationInterface.jl backend to use. Defaults
  to `AutoForwardDiff()` from `ADTypes.jl` (a hard dependency).
- `kwargs...`: Additional options passed to `StrategyOptions`.

# Notes
 - `ADTypes.jl` is a hard dependency, so `AutoForwardDiff()` is always available in core.
 - Gradient computation requires the `CTBaseDifferentiationInterface` extension.
 - Without the extension, the gradient methods throw `NotImplemented` with a helpful message.

See also: [`CTBase.Differentiation.AbstractADBackend`](@ref),
[`CTBase.Differentiation.hamiltonian_gradient`](@ref),
[`CTBase.Differentiation.variable_gradient`](@ref).
"""
struct DifferentiationInterface{O<:Strategies.StrategyOptions} <:
       AbstractADBackend
    options::O
end

"""
$(TYPEDSIGNATURES)

Constructor for `DifferentiationInterface` with a specific backend.

# Arguments
- `mode::Symbol=:strict`: Validation mode forwarded to `build_strategy_options`.
- `kwargs...`: Options passed to `StrategyOptions`. The AD backend is set through the
  `:ad_backend` option (aliases `backend` and `ad`), e.g. `backend=AutoForwardDiff()`;
  it defaults to `AutoForwardDiff()`.

# Returns
- `DifferentiationInterface`: A new backend strategy instance.
"""
function DifferentiationInterface(; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(DifferentiationInterface; mode=mode, kwargs...)
    return DifferentiationInterface{typeof(opts)}(opts)
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

Return a human-readable description of the `DifferentiationInterface` strategy.
"""
Strategies.description(::Type{<:DifferentiationInterface}) =
    "AD backend wrapping DifferentiationInterface.jl backends (e.g., AutoForwardDiff)."

"""
$(TYPEDSIGNATURES)

Return metadata defining `DifferentiationInterface` options and their specifications.
"""
function Strategies.metadata(::Type{<:DifferentiationInterface})
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name = :ad_backend,
            type = ADTypes.AbstractADType,
            default = __ad_backend(),
            description = "DifferentiationInterface.jl backend (e.g. AutoForwardDiff()).",
            aliases=(:backend, :ad),
        ),
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
ad_backend(backend::DifferentiationInterface) =
    Base.get(Strategies.options(backend), Val(:ad_backend))
