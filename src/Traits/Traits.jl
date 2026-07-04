"""
    Traits

Compile-time trait types and trait-based dispatch utilities.

Traits are abstract or empty concrete types used as type parameters or returned
by accessor functions. Behaviour is selected by dispatch at compile time, with
no runtime cost.

# Organization

- **abstract.jl**: Root abstract type `AbstractTrait` and family abstractions
- **time_dependence.jl**: Time-dependence traits and the opt-in contract
- **variable_dependence.jl**: Variable-dependence traits and the opt-in contract
- **control_dependence.jl**: Control-dependence traits and the opt-in contract
- **feedback.jl**: Feedback traits (`OpenLoopFeedback`, `ClosedLoopFeedback`, `DynClosedLoopFeedback`)
- **mutability.jl**: Mutability traits and the opt-in contract
- **mode.jl**: Integration-mode traits (`EndPointMode`, `TrajectoryMode`)
- **dynamics.jl**: Dynamics-type traits (`StateDynamics`, `HamiltonianDynamics`, `AugmentedHamiltonianDynamics`)
- **ad.jl**: Automatic-differentiation traits (`WithAD`, `WithoutAD`)
- **variable_costate.jl**: Variable-costate traits (`SupportsVariableCostate`, `NoVariableCostate`)
- **helpers.jl**: Internal utility (`_caller_function_name`)

# Public API

## Trait families

- **Time dependence**: `TimeDependence`, `Autonomous`, `NonAutonomous`
- **Variable dependence**: `VariableDependence`, `Fixed`, `NonFixed`
- **Control dependence**: `ControlDependence`, `ControlFree`, `WithControl`
- **Feedback**: `AbstractFeedback`, `OpenLoopFeedback`, `ClosedLoopFeedback`, `DynClosedLoopFeedback`
- **Mutability**: `InPlace`, `OutOfPlace`
- **Integration mode**: `EndPointMode`, `TrajectoryMode`
- **Dynamics**: `StateDynamics`, `HamiltonianDynamics`, `AugmentedHamiltonianDynamics`
- **Automatic differentiation**: `WithAD`, `WithoutAD`
- **Variable costate**: `SupportsVariableCostate`, `NoVariableCostate`

## Trait contracts — two templates

Trait families follow one of two contracts. The choice is dictated by a single
question: **does a safe default value exist?**

**1. Strict opt-in (no safe default).** Time-dependence, variable-dependence,
control-dependence, and mutability. Guessing a value silently would be a
correctness bug (an object is *either* autonomous or not), so there is no default:
a type must opt in by implementing two methods — `has_<family>_trait` returning
`true`, and an accessor (`time_dependence`, `variable_dependence`,
`control_dependence`, `mutability`) returning the trait type. The fallbacks throw
loudly ([`CTBase.Exceptions.IncorrectArgument`](@ref) /
[`CTBase.Exceptions.NotImplemented`](@ref)) via the shared helpers
`_throw_missing_trait` / `_throw_trait_not_implemented`. Boolean predicates
(`is_autonomous`, `is_variable`, `is_control_free`, `is_inplace`, …) are derived
generically.

**2. Default-valued capability (safe default exists).** Automatic differentiation
(`ad_trait(::Any) = WithoutAD`) and variable-costate
(`variable_costate_trait(::Any) = NoVariableCostate`). These are *capabilities*: a
conservative "no" is always safe, so the extractor returns a default for any object
and concrete types override it. No `has_<family>_trait` guard, no derived predicates.

The remaining families (`EndPointMode`, `StateDynamics`) are used as type
parameters only (read from a concrete type's parameters, e.g.
`AbstractSystem{TD,VD,D}`) and use neither contract.
"""
module Traits

# ==============================================================================
# External package imports
# ==============================================================================

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import CTBase.Exceptions

# ==============================================================================
# Includes
# ==============================================================================

include(joinpath(@__DIR__, "helpers.jl"))
include(joinpath(@__DIR__, "abstract.jl"))
include(joinpath(@__DIR__, "mode.jl"))
include(joinpath(@__DIR__, "dynamics.jl"))
include(joinpath(@__DIR__, "ad.jl"))
include(joinpath(@__DIR__, "variable_costate.jl"))
include(joinpath(@__DIR__, "mutability.jl"))
include(joinpath(@__DIR__, "time_dependence.jl"))
include(joinpath(@__DIR__, "variable_dependence.jl"))
include(joinpath(@__DIR__, "control_dependence.jl"))
include(joinpath(@__DIR__, "feedback.jl"))

# ==============================================================================
# Module exports
# ==============================================================================

export AbstractTrait
export AbstractModeTrait, AbstractDynamicsTrait
export AbstractMutabilityTrait
export AbstractADTrait
export AbstractVariableCostateCapability
export TimeDependence, Autonomous, NonAutonomous
export EndPointMode, TrajectoryMode
export StateDynamics, HamiltonianDynamics, AugmentedHamiltonianDynamics
export InPlace, OutOfPlace
export WithAD, WithoutAD
export SupportsVariableCostate, NoVariableCostate
export VariableDependence, Fixed, NonFixed
export ControlDependence, ControlFree, WithControl
export AbstractFeedback, OpenLoopFeedback, ClosedLoopFeedback, DynClosedLoopFeedback
export ad_trait, variable_costate_trait, dynamics_trait, feedback
export is_open_loop, is_closed_loop, is_dyn_closed_loop
export is_inplace, is_outofplace
export is_autonomous, is_nonautonomous, is_variable, is_nonvariable, has_variable
export is_control_free, has_control
export has_time_dependence_trait, time_dependence, has_mutability_trait, mutability
export has_variable_dependence_trait, variable_dependence
export has_control_dependence_trait, control_dependence

end # module Traits
