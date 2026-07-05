# ==============================================================================
# Differentiation — AD Backend Strategies for Hamiltonian Gradients
# ==============================================================================

"""
Module `CTBase.Differentiation` provides automatic differentiation backend strategies
for computing gradients of scalar Hamiltonian functions.

## Architecture

The module defines an abstract contract `AbstractADBackend` with the following methods:
- `ad_backend(backend)` → the wrapped ADTypes backend (resolved in core)
- `hamiltonian_gradient(backend, h, t, x, p, v)` → (∂H/∂x, ∂H/∂p)
- `variable_gradient(backend, h, t, x, p, v)` → ∂H/∂v
- `gradient(backend, f, x)` → ∇f (extension contract)
- `derivative(backend, g, t)` → dg/dt (extension contract)
- `differentiate(backend, f, ::Val{Slot}, active, consts...)` → partial derivative at slot
- `pushforward(backend, f, ::Val{Slot}, x, dx, consts...)` → JVP along direction dx

The concrete strategy `DifferentiationInterface` wraps DifferentiationInterface.jl backends
(e.g., `AutoForwardDiff()`) and stores them in its `:ad_backend` option.

## Dependencies

- `ADTypes.jl` (hard dependency) — provides `AutoForwardDiff` type
- `CTBase.Data` — `AbstractHamiltonian` in the gradient contract signatures
- `CTBase.Strategies` — strategy contract
- `CTBase.Exceptions` — `NotImplemented` for stub methods

## Extension

Gradient computation requires the `CTBaseDifferentiationInterface` extension,
which implements the contract methods using `DifferentiationInterface.gradient`
and friends. It is loaded automatically when `DifferentiationInterface` is loaded
together with `CTBase`.

## Exports

- `AbstractADBackend`
- `DifferentiationInterface`
- `build_ad_backend`
- `ad_backend`
- `hamiltonian_gradient`
- `variable_gradient`
- `gradient`
- `derivative`
- `differentiate`
- `pushforward`
"""
module Differentiation

# ==============================================================================
# External Imports
# ==============================================================================

using ADTypes: ADTypes
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import CTBase.Data
import CTBase.Exceptions
import CTBase.Strategies

# ==============================================================================
# Includes (in dependency order)
# ==============================================================================

include(joinpath(@__DIR__, "default.jl"))
include(joinpath(@__DIR__, "abstract_ad_backend.jl"))
include(joinpath(@__DIR__, "differentiation_interface.jl"))
include(joinpath(@__DIR__, "building.jl"))

# ==============================================================================
# Exports
# ==============================================================================

export AbstractADBackend
export DifferentiationInterface
export build_ad_backend
export ad_backend
export hamiltonian_gradient
export pseudo_hamiltonian_gradient
export pseudo_hamiltonian_control_gradient
export variable_gradient
export pseudo_variable_gradient
export gradient
export derivative
export differentiate
export pushforward

end # module
