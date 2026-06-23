"""
    Traits

Trait types and trait-based dispatch shared across the control-toolbox ecosystem.

This module provides the trait system used for compile-time dispatch on:
- Time dependence: [`Autonomous`](@ref), [`NonAutonomous`](@ref)
- Variable dependence: [`Fixed`](@ref), [`NonFixed`](@ref)
- Integration mode: [`EndPointMode`](@ref), [`TrajectoryMode`](@ref)
- Dynamics type: [`StateDynamics`](@ref), [`HamiltonianDynamics`](@ref), [`AugmentedHamiltonianDynamics`](@ref)
- Mutability: [`InPlace`](@ref), [`OutOfPlace`](@ref)
- Automatic differentiation: [`WithAD`](@ref), [`WithoutAD`](@ref)
- Variable costate capability: [`SupportsVariableCostate`](@ref), [`NoVariableCostate`](@ref)

Traits are used as type parameters in configuration types, vector fields, and systems
to enable static dispatch without runtime type checks.

The time-dependence trait types (`TimeDependence`, `Autonomous`, `NonAutonomous`)
historically lived in `CTModels.Components`; they are now defined here so the whole
ecosystem shares a single set of types (CTModels consumes them from here).
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
