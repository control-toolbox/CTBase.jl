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

| Type | Mathematical object | Out-of-place call | In-place |
|---|---|---|---|
| [`Data.VectorField`](@ref CTBase.Data.VectorField) | ``X : \mathcal{X} \to \mathbb{R}^n`` | `X([t, ]x[, v])` | ✓ |
| [`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian) | ``H : T^*\mathcal{X} \to \mathbb{R}`` | `H([t, ]x, p[, v])` | — |
| [`Data.PseudoHamiltonian`](@ref CTBase.Data.PseudoHamiltonian) | ``\tilde{H} : T^*\mathcal{X} \times \mathcal{U} \to \mathbb{R}`` | `H̃([t, ]x, p, u[, v])` | — |
| [`Data.ComposedHamiltonian`](@ref CTBase.Data.ComposedHamiltonian) | ``H : T^*\mathcal{X} \to \mathbb{R}`` | `H([t, ]x, p[, v])` | — |
| [`Data.HamiltonianVectorField`](@ref CTBase.Data.HamiltonianVectorField) | ``\vec{H} : T^*\mathcal{X} \to \mathbb{R}^{2n}`` | `HVF([t, ]x, p[, v])` | ✓ |
| [`Data.ControlledVectorField`](@ref CTBase.Data.ControlledVectorField) | ``f_c : \mathcal{X} \times \mathcal{U} \to \mathbb{R}^n`` | `fc([t, ]x, u[, v])` | — |
| [`Data.ComposedVectorField`](@ref CTBase.Data.ComposedVectorField) | ``g : \mathcal{X} \to \mathbb{R}^n`` | `g([t, ]x[, v])` | — |
| [`Data.ControlLaw`](@ref CTBase.Data.ControlLaw) | ``u : \cdots \to \mathcal{U}`` | `u([t, ]⋯[, v])`† | — |
| [`Data.PathConstraint`](@ref CTBase.Data.PathConstraint) | ``g : \cdots \to \mathbb{R}^{n_g}`` | `g([t, ]⋯[, v])`† | — |
| [`Data.Multiplier`](@ref CTBase.Data.Multiplier) | ``\mu : T^*\mathcal{X} \to \mathbb{R}^{n_g}`` | `μ([t, ]x, p[, v])` | — |

The mathematical spaces are:

- ``\mathcal{X} \subseteq \mathbb{R}^n`` — the **state space** (``n`` state dimensions).
- ``\mathcal{U} \subseteq \mathbb{R}^m`` — the **control space** (``m`` control dimensions).
- ``T^*\mathcal{X} = \mathcal{X} \times \mathbb{R}^n`` — the **cotangent bundle** (state + costate, ``2n`` dimensions).
- ``\mathbb{R}^{n_v}`` — the **optimisation variable** space (``n_v`` variable dimensions; absent when fixed).
- ``\mathbb{R}`` — scalars; ``\mathbb{R}^{n_g}`` — constraint values (``n_g`` constraint dimensions).
- ``\cdots`` — the domain depends on an additional trait (feedback or constraint-kind).

In the call patterns, brackets `[…]` denote optional arguments controlled by traits:

- `t` is present when `is_autonomous=false` (non-autonomous).
- `v` is present when `is_variable=true` (non-fixed).
- † `⋯` depends on an additional trait: **feedback** for `ControlLaw` (see below),
  **constraint-kind** for `PathConstraint` (see below).

All ten share the same time-dependence and variable-dependence trait axes.
`VectorField` and `HamiltonianVectorField` also carry a mutability trait (in-place / out-of-place);
`ControlLaw` carries a feedback trait;
`PathConstraint` carries a constraint-kind trait (see [Traits](traits.md)).

---

## VectorField

A `VectorField` wraps a Julia function representing the dynamics ``\dot{x} = X(t, x, v)``.

The **natural** out-of-place call is `X([t, ]x[, v])`, where `t` and `v` are
optional arguments controlled by the time-dependence and variable-dependence traits.
A **uniform** call `X(t, x, v)` always works regardless of traits (unused arguments
are ignored). In-place is supported: the derivative buffer `dx` is prepended,
giving `X!(dx, [t, ]x[, v])`.

**Construction**

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

**In-place construction**

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

**Calling**

```@example data
x0 = [1.0, 0.5]

vf1(x0)                    # natural call
vf1(0.0, x0, nothing)      # uniform call (ignores t and v)
vf2(0.5, x0)               # non-autonomous natural call
```

---

## Hamiltonian

A `Hamiltonian` wraps a scalar function ``H(t, x, p, v) \in \mathbb{R}``.

```math
H : \mathbb{R} \times T^*\mathcal{X} \times \mathbb{R}^{n_v} \to \mathbb{R}, \quad (t, x, p, v) \mapsto H(t, x, p, v).
```

The **natural** call is `H([t, ]x, p[, v])`, where `t` and `v` are optional
arguments controlled by the time-dependence and variable-dependence traits.
A **uniform** call `H(t, x, p, v)` always works regardless of traits.
In-place is not supported (scalar return value).

**Construction**

```@example data
# Autonomous, fixed (default): H(x, p)
h1 = Data.Hamiltonian((x, p) -> dot(p, x))

# Non-autonomous, fixed: H(t, x, p)
h2 = Data.Hamiltonian((t, x, p) -> t * dot(p, x); is_autonomous=false)

# Autonomous, non-fixed: H(x, p, v)
h3 = Data.Hamiltonian((x, p, v) -> dot(p, x) * v[1]; is_variable=true)

h1
```

**Calling**

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
\vec{H}(t, x, p, v) = \bigl(\partial_p H,\; -\partial_x H\bigr).
```

The **natural** out-of-place call is `HVF([t, ]x, p[, v])`, where `t` and `v` are
optional arguments controlled by the time-dependence and variable-dependence traits.
A **uniform** call `HVF(t, x, p, v)` always works regardless of traits.
In-place is supported: the derivative buffers `dx, dp` are prepended,
giving `HVF!(dx, dp, [t, ]x, p[, v])`.

Use this when the Hamiltonian equations are known analytically. When only the
scalar Hamiltonian is available and the derivatives must be obtained by automatic
differentiation, use [`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian) instead.

**Construction**

```@example data
# Harmonic oscillator H = (x²+p²)/2:  ẋ = p, ṗ = -x
hvf = Data.HamiltonianVectorField((x, p) -> (p, -x))

# With time dependence
hvf_na = Data.HamiltonianVectorField((t, x, p) -> (p, -x .* t); is_autonomous=false)

hvf
```

**Calling**

```@example data
dx, dp = hvf(x0, p0)   # natural call: returns (ẋ, ṗ)
(dx, dp)
```

**The `variable_costate` keyword**

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

A `PseudoHamiltonian` wraps a scalar function ``\tilde{H}(t, x, p, u, v) \in \mathbb{R}``
that extends the standard Hamiltonian with an explicit control argument ``u``.

```math
\tilde{H} : \mathbb{R} \times T^*\mathcal{X} \times \mathcal{U} \times \mathbb{R}^{n_v} \to \mathbb{R}, \quad (t, x, p, u, v) \mapsto \tilde{H}(t, x, p, u, v).
```

The **natural** call is `H̃([t, ]x, p, u[, v])`, where `t` and `v` are optional
arguments controlled by the time-dependence and variable-dependence traits.
A **uniform** call `H̃(t, x, p, u, v)` always works regardless of traits.
In-place is not supported (scalar return value).

Unlike [`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian), which encodes the
control implicitly, a pseudo-Hamiltonian takes the control as an additional
argument. This enables dynamic closed-loop flows where the control is computed
from the pseudo-Hamiltonian's maximisation condition (PMP stationarity:
``\partial \tilde{H} / \partial u = 0``).

