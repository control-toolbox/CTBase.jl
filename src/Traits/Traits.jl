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
- **Mutability**: `InPlace`, `OutOfPlace`
- **Integration mode**: `EndPointMode`, `TrajectoryMode`
- **Dynamics**: `StateDynamics`, `HamiltonianDynamics`, `AugmentedHamiltonianDynamics`
- **Automatic differentiation**: `WithAD`, `WithoutAD`
- **Variable costate**: `SupportsVariableCostate`, `NoVariableCostate`

## Trait contract

For time-dependence, variable-dependence, and mutability, a type opts in by
implementing two methods — `has_<family>_trait` returning `true`, and an accessor
(`time_dependence`, `variable_dependence`, `mutability`) returning the trait type.
Boolean predicates (`is_autonomous`, `is_variable`, `is_inplace`, …) are then
derived generically.

The remaining families (`EndPointMode`, `StateDynamics`, `WithAD`,
`SupportsVariableCostate`) are used as type parameters only and do not use the
two-method contract.
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
export ad_trait, variable_costate_trait, dynamics_trait
export is_inplace, is_outofplace
export is_autonomous, is_nonautonomous, is_variable, is_nonvariable, has_variable
export has_time_dependence_trait, time_dependence, has_mutability_trait, mutability
export has_variable_dependence_trait, variable_dependence

end # module Traits
