# Data: typed function wrappers

```@meta
CurrentModule = CTBase
```

The [`CTBase.Data`](@ref CTBase.Data) submodule provides typed wrappers that carry
a Julia function together with its **trait metadata** (see the [Traits](traits.md)
guide). Each wrapper knows, at the type level, whether it depends on time, whether
it depends on an extra variable, and whether it is evaluated in-place.

```@setup data
using CTBase
using CTBase.Data
using CTBase.Traits
using LinearAlgebra
```

## Overview

| Type | Mathematical object | Natural signature (autonomous/fixed) |
|---|---|---|
| [`Data.VectorField`](@ref CTBase.Data.VectorField) | ``X : \mathcal{X} \to \mathbb{R}^n`` | `X(x)` |
| [`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian) | ``H : T^*\mathcal{X} \to \mathbb{R}`` | `H(x, p)` |
| [`Data.PseudoHamiltonian`](@ref CTBase.Data.PseudoHamiltonian) | ``\tilde{H} : T^*\mathcal{X} \times \mathcal{U} \to \mathbb{R}`` | `H̃(x, p, u)` |
| [`Data.HamiltonianVectorField`](@ref CTBase.Data.HamiltonianVectorField) | ``\vec{H} : T^*\mathcal{X} \to \mathbb{R}^{2n}`` | `HVF(x, p)` |
| [`Data.ControlLaw`](@ref CTBase.Data.ControlLaw) | ``u : \cdots \to \mathcal{U}`` | `u()` / `u(x)` / `u(x, p)` |

All five share the same trait axes — time dependence and variable dependence.
`VectorField` and `HamiltonianVectorField` also carry a mutability trait;
`ControlLaw` carries a feedback trait (see [Traits](traits.md)).

---

## VectorField

A `VectorField` wraps a Julia function representing ``\dot{x} = X(\cdots)``.

### Construction

```@example data
using CTBase.Data, CTBase.Traits

# Autonomous, fixed (default): X(x)
vf1 = Data.VectorField(x -> -x)

# Non-autonomous, fixed: X(t, x)
vf2 = Data.VectorField((t, x) -> t .* x; is_autonomous=false)

# Autonomous, non-fixed: X(x, v)
vf3 = Data.VectorField((x, v) -> x .* v; is_variable=true)

# Non-autonomous, non-fixed: X(t, x, v)
vf4 = Data.VectorField((t, x, v) -> t .* x .+ v; is_autonomous=false, is_variable=true)

vf1
```

The `show` output summarises the traits and both call signatures (natural and
uniform).

### In-place construction

Prefer out-of-place for clarity. Use in-place when avoiding allocations matters:

```@example data
# In-place Autonomous/Fixed: f(dx, x) — mutability auto-detected
vf_ip = Data.VectorField((dx, x) -> (dx .= -x; nothing))
Traits.mutability(vf_ip)
```

If the function has multiple methods, auto-detection fails; pass `is_inplace`
explicitly:

```@example data
f_multi(x) = -x
f_multi(dx, x) = (dx .= -x; nothing)

vf_explicit = Data.VectorField(f_multi; is_inplace=true)
```

### Calling

```@example data
x0 = [1.0, 0.5]

vf1(x0)                    # natural call
vf1(0.0, x0, nothing)      # uniform call (ignores t and v)
vf2(0.5, x0)               # non-autonomous natural call
```

---

## Hamiltonian

A `Hamiltonian` wraps a scalar function ``H(x, p) \in \mathbb{R}``.

```math
H : T^*\mathcal{X} \to \mathbb{R}, \quad (x, p) \mapsto H(x, p).
```

### Construction

```@example data
# Autonomous, fixed (default): H(x, p)
h1 = Data.Hamiltonian((x, p) -> dot(p, x))

# Non-autonomous, fixed: H(t, x, p)
h2 = Data.Hamiltonian((t, x, p) -> t * dot(p, x); is_autonomous=false)

# Autonomous, non-fixed: H(x, p, v)
h3 = Data.Hamiltonian((x, p, v) -> dot(p, x) * v[1]; is_variable=true)

h1
```

### Calling

```@example data
x0, p0 = [1.0, 0.5], [0.3, 0.7]

h1(x0, p0)                # natural call
h1(0.0, x0, p0, nothing)  # uniform call
h2(0.5, x0, p0)           # non-autonomous
```

---

## HamiltonianVectorField

A `HamiltonianVectorField` wraps the map
``(x, p) \mapsto (\dot{x}, \dot{p}) = (\partial_p H, -\partial_x H)``
when the derivatives are provided **explicitly** (no automatic differentiation).

```math
\vec{H}(x, p) = \bigl(\partial_p H(x,p),\; -\partial_x H(x,p)\bigr).
```

Use this when the Hamiltonian equations are known analytically. When only the
scalar Hamiltonian is available and the derivatives must be obtained by automatic
differentiation, use [`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian) instead.

### Construction

