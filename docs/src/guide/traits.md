# Traits: compile-time properties

```@meta
CurrentModule = CTBase
```

[`CTBase.Traits`](@ref CTBase.Traits) provides a small set of **compile-time
traits** shared across the control-toolbox ecosystem. A trait is an abstract type
used as a **type parameter** or returned by an accessor function so that
behaviour can be selected by dispatch, with **no runtime cost**.

```@repl traits
using CTBase
import CTBase.Traits
```

A typical use case is encoding a property of a callable object — does it take a
time argument? does it depend on an extra variable? is it evaluated in-place? —
so that a wrapper type can select the correct call path at compile time, without
runtime conditionals.

## Trait families

### Time dependence

Does the object depend on time ``t``?

| Type | Meaning |
|---|---|
| [`Traits.Autonomous`](@ref CTBase.Traits.Autonomous) | ``t`` is not an argument |
| [`Traits.NonAutonomous`](@ref CTBase.Traits.NonAutonomous) | ``t`` must be supplied |

Both are abstract subtypes of [`Traits.TimeDependence`](@ref CTBase.Traits.TimeDependence).
Because they are abstract, they can only appear as type parameters — they are not
instantiated, only dispatched upon.

```@repl traits
Traits.Autonomous <: Traits.TimeDependence
Traits.NonAutonomous <: Traits.TimeDependence
```

### Variable dependence

Does the object depend on an extra parameter ``v`` (e.g. a free final time or a
design variable)?

| Type | Meaning |
|---|---|
| [`Traits.Fixed`](@ref CTBase.Traits.Fixed) | no ``v`` argument |
| [`Traits.NonFixed`](@ref CTBase.Traits.NonFixed) | ``v`` must be supplied |

Both are concrete subtypes of [`Traits.VariableDependence`](@ref CTBase.Traits.VariableDependence):

```@repl traits
Traits.Fixed <: Traits.VariableDependence
Traits.NonFixed <: Traits.VariableDependence
```

### Control dependence

Does the optimal control problem carry a control input ``u``?

| Type | Meaning |
|---|---|
| [`Traits.ControlFree`](@ref CTBase.Traits.ControlFree) | no control: ``ẋ = f(t, x, v)`` |
| [`Traits.WithControl`](@ref CTBase.Traits.WithControl) | control ``u``: ``ẋ = f(t, x, u, v)`` |

Both are concrete subtypes of [`Traits.ControlDependence`](@ref CTBase.Traits.ControlDependence):

```@repl traits
Traits.ControlFree <: Traits.ControlDependence
Traits.WithControl <: Traits.ControlDependence
```

### Mutability

Does a function allocate a new output, or write into a pre-allocated buffer?

| Type | Meaning |
|---|---|
| [`Traits.OutOfPlace`](@ref CTBase.Traits.OutOfPlace) | returns a new value |
| [`Traits.InPlace`](@ref CTBase.Traits.InPlace) | writes into a buffer (first arg) |

### Feedback

How does a control law close the loop? The feedback trait encodes which arguments
the control law depends on, and therefore which dynamics trait it implies.

| Type | Meaning | Control law signature |
|---|---|---|
| [`Traits.OpenLoopFeedback`](@ref CTBase.Traits.OpenLoopFeedback) | time (and variable) only | `u(t[, v])` |
| [`Traits.ClosedLoopFeedback`](@ref CTBase.Traits.ClosedLoopFeedback) | time and state | `u(t, x[, v])` |
| [`Traits.DynClosedLoopFeedback`](@ref CTBase.Traits.DynClosedLoopFeedback) | time, state, and costate | `u(t, x, p[, v])` |

All three are concrete subtypes of
[`Traits.AbstractFeedback`](@ref CTBase.Traits.AbstractFeedback):

```@repl traits
Traits.OpenLoopFeedback <: Traits.AbstractFeedback
Traits.ClosedLoopFeedback <: Traits.AbstractFeedback
Traits.DynClosedLoopFeedback <: Traits.AbstractFeedback
```

!!! note "Type-parameter-only contract"
    Unlike time-, variable-, and control-dependence (which use the two-method
    opt-in contract), feedback follows a **type-parameter-only** contract: the
    trait value is read from a type parameter of the concrete data type (e.g.
    `ControlLaw{F,FB,TD,VD}`) by the
    [`Traits.feedback`](@ref CTBase.Traits.feedback) accessor. No
    `has_feedback_trait` guard is provided; calling `feedback` on a type that
    does not implement it yields a standard `MethodError`.