**Construction**

```@example data
# Autonomous, fixed (default): H̃(x, p, u)
ph1 = Data.PseudoHamiltonian((x, p, u) -> dot(p, x) + u^2)

# Non-autonomous, fixed: H̃(t, x, p, u)
ph2 = Data.PseudoHamiltonian((t, x, p, u) -> t * dot(p, x) + u^2; is_autonomous=false)

# Autonomous, non-fixed: H̃(x, p, u, v)
ph3 = Data.PseudoHamiltonian((x, p, u, v) -> dot(p, x) + u^2 + v[1]; is_variable=true)

ph1
```

**Calling**

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

## ComposedHamiltonian

A `ComposedHamiltonian` is obtained by eliminating the control from a
[`Data.PseudoHamiltonian`](@ref CTBase.Data.PseudoHamiltonian) with a
dynamic closed-loop [`Data.ControlLaw`](@ref CTBase.Data.ControlLaw):

```math
H(t, x, p, v) = \tilde{H}(t, x, p, u(t, x, p, v), v).
```

The **natural** call is `H([t, ]x, p[, v])`, where the time/variable dependences
are the **join** of the pseudo-Hamiltonian and the control law —
`NonAutonomous`/`NonFixed` win.
A **uniform** call `H(t, x, p, v)` always works regardless of traits.
In-place is not supported (scalar return value).

