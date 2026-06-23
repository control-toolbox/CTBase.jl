# Traits: compile-time properties

```@meta
CurrentModule = CTBase
```

[`CTBase.Traits`](@ref CTBase.Traits) provides a small set of **compile-time
traits** shared across the control-toolbox ecosystem. Traits are empty marker
types used as type parameters (or returned by accessor functions) so that
behaviour can be selected by dispatch, with **no runtime cost**.

```@repl traits
using CTBase
import CTBase.Traits
```

Downstream packages use these traits to encode, for example, the **call
signature** of a vector field or Hamiltonian, and to dispatch system builders
without runtime branches.

## Trait families

### Time dependence

Does the object depend on time ``t``?

| Type | Meaning |
|---|---|
| [`Traits.Autonomous`](@ref CTBase.Traits.Autonomous) | ``t`` is not an argument |
| [`Traits.NonAutonomous`](@ref CTBase.Traits.NonAutonomous) | ``t`` must be supplied |

Both are abstract subtypes of [`Traits.TimeDependence`](@ref CTBase.Traits.TimeDependence).
They are used as the time-dependence type parameter of `CTModels.Model` and of
CTFlows data wrappers.

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

```@repl traits
Traits.Fixed <: Traits.VariableDependence
Traits.NonFixed <: Traits.VariableDependence
```

### Mutability

Does a function allocate a new output, or write into a pre-allocated buffer?

| Type | Meaning |
|---|---|
| [`Traits.OutOfPlace`](@ref CTBase.Traits.OutOfPlace) | returns a new value |
| [`Traits.InPlace`](@ref CTBase.Traits.InPlace) | writes into a buffer (first arg) |

### Other families

| Family | Values |
|---|---|
| Integration mode | [`Traits.EndPointMode`](@ref CTBase.Traits.EndPointMode), [`Traits.TrajectoryMode`](@ref CTBase.Traits.TrajectoryMode) |
| Dynamics | [`Traits.StateDynamics`](@ref CTBase.Traits.StateDynamics), [`Traits.HamiltonianDynamics`](@ref CTBase.Traits.HamiltonianDynamics), [`Traits.AugmentedHamiltonianDynamics`](@ref CTBase.Traits.AugmentedHamiltonianDynamics) |
| Automatic differentiation | [`Traits.WithAD`](@ref CTBase.Traits.WithAD), [`Traits.WithoutAD`](@ref CTBase.Traits.WithoutAD) |
| Variable costate | [`Traits.SupportsVariableCostate`](@ref CTBase.Traits.SupportsVariableCostate), [`Traits.NoVariableCostate`](@ref CTBase.Traits.NoVariableCostate) |

## The trait contract

A type opts in to a trait by implementing **two methods**: one declaring that it
*has* the trait, and one returning the trait *value*. The boolean predicates
([`Traits.is_autonomous`](@ref CTBase.Traits.is_autonomous),
[`Traits.is_variable`](@ref CTBase.Traits.is_variable), …) then follow
generically — they are not implemented per type.

For time dependence, implement `has_time_dependence_trait` and `time_dependence`:

```@repl traits
struct MyObject end

Traits.has_time_dependence_trait(::MyObject) = true
Traits.time_dependence(::MyObject) = Traits.NonAutonomous

Traits.has_variable_dependence_trait(::MyObject) = true
Traits.variable_dependence(::MyObject) = Traits.Fixed

obj = MyObject()
Traits.is_autonomous(obj)      # false  (derived from time_dependence)
Traits.is_nonautonomous(obj)   # true
Traits.is_variable(obj)        # false  (derived from variable_dependence)
Traits.is_nonvariable(obj)     # true
```

If a type does not declare a trait, the predicates throw an informative error
rather than returning a wrong default:

```@repl traits
Traits.is_autonomous(3.14)
```

!!! note "Single source of truth"
    `Traits.Autonomous` / `Traits.NonAutonomous` are the very types used as the
    `CTModels.Model` time-dependence parameter, so `Traits.time_dependence(model)`
    and `Traits.is_autonomous(model)` work out of the box on a real optimal
    control problem.

## Accessor / predicate summary

| Trait value function | Boolean predicates |
|---|---|
| [`Traits.time_dependence`](@ref CTBase.Traits.time_dependence) | `is_autonomous`, `is_nonautonomous` |
| [`Traits.variable_dependence`](@ref CTBase.Traits.variable_dependence) | `is_variable`, `is_nonvariable`, `has_variable` |
| [`Traits.mutability`](@ref CTBase.Traits.mutability) | `is_inplace`, `is_outofplace` |
| [`Traits.ad_trait`](@ref CTBase.Traits.ad_trait) | — |
| [`Traits.variable_costate_trait`](@ref CTBase.Traits.variable_costate_trait) | — |
| [`Traits.dynamics_trait`](@ref CTBase.Traits.dynamics_trait) | — |
