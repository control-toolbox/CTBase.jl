"""
# ============================================================================
# Traits Module Exports Tests
# ============================================================================
# This file tests the exports from the `Traits` module. It verifies that
# the expected types and functions are properly exported by
# `CTBase.Traits` and readily accessible to the end user.
#
# Functionality tests are in separate files:
# - test_abstract_traits.jl for abstract trait types
# - test_ad.jl for AD traits
# - test_dynamics.jl for dynamics traits
# - test_mode.jl for mode traits
# - test_mutability.jl for mutability traits
# - test_time_dependence.jl for time dependence traits
# - test_variable_costate.jl for variable costate traits
# - test_variable_dependence.jl for variable dependence traits
"""

module TestTraitsModule

import Test
import CTBase
import CTBase.Traits
using CTBase.Traits  # For testing exported symbols

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

const CurrentModule = TestTraitsModule

# ============================================================================
# Hardcoded export lists
# ============================================================================
# These lists define the expected public API of the Traits module.

const EXPORTED_ABSTRACT_TYPES = (
    :AbstractTrait,
    :AbstractModeTrait,
    :AbstractDynamicsTrait,
    :AbstractMutabilityTrait,
    :AbstractADTrait,
    :AbstractVariableCostateCapability,
    :TimeDependence,
    :VariableDependence,
)

const EXPORTED_CONCRETE_TYPES = (
    :EndPointMode,
    :TrajectoryMode,
    :StateDynamics,
    :HamiltonianDynamics,
    :AugmentedHamiltonianDynamics,
    :InPlace,
    :OutOfPlace,
    :WithAD,
    :WithoutAD,
    :SupportsVariableCostate,
    :NoVariableCostate,
    :Autonomous,
    :NonAutonomous,
    :Fixed,
    :NonFixed,
)

const EXPORTED_FUNCTIONS = (
    :ad_trait,
    :variable_costate_trait,
    :is_inplace,
    :is_outofplace,
    :has_time_dependence_trait,
    :time_dependence,
    :has_mutability_trait,
    :mutability,
    :has_variable_dependence_trait,
    :variable_dependence,
    :is_autonomous,
    :is_nonautonomous,
    :is_variable,
    :is_nonvariable,
    :has_variable,
)

const PRIVATE_SYMBOLS = (
    :_caller_function_name,
)

# ============================================================================
# Helper functions (generic for reuse in other modules)
# ============================================================================

"""
    test_exported_symbols(module_ref::Module, symbols::Tuple, test_module::Module)

Test that symbols are exported from a module and available via `using`.
"""
function test_exported_symbols(module_ref::Module, symbols::Tuple, test_module::Module)
    for sym in symbols
        Test.@testset "$(sym)" begin
            Test.@test isdefined(module_ref, sym)
            Test.@test isdefined(test_module, sym)
        end
    end
end

"""
    test_internal_symbols(module_ref::Module, symbols::Tuple, test_module::Module)

Test that symbols are defined in a module but NOT exported (not available via `using`).
Generic helper for modules with private symbols.
"""
function test_internal_symbols(module_ref::Module, symbols::Tuple, test_module::Module)
    for sym in symbols
        Test.@testset "$(sym)" begin
            Test.@test isdefined(module_ref, sym)
            Test.@test !isdefined(test_module, sym)
        end
    end
end

# ============================================================================
# Test function
# ============================================================================

function test_traits_module()
    Test.@testset "Traits Module Exports" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # Module availability
        # ====================================================================

        Test.@testset "Module availability" begin
            Test.@testset "Traits module exists" begin
                Test.@test isdefined(CTBase, :Traits)
                Test.@test CTBase.Traits isa Module
            end
        end

        # ====================================================================
        # Exported abstract types verification
        # ====================================================================

        Test.@testset "Exported abstract types" begin
            test_exported_symbols(Traits, EXPORTED_ABSTRACT_TYPES, CurrentModule)
        end

        # ====================================================================
        # Exported concrete types verification
        # ====================================================================

        Test.@testset "Exported concrete types" begin
            test_exported_symbols(Traits, EXPORTED_CONCRETE_TYPES, CurrentModule)
        end

        # ====================================================================
        # Exported functions verification
        # ====================================================================

        Test.@testset "Exported functions" begin
            test_exported_symbols(Traits, EXPORTED_FUNCTIONS, CurrentModule)
        end

        # ====================================================================
        # Private symbols (not exported) verification
        # ====================================================================

        Test.@testset "Private symbols (not exported)" begin
            test_internal_symbols(Traits, PRIVATE_SYMBOLS, CurrentModule)
        end

        # ====================================================================
        # Type hierarchy tests
        # ====================================================================

        Test.@testset "Type hierarchy" begin
            Test.@testset "Abstract types are abstract" begin
                Test.@test isabstracttype(Traits.AbstractTrait)
                Test.@test isabstracttype(Traits.AbstractModeTrait)
                Test.@test isabstracttype(Traits.AbstractDynamicsTrait)
                Test.@test isabstracttype(Traits.AbstractMutabilityTrait)
                Test.@test isabstracttype(Traits.AbstractADTrait)
                Test.@test isabstracttype(Traits.AbstractVariableCostateCapability)
                Test.@test isabstracttype(Traits.TimeDependence)
                Test.@test isabstracttype(Traits.VariableDependence)
            end

            Test.@testset "Concrete types inherit from abstract types" begin
                Test.@test Traits.EndPointMode <: Traits.AbstractModeTrait
                Test.@test Traits.TrajectoryMode <: Traits.AbstractModeTrait
                Test.@test Traits.StateDynamics <: Traits.AbstractDynamicsTrait
                Test.@test Traits.HamiltonianDynamics <: Traits.AbstractDynamicsTrait
                Test.@test Traits.AugmentedHamiltonianDynamics <: Traits.AbstractDynamicsTrait
                Test.@test Traits.InPlace <: Traits.AbstractMutabilityTrait
                Test.@test Traits.OutOfPlace <: Traits.AbstractMutabilityTrait
                Test.@test Traits.WithAD <: Traits.AbstractADTrait
                Test.@test Traits.WithoutAD <: Traits.AbstractADTrait
                Test.@test Traits.SupportsVariableCostate <: Traits.AbstractVariableCostateCapability
                Test.@test Traits.NoVariableCostate <: Traits.AbstractVariableCostateCapability
                Test.@test Traits.Autonomous <: Traits.TimeDependence
                Test.@test Traits.NonAutonomous <: Traits.TimeDependence
                Test.@test Traits.Fixed <: Traits.VariableDependence
                Test.@test Traits.NonFixed <: Traits.VariableDependence
            end
        end
    end
end

end # module

test_traits_module() = TestTraitsModule.test_traits_module()