It subtypes [`Data.AbstractHamiltonian`](@ref CTBase.Data.AbstractHamiltonian), so it
*is* a Hamiltonian and can be used anywhere one is expected.

**Construction**

```@example data
# Pseudo-Hamiltonian H̃(x, p, u) = p⋅x + u²  (scalar state/costate/control)
ph = Data.PseudoHamiltonian((x, p, u) -> p * x + u^2)

# Dynamic closed-loop law u(x, p) = -p
law = Data.DynClosedLoop((x, p) -> -p)

# Composed Hamiltonian: H(x, p) = H̃(x, p, -p) = p⋅x + p²
H = Data.ComposedHamiltonian(ph, law)

H
```

The composed time/variable dependences are the **join** of the two inputs —
`NonAutonomous`/`NonFixed` win. A time-varying feedback on an autonomous
pseudo-Hamiltonian correctly yields a `NonAutonomous` composed Hamiltonian.

**Calling**

```@example data
x0, p0 = 1.0, 0.5

H(x0, p0)                    # natural call
H(0.0, x0, p0, nothing)      # uniform call
```

**Getters**

```@example data
Data.pseudo_hamiltonian(H)   # the underlying PseudoHamiltonian
Data.control_law(H)          # the DynClosedLoop law
```

The constructor rejects non-`DynClosedLoop` laws (`OpenLoop`, `ClosedLoop`) with a
`MethodError` — those are the state-space path (`ComposedVectorField`).

---

## ControlLaw

A `ControlLaw` wraps a function ``u(\cdots)`` that provides the control input for
an optimal control problem. The **feedback** trait (see [Traits](traits.md))
determines which primal variables the control law depends on, and the
time/variable traits add `t` and `v` as for other data types.

Three user-facing constructors fix the feedback trait:

| Constructor | Feedback trait | Out-of-place call |
|---|---|---|
| [`Data.OpenLoop`](@ref CTBase.Data.OpenLoop) | `OpenLoopFeedback` | `u([t][, v])` |
| [`Data.ClosedLoop`](@ref CTBase.Data.ClosedLoop) | `ClosedLoopFeedback` | `u([t, ]x[, v])` |
| [`Data.DynClosedLoop`](@ref CTBase.Data.DynClosedLoop) | `DynClosedLoopFeedback` | `u([t, ]x, p[, v])` |

**Construction**

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

**Calling**

Every `ControlLaw` is callable via its **natural** signature (matching the
traits) and via a **uniform** signature that depends on the feedback trait:

| Feedback | Natural | Uniform |
|---|---|---|
| `OpenLoop` | `u([t][, v])` | `u(t, v)` |
| `ClosedLoop` | `u([t, ]x[, v])` | `u(t, x, v)` |
| `DynClosedLoop` | `u([t, ]x, p[, v])` | `u(t, x, p, v)` |

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

## PathConstraint

A `PathConstraint` wraps a function ``g(\cdots)`` that evaluates a path constraint
along the trajectory. The **constraint-kind** trait (see [Traits](traits.md))
determines which primal variables the constraint depends on, and the
time/variable traits add `t` and `v` as for other data types.

Three user-facing constructors fix the constraint kind:

| Constructor | Constraint kind | Out-of-place call |
|---|---|---|
| [`Data.StateConstraint`](@ref CTBase.Data.StateConstraint) | `StateConstraintKind` | `g([t, ]x[, v])` |
| [`Data.ControlConstraint`](@ref CTBase.Data.ControlConstraint) | `ControlConstraintKind` | `g([t, ]u[, v])` |
| [`Data.MixedConstraint`](@ref CTBase.Data.MixedConstraint) | `MixedConstraintKind` | `g([t, ]x, u[, v])` |

**Construction**