```@example data
# Harmonic oscillator H = (x²+p²)/2:  ẋ = p, ṗ = -x
hvf = Data.HamiltonianVectorField((x, p) -> (p, -x))

# With time dependence
hvf_na = Data.HamiltonianVectorField((t, x, p) -> (p, -x .* t); is_autonomous=false)

hvf
```

### Calling

```@example data
dx, dp = hvf(x0, p0)   # natural call: returns (ẋ, ṗ)
(dx, dp)
```

### The `variable_costate` keyword

For **non-fixed** Hamiltonian vector fields, the call accepts an optional
`variable_costate` keyword (default `false`).

When `false` (default), the out-of-place call returns `(dx, dp)`; when `true`,
it returns the extended tuple `(dx, dp, dpv)` where `dpv = ∂ṗ/∂v` is the
derivative of the costate equations with respect to the variable `v`. For
in-place fields, `dpv` is passed as an optional pre-allocated buffer
(`dpv=nothing` skips the computation):

```@example data
# Inner function that implements the variable_costate path.
# H(x, p, v) = v[1] * dot(p, x)  →  ẋ = v[1]*x,  ṗ = -v[1]*p,  ∂ṗ/∂v[1] = -p
function f_vc(x, p, v; variable_costate=false)
    dx = v[1] .* x
    dp = -v[1] .* p
    variable_costate ? (dx, dp, -p) : (dx, dp)
end

hvf_nf = Data.HamiltonianVectorField(f_vc; is_variable=true)
v0 = [2.0]

dx, dp = hvf_nf(x0, p0, v0)                            # returns (ẋ, ṗ)
(dx, dp)
```

```@example data
dx, dp, dpv = hvf_nf(x0, p0, v0; variable_costate=true)  # returns (ẋ, ṗ, ∂ṗ/∂v)
(dx, dp, dpv)
```

For in-place non-fixed fields the signature is:

```julia
dpv = zeros(length(p0))
hvf_ip_nf(dx, dp, x, p, v; dpv=dpv, variable_costate=true)  # fills dx, dp, dpv in place
```

This is only supported by inner functions that implement the `variable_costate`
keyword path — typically those **derived from a
[`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian)** by automatic differentiation.
For a plain user-supplied function that does not accept `variable_costate`, passing
`true` raises a [`CTBase.Exceptions.PreconditionError`](@ref) (see the
[Exceptions](exceptions.md) guide).

---

## PseudoHamiltonian

A `PseudoHamiltonian` wraps a scalar function ``\tilde{H}(x, p, u) \in \mathbb{R}``
that extends the standard Hamiltonian with an explicit control argument ``u``.

```math
\tilde{H} : T^*\mathcal{X} \times \mathcal{U} \to \mathbb{R}, \quad (x, p, u) \mapsto \tilde{H}(x, p, u).
```

Unlike [`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian), which encodes the
control implicitly, a pseudo-Hamiltonian takes the control as an additional
argument. This enables dynamic closed-loop flows where the control is computed
from the pseudo-Hamiltonian's maximisation condition (PMP stationarity:
``\partial \tilde{H} / \partial u = 0``).

### Construction

```@example data
# Autonomous, fixed (default): H̃(x, p, u)
ph1 = Data.PseudoHamiltonian((x, p, u) -> dot(p, x) + u^2)

# Non-autonomous, fixed: H̃(t, x, p, u)
ph2 = Data.PseudoHamiltonian((t, x, p, u) -> t * dot(p, x) + u^2; is_autonomous=false)

# Autonomous, non-fixed: H̃(x, p, u, v)
ph3 = Data.PseudoHamiltonian((x, p, u, v) -> dot(p, x) + u^2 + v[1]; is_variable=true)

ph1
```

### Calling

```@example data
x0, p0, u0 = [1.0, 0.5], [0.3, 0.7], 2.0

ph1(x0, p0, u0)                    # natural call
ph1(0.0, x0, p0, u0, nothing)      # uniform call
ph2(0.5, x0, p0, u0)               # non-autonomous
```

The dynamics trait of a `PseudoHamiltonian` is always
[`Traits.HamiltonianDynamics`](@ref CTBase.Traits.HamiltonianDynamics), since
pseudo-Hamiltonians involve both state and costate.

---

## ControlLaw

A `ControlLaw` wraps a function ``u(\cdots)`` that provides the control input for
an optimal control problem. The feedback trait (see [Traits](traits.md))
determines which arguments the control law depends on.

Three user-facing constructors fix the feedback trait:

| Constructor | Feedback trait | Natural signature (autonomous/fixed) |
|---|---|---|
| [`Data.OpenLoop`](@ref CTBase.Data.OpenLoop) | `OpenLoopFeedback` | `u()` |
| [`Data.ClosedLoop`](@ref CTBase.Data.ClosedLoop) | `ClosedLoopFeedback` | `u(x)` |
| [`Data.DynClosedLoop`](@ref CTBase.Data.DynClosedLoop) | `DynClosedLoopFeedback` | `u(x, p)` |

