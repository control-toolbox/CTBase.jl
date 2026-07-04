# Differentiation: AD backend strategies

```@meta
CurrentModule = CTBase
```

The [`CTBase.Differentiation`](@ref CTBase.Differentiation) submodule provides an
**automatic differentiation (AD) backend** abstraction built on the
[Strategies](implementing-a-strategy.md) contract. It exposes a small set of
differentiation primitives — gradients, derivatives, partial derivatives and
Jacobian–vector products — behind a single strategy type, so that consumers
(Hamiltonian systems, flows, differential geometry) never depend on a concrete
AD package directly.

!!! tip "Prerequisites"
    Read the [Implementing a Strategy](@ref) and [Options System](@ref) guides
    first: an AD backend is a strategy with a single `:ad_backend` option.

```@setup diff
using CTBase
using CTBase.Differentiation
using CTBase.Data
using CTBase.Strategies
# Loading DifferentiationInterface (+ an AD package) activates the extension
# that provides the actual differentiation methods.
using DifferentiationInterface
using ForwardDiff
import ADTypes
```

## Overview

The module is organised around a two-level strategy contract:

| Level | Symbol | Role |
|---|---|---|
| Family | [`Differentiation.AbstractADBackend`](@ref CTBase.Differentiation.AbstractADBackend) | abstract strategy; defines the AD contract |
| Concrete | [`Differentiation.DifferentiationInterface`](@ref CTBase.Differentiation.DifferentiationInterface) | wraps a [DifferentiationInterface.jl](https://github.com/JuliaDiff/DifferentiationInterface.jl) backend |

The concrete strategy stores a single option, `:ad_backend`, holding an
[ADTypes.jl](https://github.com/SciML/ADTypes.jl) backend (default
`AutoForwardDiff()`). `ADTypes` is a hard dependency of CTBase, so the default is
always available.

The contract has nine methods.
[`Differentiation.ad_backend`](@ref CTBase.Differentiation.ad_backend) — the accessor
returning the wrapped ADTypes backend — is resolved in core and always available; the
eight differentiation primitives below live in an extension.

!!! note "The differentiation methods live in an extension"
    The contract methods (`gradient`, `derivative`, `differentiate`,
    `pushforward`, `hamiltonian_gradient`, `variable_gradient`,
    `pseudo_hamiltonian_gradient`, `pseudo_hamiltonian_control_gradient`) are implemented in
    the `CTBaseDifferentiationInterface` **package extension**. They become
    available only once `DifferentiationInterface` *and* a concrete AD package
    (e.g. `ForwardDiff`) are loaded. Without the extension, every contract method
    throws a [`CTBase.Exceptions.NotImplemented`](@ref) with a helpful message.

## Building a backend

Use [`Differentiation.build_ad_backend`](@ref CTBase.Differentiation.build_ad_backend)
to construct a backend with the default AD type:

```@example diff
backend = Differentiation.build_ad_backend()
```

Pass an explicit ADTypes backend through the `ad_backend` option (the aliases
`backend` and `ad` resolve to the same option):

```@example diff
Differentiation.build_ad_backend(; ad_backend = ADTypes.AutoForwardDiff())
```

The wrapped AD type is recovered with
[`Differentiation.ad_backend`](@ref CTBase.Differentiation.ad_backend):

```@example diff
Differentiation.ad_backend(backend)
```

Because it is a regular strategy, its metadata is introspectable at the type level:

```@example diff
Strategies.metadata(Differentiation.DifferentiationInterface)
```

## Differentiation primitives

### Gradient and derivative

[`Differentiation.gradient`](@ref CTBase.Differentiation.gradient) differentiates a
scalar function of a vector, and
[`Differentiation.derivative`](@ref CTBase.Differentiation.derivative) a scalar
function of a scalar:

```@example diff
f(x) = sum(x .^ 2)          # ∇f = 2x
Differentiation.gradient(backend, f, [1.0, 2.0])
```

```@example diff
g(t) = t^3                  # g'(t) = 3t²
Differentiation.derivative(backend, g, 2.0)
```

### Partial derivative at a slot

[`Differentiation.differentiate`](@ref CTBase.Differentiation.differentiate)
computes the partial derivative of `f` with respect to the argument at a
**compile-time slot** `Val(Slot)`, holding the other arguments fixed. The active
argument comes first, the frozen ones follow in slot order:

```@example diff
# H(x, p) = ½‖p‖² + ‖x‖²  →  ∂H/∂x = 2x,  ∂H/∂p = p
H(x, p) = 0.5 * sum(p .^ 2) + sum(x .^ 2)
x = [1.0, 2.0]; p = [3.0, 4.0]

∂x = Differentiation.differentiate(backend, H, Val(1), x, p)   # active = x (slot 1), const = p
∂p = Differentiation.differentiate(backend, H, Val(2), p, x)   # active = p (slot 2), const = x
(∂x, ∂p)
```

A scalar slot yields a scalar derivative:

```@example diff
# f(t, x) = t * x[1]  →  ∂f/∂t = x[1]
ft(t, x) = t * x[1]
Differentiation.differentiate(backend, ft, Val(1), 2.0, [3.0, 4.0])
```

### Pushforward (Jacobian–vector product)

[`Differentiation.pushforward`](@ref CTBase.Differentiation.pushforward) computes the
directional derivative of `f` at `x` along `dx`, freezing the other arguments:

```@example diff
A = [0.0 1.0; -1.0 0.0]
X(x) = A * x                 # J_X = A  →  pushforward = A·dx
Differentiation.pushforward(backend, X, Val(1), [1.0, 2.0], [5.0, 6.0])
```

## Hamiltonian gradients

The two domain-specific methods operate directly on a
[`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian) (see the [Data](data.md) guide).
[`Differentiation.hamiltonian_gradient`](@ref CTBase.Differentiation.hamiltonian_gradient)
returns `(∂H/∂x, ∂H/∂p)`, **non-negated** — the caller applies the signs of
Hamilton's equations (`ẋ = ∂H/∂p`, `ṗ = -∂H/∂x`):

```@example diff
# H(x, p) = ½(‖x‖² + ‖p‖²)  →  ∂H/∂x = x,  ∂H/∂p = p
h = Data.Hamiltonian((x, p) -> 0.5 * (sum(abs2, x) + sum(abs2, p)))
∂x, ∂p = Differentiation.hamiltonian_gradient(backend, h, 0.0, [1.0, 2.0], [3.0, 4.0], nothing)
(∂x, ∂p)
```

For a non-fixed Hamiltonian,
[`Differentiation.variable_gradient`](@ref CTBase.Differentiation.variable_gradient)
returns `∂H/∂v`:

```@example diff
# H(x, p, v) = ½(‖x‖² + ‖p‖² + ‖v‖²)  →  ∂H/∂v = v
hv = Data.Hamiltonian((x, p, v) -> 0.5 * (sum(abs2, x) + sum(abs2, p) + sum(abs2, v)); is_variable=true)
Differentiation.variable_gradient(backend, hv, 0.0, [1.0, 2.0], [3.0, 4.0], [5.0, 6.0])
```

## Pseudo-Hamiltonian gradients

The two pseudo-Hamiltonian methods operate directly on a
[`Data.PseudoHamiltonian`](@ref CTBase.Data.PseudoHamiltonian) (see the [Data](data.md)
guide).
[`Differentiation.pseudo_hamiltonian_gradient`](@ref CTBase.Differentiation.pseudo_hamiltonian_gradient)
returns `(∂H̃/∂x, ∂H̃/∂p)`, **non-negated** — the caller applies the signs of
Hamilton's equations:

```@example diff
# H̃(x, p, u) = ½(‖x‖² + ‖p‖²) + u²  →  ∂H̃/∂x = x, ∂H̃/∂p = p
ph = Data.PseudoHamiltonian((x, p, u) -> 0.5 * (sum(abs2, x) + sum(abs2, p)) + u^2)
∂x, ∂p = Differentiation.pseudo_hamiltonian_gradient(backend, ph, 0.0, [1.0, 2.0], [3.0, 4.0], 2.0, nothing)
(∂x, ∂p)
```

[`Differentiation.pseudo_hamiltonian_control_gradient`](@ref CTBase.Differentiation.pseudo_hamiltonian_control_gradient)
returns `∂H̃/∂u`, which vanishes along optimal trajectories by the Pontryagin
Maximum Principle stationarity condition:

```@example diff
# ∂H̃/∂u = 2u = 4.0
Differentiation.pseudo_hamiltonian_control_gradient(backend, ph, 0.0, [1.0, 2.0], [3.0, 4.0], 2.0, nothing)
```

For a non-fixed pseudo-Hamiltonian, the `v` argument carries the variable:

```@example diff
phv = Data.PseudoHamiltonian((x, p, u, v) -> 0.5 * (sum(abs2, x) + sum(abs2, p)) + u^2 + v[1]; is_variable=true)
Differentiation.pseudo_hamiltonian_control_gradient(backend, phv, 0.0, [1.0, 2.0], [3.0, 4.0], 2.0, [5.0])
```

## The contract without the extension

Every contract method has a fallback on `AbstractADBackend` that throws
[`CTBase.Exceptions.NotImplemented`](@ref) (see the [Exceptions](exceptions.md)
guide). This is what users hit when the AD package is not loaded, and what custom
backends must override:

```@repl diff
struct MyBackend <: Differentiation.AbstractADBackend
    options::Strategies.StrategyOptions
end
try # hide
Differentiation.gradient(MyBackend(Strategies.StrategyOptions()), x -> sum(x), [1.0])
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## See also

- [`Differentiation.AbstractADBackend`](@ref CTBase.Differentiation.AbstractADBackend), [`Differentiation.DifferentiationInterface`](@ref CTBase.Differentiation.DifferentiationInterface) — the strategy types.
- [Implementing a Strategy](@ref), [Options System](@ref) — the contract these build on.
- [Data](data.md) — `Hamiltonian` and `PseudoHamiltonian` wrappers consumed by the gradient methods.
- [Exceptions](exceptions.md) — `NotImplemented`, raised by the contract fallbacks.