```@example data
# State constraint, autonomous, fixed (default): g(x)
g_state = Data.StateConstraint(x -> x[1])

# Control constraint, autonomous, fixed: g(u)
g_ctrl = Data.ControlConstraint(u -> u[1])

# Mixed constraint, autonomous, fixed: g(x, u)
g_mixed = Data.MixedConstraint((x, u) -> x[1] + u[1])

# Non-autonomous state constraint: g(t, x)
g_state_na = Data.StateConstraint((t, x) -> t * x[1]; is_autonomous=false)

g_state
```

**Calling**

Every `PathConstraint` is callable via its **natural** signature (matching the
traits) and via a **uniform** signature `g(t, x, u, v)` that ignores unused
arguments:

```@example data
x0, u0 = [1.0, 0.5], [2.0]

g_state(x0)                    # natural call
g_state(0.0, x0, u0, nothing)  # uniform call

g_ctrl(u0)                     # natural call
g_mixed(x0, u0)                # natural call
```

The constraint kind can be queried with the predicate functions
[`Traits.is_state_constraint`](@ref CTBase.Traits.is_state_constraint),
[`Traits.is_control_constraint`](@ref CTBase.Traits.is_control_constraint),
and [`Traits.is_mixed_constraint`](@ref CTBase.Traits.is_mixed_constraint):

```@example data
Traits.is_state_constraint(g_state), Traits.is_control_constraint(g_ctrl), Traits.is_mixed_constraint(g_mixed)
```

---

## Multiplier

A `Multiplier` wraps a function ``\mu(t, x, p, v)`` returning the Lagrange
multiplier associated with a path constraint.

The **natural** call is `μ([t, ]x, p[, v])`, where `t` and `v` are optional
arguments controlled by the time-dependence and variable-dependence traits.
A **uniform** call `μ(t, x, p, v)` always works regardless of traits.
In-place is not supported.