The boolean predicates
[`Traits.is_open_loop`](@ref CTBase.Traits.is_open_loop),
[`Traits.is_closed_loop`](@ref CTBase.Traits.is_closed_loop), and
[`Traits.is_dyn_closed_loop`](@ref CTBase.Traits.is_dyn_closed_loop) dispatch
on the feedback type parameter:

```@repl traits
using CTBase.Data
u = Data.OpenLoop(() -> 1.0)
Traits.feedback(u)
Traits.is_open_loop(u)
```

The feedback trait also determines the dynamics trait: open-loop and closed-loop
control laws carry [`Traits.StateDynamics`](@ref CTBase.Traits.StateDynamics)
(no costate), while dynamic closed-loop control laws carry
[`Traits.HamiltonianDynamics`](@ref CTBase.Traits.HamiltonianDynamics).

### Constraint kind

Which primal variables does a path constraint `g(...)` depend on? The
constraint-kind trait encodes this at the type level.

| Type | Meaning | Constraint signature |
|---|---|---|
| [`Traits.StateConstraintKind`](@ref CTBase.Traits.StateConstraintKind) | state only | `g(x)` |
| [`Traits.ControlConstraintKind`](@ref CTBase.Traits.ControlConstraintKind) | control only | `g(u)` |
| [`Traits.MixedConstraintKind`](@ref CTBase.Traits.MixedConstraintKind) | state and control | `g(x, u)` |

All three are concrete subtypes of
[`Traits.AbstractConstraintKind`](@ref CTBase.Traits.AbstractConstraintKind):

```@repl traits
Traits.StateConstraintKind <: Traits.AbstractConstraintKind
Traits.ControlConstraintKind <: Traits.AbstractConstraintKind
Traits.MixedConstraintKind <: Traits.AbstractConstraintKind
```

!!! note "Type-parameter-only contract"
    Like feedback, constraint kind follows a **type-parameter-only** contract: the
    trait value is read from a type parameter of the concrete data type (e.g.
    `PathConstraint{F,K,TD,VD}`) by the
    [`Traits.constraint_kind`](@ref CTBase.Traits.constraint_kind) accessor. No
    `has_constraint_kind_trait` guard is provided; calling `constraint_kind` on a
    type that does not implement it yields a standard `MethodError`.

The boolean predicates
[`Traits.is_state_constraint`](@ref CTBase.Traits.is_state_constraint),
[`Traits.is_control_constraint`](@ref CTBase.Traits.is_control_constraint), and
[`Traits.is_mixed_constraint`](@ref CTBase.Traits.is_mixed_constraint) dispatch
on the constraint-kind type parameter:

```@repl traits
using CTBase.Data
g = Data.StateConstraint(x -> x[1])
Traits.constraint_kind(g)
Traits.is_state_constraint(g)
```

### Other families

These traits encode properties that are fixed at construction time and carried
as type parameters. They are not opted into via the two-method contract described
below — they are passed directly as type arguments.

| Family | Values |
|---|---|
| Integration mode | [`Traits.EndPointMode`](@ref CTBase.Traits.EndPointMode), [`Traits.TrajectoryMode`](@ref CTBase.Traits.TrajectoryMode) |
| Dynamics | [`Traits.StateDynamics`](@ref CTBase.Traits.StateDynamics), [`Traits.HamiltonianDynamics`](@ref CTBase.Traits.HamiltonianDynamics), [`Traits.AugmentedHamiltonianDynamics`](@ref CTBase.Traits.AugmentedHamiltonianDynamics) |
| Automatic differentiation | [`Traits.WithAD`](@ref CTBase.Traits.WithAD), [`Traits.WithoutAD`](@ref CTBase.Traits.WithoutAD) |
| Variable costate | [`Traits.SupportsVariableCostate`](@ref CTBase.Traits.SupportsVariableCostate), [`Traits.NoVariableCostate`](@ref CTBase.Traits.NoVariableCostate) |
| Feedback | [`Traits.OpenLoopFeedback`](@ref CTBase.Traits.OpenLoopFeedback), [`Traits.ClosedLoopFeedback`](@ref CTBase.Traits.ClosedLoopFeedback), [`Traits.DynClosedLoopFeedback`](@ref CTBase.Traits.DynClosedLoopFeedback) |