### Construction

```@example data
# Open-loop, autonomous, fixed (default): u()
u_ol = Data.OpenLoop(() -> 1.0)

# Closed-loop, autonomous, fixed: u(x)
u_cl = Data.ClosedLoop(x -> -x)

# Dynamic closed-loop, autonomous, fixed: u(x, p)
u_dcl = Data.DynClosedLoop((x, p) -> -x - p)

u_ol
```

Non-autonomous and variable variants are constructed with the same keywords as
other data types:

```@example data
u_ol_na = Data.OpenLoop((t, v) -> t * v; is_autonomous=false, is_variable=true)
```

### Calling

Every `ControlLaw` is callable via its **natural** signature (matching the
traits) and via a **uniform** signature that depends on the feedback trait:

| Feedback | Natural `(Aut, Fixed)` | Uniform |
|---|---|---|
| `OpenLoop` | `u()` | `u(t, v)` |
| `ClosedLoop` | `u(x)` | `u(t, x, v)` |
| `DynClosedLoop` | `u(x, p)` | `u(t, x, p, v)` |

```@example data
u_ol()                         # natural call
u_ol(0.0, nothing)             # uniform call

u_cl(x0)                       # natural call
u_cl(0.0, x0, nothing)         # uniform call

u_dcl(x0, p0)                  # natural call
u_dcl(0.0, x0, p0, nothing)    # uniform call
```

The feedback trait determines the dynamics trait: open-loop and closed-loop
control laws carry [`Traits.StateDynamics`](@ref CTBase.Traits.StateDynamics),
while dynamic closed-loop control laws carry
[`Traits.HamiltonianDynamics`](@ref CTBase.Traits.HamiltonianDynamics).

---

## Querying traits

Because the trait metadata lives in the type, it can be recovered from any data
object through the [Traits](traits.md) accessors — with no runtime cost:

```@example data
Traits.time_dependence(vf2)      # NonAutonomous
```

```@example data
Traits.variable_dependence(vf3)  # NonFixed
```

```@example data
Traits.mutability(vf_ip)         # InPlace
```

The boolean predicates follow generically:

```@example data
Traits.is_autonomous(vf1), Traits.is_variable(vf1), Traits.is_inplace(vf1)
```

Each data family also reports its dynamics trait via
[`Traits.dynamics_trait`](@ref CTBase.Traits.dynamics_trait):

```@example data
Traits.dynamics_trait(vf1), Traits.dynamics_trait(h1), Traits.dynamics_trait(hvf)
```

A `VectorField` carries [`Traits.StateDynamics`](@ref CTBase.Traits.StateDynamics),
while both `Hamiltonian` and `HamiltonianVectorField` carry
[`Traits.HamiltonianDynamics`](@ref CTBase.Traits.HamiltonianDynamics).

---

## Typed constructors

A lower-level constructor takes the trait types directly (no keyword inference).
It is used internally by code that produces typed data objects programmatically:

```@example data
vf_typed = Data.VectorField(x -> 2x, Traits.Autonomous, Traits.Fixed, Traits.OutOfPlace)
Traits.time_dependence(vf_typed)
```

The same positional form exists for [`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian)
(`Hamiltonian(f, TD, VD)`),
[`Data.PseudoHamiltonian`](@ref CTBase.Data.PseudoHamiltonian)
(`PseudoHamiltonian(f, TD, VD)`),
[`Data.HamiltonianVectorField`](@ref CTBase.Data.HamiltonianVectorField)
(`HamiltonianVectorField(f, TD, VD, MD)`), and
[`Data.ControlLaw`](@ref CTBase.Data.ControlLaw)
(`ControlLaw(f, FB, TD, VD)`).

---

## See also

- [`Data.VectorField`](@ref CTBase.Data.VectorField), [`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian), [`Data.PseudoHamiltonian`](@ref CTBase.Data.PseudoHamiltonian), [`Data.HamiltonianVectorField`](@ref CTBase.Data.HamiltonianVectorField), [`Data.ControlLaw`](@ref CTBase.Data.ControlLaw) — concrete data types.
- [`Data.AbstractVectorField`](@ref CTBase.Data.AbstractVectorField), [`Data.AbstractHamiltonian`](@ref CTBase.Data.AbstractHamiltonian), [`Data.AbstractPseudoHamiltonian`](@ref CTBase.Data.AbstractPseudoHamiltonian), [`Data.AbstractHamiltonianVectorField`](@ref CTBase.Data.AbstractHamiltonianVectorField), [`Data.AbstractControlLaw`](@ref CTBase.Data.AbstractControlLaw) — abstract supertypes.
- [Traits](traits.md) — the three trait axes, the dynamics trait, and call-signature tables.
- [Exceptions](exceptions.md) — `PreconditionError` and `IncorrectArgument`, raised by the constructors and the `variable_costate` path.