It has the same call structure as a
[`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian) — it depends on the state and
costate — but carries no dynamics semantics of its own.

**Construction**

```@example data
# Autonomous, fixed (default): μ(x, p)
μ1 = Data.Multiplier((x, p) -> x[1])

# Non-autonomous, fixed: μ(t, x, p)
μ2 = Data.Multiplier((t, x, p) -> t * x[1]; is_autonomous=false)

μ1
```

**Calling**

```@example data
x0, p0 = [1.0, 0.5], [0.3, 0.7]

μ1(x0, p0)                    # natural call
μ1(0.0, x0, p0, nothing)      # uniform call
μ2(0.5, x0, p0)               # non-autonomous natural call
```

---

## ControlledVectorField

A `ControlledVectorField` wraps a function ``f_c(t, x, u, v)`` that returns the
state derivative with an **explicit control argument** ``u``. It is the state-space
analogue of [`Data.PseudoHamiltonian`](@ref CTBase.Data.PseudoHamiltonian): where a
pseudo-Hamiltonian carries the control alongside the costate, a controlled vector
field carries the control alongside the state.

The **natural** call is `fc([t, ]x, u[, v])`, where `t` and `v` are optional
arguments controlled by the time-dependence and variable-dependence traits.
A **uniform** call `fc(t, x, u, v)` always works regardless of traits.
In-place is not supported (always out-of-place).

It carries [`Traits.StateDynamics`](@ref CTBase.Traits.StateDynamics).

**Construction**

```@example data
# Autonomous, fixed (default): fc(x, u)
fc1 = Data.ControlledVectorField((x, u) -> -x + u)

# Non-autonomous, fixed: fc(t, x, u)
fc2 = Data.ControlledVectorField((t, x, u) -> t * x + u; is_autonomous=false)

# Autonomous, non-fixed: fc(x, u, v)
fc3 = Data.ControlledVectorField((x, u, v) -> v * x + u; is_variable=true)

# Scalar state and control
x0, u0 = 1.0, 2.0

fc1
```

**Calling**

```@example data
fc1(x0, u0)                       # natural call
fc1(0.0, x0, u0, nothing)         # uniform call
fc2(0.5, x0, u0)                  # non-autonomous natural call
```

---

## ComposedVectorField

A `ComposedVectorField` is obtained by eliminating the control from a
[`Data.ControlledVectorField`](@ref CTBase.Data.ControlledVectorField) with an
**open-loop** or **closed-loop** [`Data.ControlLaw`](@ref CTBase.Data.ControlLaw):

```math
g(t, x, v) = f_c(t, x, u(\cdots), v),
```

where the control is `u(t, v)` for an open-loop law and `u(t, x, v)` for a
closed-loop law. It is the state-space analogue of
[`Data.ComposedHamiltonian`](@ref CTBase.Data.ComposedHamiltonian).

The **natural** call is `g([t, ]x[, v])`, where the time/variable dependences
are the **join** of the controlled vector field and the control law —
`NonAutonomous`/`NonFixed` win.
A **uniform** call `g(t, x, v)` always works regardless of traits.
In-place is not supported (always out-of-place).

It subtypes [`Data.AbstractVectorField`](@ref CTBase.Data.AbstractVectorField) with
`OutOfPlace` mutability, so it *is* a vector field usable anywhere one is expected.

**Construction**

```@example data
# Controlled vector field fc(x, u) = -x + u  (scalar state/control)
fc = Data.ControlledVectorField((x, u) -> -x + u)

# Closed-loop law u(x) = -x
law = Data.ClosedLoop(x -> -x)

# Composed vector field: g(x) = fc(x, -x) = -2x
g = Data.ComposedVectorField(fc, law)

g
```

The composed time/variable dependences are the **join** of the two inputs —
`NonAutonomous`/`NonFixed` win.

**Calling**

```@example data
g(3.0)                     # natural call: g(x) = -2x
g(0.0, 3.0, nothing)       # uniform call (t, x, v)
```

**Getters**

```@example data
Data.controlled_vector_field(g)   # the underlying ControlledVectorField
Data.control_law(g)               # the ClosedLoop law
```

The constructor rejects `DynClosedLoop` laws with a `MethodError` — that is the
Hamiltonian path (`ComposedHamiltonian`).

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
(`ControlLaw(f, FB, TD, VD)`),
[`Data.ControlledVectorField`](@ref CTBase.Data.ControlledVectorField)
(`ControlledVectorField(f, TD, VD)`),
[`Data.PathConstraint`](@ref CTBase.Data.PathConstraint)
(`PathConstraint(f, K, TD, VD)`),
[`Data.Multiplier`](@ref CTBase.Data.Multiplier)
(`Multiplier(f, TD, VD)`).

---

## See also

- [`Data.VectorField`](@ref CTBase.Data.VectorField), [`Data.Hamiltonian`](@ref CTBase.Data.Hamiltonian), [`Data.PseudoHamiltonian`](@ref CTBase.Data.PseudoHamiltonian), [`Data.ComposedHamiltonian`](@ref CTBase.Data.ComposedHamiltonian), [`Data.HamiltonianVectorField`](@ref CTBase.Data.HamiltonianVectorField), [`Data.ControlledVectorField`](@ref CTBase.Data.ControlledVectorField), [`Data.ComposedVectorField`](@ref CTBase.Data.ComposedVectorField), [`Data.ControlLaw`](@ref CTBase.Data.ControlLaw), [`Data.PathConstraint`](@ref CTBase.Data.PathConstraint), [`Data.Multiplier`](@ref CTBase.Data.Multiplier) — concrete data types.
- [`Data.AbstractVectorField`](@ref CTBase.Data.AbstractVectorField), [`Data.AbstractHamiltonian`](@ref CTBase.Data.AbstractHamiltonian), [`Data.AbstractPseudoHamiltonian`](@ref CTBase.Data.AbstractPseudoHamiltonian), [`Data.AbstractHamiltonianVectorField`](@ref CTBase.Data.AbstractHamiltonianVectorField), [`Data.AbstractControlledVectorField`](@ref CTBase.Data.AbstractControlledVectorField), [`Data.AbstractControlLaw`](@ref CTBase.Data.AbstractControlLaw), [`Data.AbstractPathConstraint`](@ref CTBase.Data.AbstractPathConstraint), [`Data.AbstractMultiplier`](@ref CTBase.Data.AbstractMultiplier) — abstract supertypes.
- [`Data.pseudo_hamiltonian`](@ref CTBase.Data.pseudo_hamiltonian), [`Data.control_law`](@ref CTBase.Data.control_law), [`Data.controlled_vector_field`](@ref CTBase.Data.controlled_vector_field) — getters for composed types.
- [Traits](traits.md) — the three trait axes, the dynamics trait, and call-signature tables.
- [Exceptions](exceptions.md) — `PreconditionError` and `IncorrectArgument`, raised by the constructors and the `variable_costate` path.