!!! note "Abstract tags vs. concrete tags"
    Time-dependence tags (`Autonomous`, `NonAutonomous`) are **abstract** types
    because they are only ever used as type-parameter *values* (e.g. `Model{Autonomous}`)
    — never instantiated. All other tags (`Fixed`/`NonFixed`, `ControlFree`/`WithControl`,
    `InPlace`/`OutOfPlace`, …) are **concrete** empty singletons. In practice every tag
    is compared as a type (`control_dependence(obj) === Traits.ControlFree`), so the
    two forms are used interchangeably; the distinction is historical, not semantic.

## The trait contract — two templates

Trait families follow one of **two contracts**, and the choice is dictated by a
single question: **does a safe default value exist?**

- **Strict opt-in (no safe default).** Time-, variable-, and control-dependence,
  and mutability. An object is *either* autonomous or not, *either* control-free or
  not — guessing silently would be a correctness bug, so there is no default. A type
  must opt in by implementing **two methods**: one declaring that it *has* the trait,
  one returning the trait *value*. The boolean predicates
  ([`Traits.is_autonomous`](@ref CTBase.Traits.is_autonomous),
  [`Traits.is_control_free`](@ref CTBase.Traits.is_control_free), …) then follow
  generically. If a type does not opt in, the predicates throw rather than guess.
- **Default-valued capability (safe default exists).** Automatic differentiation
  and variable costate are *capabilities*: a conservative "no" is always safe. The
  extractor returns a default for any object
  ([`Traits.ad_trait`](@ref CTBase.Traits.ad_trait) ``→`` `WithoutAD`,
  [`Traits.variable_costate_trait`](@ref CTBase.Traits.variable_costate_trait) ``→``
  `NoVariableCostate`) and concrete types override it — no `has_*` method, no
  predicates.

The "Other families" above (integration mode, dynamics) use neither contract: they
are read directly from a concrete type's parameters.

For the strict opt-in families — time, variable and control dependence:

```@repl traits
struct MyObject end

Traits.has_time_dependence_trait(::MyObject) = true
Traits.time_dependence(::MyObject) = Traits.NonAutonomous

Traits.has_variable_dependence_trait(::MyObject) = true
Traits.variable_dependence(::MyObject) = Traits.Fixed

Traits.has_control_dependence_trait(::MyObject) = true
Traits.control_dependence(::MyObject) = Traits.WithControl

obj = MyObject()
Traits.is_autonomous(obj)
Traits.is_nonautonomous(obj)
Traits.is_variable(obj)
Traits.is_nonvariable(obj)
Traits.is_control_free(obj)
Traits.has_control(obj)
```

For mutability, the same pattern applies with `has_mutability_trait` and `mutability`:

```@repl traits
struct MyMutableObject end

Traits.has_mutability_trait(::MyMutableObject) = true
Traits.mutability(::MyMutableObject) = Traits.InPlace

Traits.is_inplace(MyMutableObject())
Traits.is_outofplace(MyMutableObject())
```

If a type does not declare a trait, the predicates throw an informative error
rather than returning a wrong default:

```@repl traits
try # hide
Traits.is_autonomous(3.14)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

!!! note "Trait types are shared"
    Because trait types (e.g. `Traits.Autonomous`) are defined in a single place,
    a type that carries `Traits.Autonomous` as a type parameter and an object that
    implements `time_dependence` returning `Traits.Autonomous` are compatible by
    construction — no conversion or mapping needed.

## Accessor / predicate summary

| Trait value function | Boolean predicates |
|---|---|
| [`Traits.time_dependence`](@ref CTBase.Traits.time_dependence) | `is_autonomous`, `is_nonautonomous` |
| [`Traits.variable_dependence`](@ref CTBase.Traits.variable_dependence) | `is_variable`, `is_nonvariable`, `has_variable` |
| [`Traits.control_dependence`](@ref CTBase.Traits.control_dependence) | `is_control_free`, `has_control` |
| [`Traits.mutability`](@ref CTBase.Traits.mutability) | `is_inplace`, `is_outofplace` |
| [`Traits.ad_trait`](@ref CTBase.Traits.ad_trait) | — |
| [`Traits.variable_costate_trait`](@ref CTBase.Traits.variable_costate_trait) | — |
| [`Traits.dynamics_trait`](@ref CTBase.Traits.dynamics_trait) | — |
| [`Traits.feedback`](@ref CTBase.Traits.feedback) | `is_open_loop`, `is_closed_loop`, `is_dyn_closed_loop` |
| [`Traits.constraint_kind`](@ref CTBase.Traits.constraint_kind) | `is_state_constraint`, `is_control_constraint`, `is_mixed_constraint` |

## See Also

- [Exceptions guide](exceptions.md) — understanding `IncorrectArgument` and `NotImplemented`.
