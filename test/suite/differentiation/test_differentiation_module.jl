"""
# ============================================================================
# Differentiation Module Exports Tests
# ============================================================================
# This file tests the exports from the `Differentiation` module. It verifies that
# the expected types and functions are properly exported by
# `CTBase.Differentiation` and readily accessible to the end user.
#
# Functionality tests are in separate files:
# - test_ad_backend.jl for AD backend functionality
# - test_arg_placement.jl for differentiate/pushforward primitives
"""

module TestDifferentiationModule

using Test: Test
using CTBase: CTBase
import CTBase.Differentiation
using CTBase.Differentiation  # For testing exported symbols

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

const CurrentModule = TestDifferentiationModule

# ============================================================================
# Hardcoded export lists
# ============================================================================
# These lists define the expected public API of the Differentiation module.

const EXPORTED_ABSTRACT_TYPES = (:AbstractADBackend,)

const EXPORTED_CONCRETE_TYPES = (:DifferentiationInterface,)

const EXPORTED_FUNCTIONS = (
    :build_ad_backend,
    :ad_backend,
    :hamiltonian_gradient,
    :pseudo_hamiltonian_gradient,
    :pseudo_hamiltonian_control_gradient,
    :variable_gradient,
    :gradient,
    :derivative,
    :differentiate,
    :pushforward,
)

# Note: Differentiation module has no private symbols (after filtering Julia internals)
# All symbols are exported

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

function test_differentiation_module()
    Test.@testset "Differentiation Module Exports" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # Module availability
        # ====================================================================

        Test.@testset "Module availability" begin
            Test.@testset "Differentiation module exists" begin
                Test.@test isdefined(CTBase, :Differentiation)
                Test.@test CTBase.Differentiation isa Module
            end
        end

        # ====================================================================
        # Exported abstract types verification
        # ====================================================================

        Test.@testset "Exported abstract types" begin
            test_exported_symbols(Differentiation, EXPORTED_ABSTRACT_TYPES, CurrentModule)
        end

        # ====================================================================
        # Exported concrete types verification
        # ====================================================================

        Test.@testset "Exported concrete types" begin
            test_exported_symbols(Differentiation, EXPORTED_CONCRETE_TYPES, CurrentModule)
        end

        # ====================================================================
        # Exported functions verification
        # ====================================================================

        Test.@testset "Exported functions" begin
            test_exported_symbols(Differentiation, EXPORTED_FUNCTIONS, CurrentModule)
        end

        # ====================================================================
        # Type hierarchy tests
        # ====================================================================

        Test.@testset "Type hierarchy" begin
            Test.@testset "Abstract types are abstract" begin
                Test.@test isabstracttype(Differentiation.AbstractADBackend)
            end

            Test.@testset "Concrete types inherit from abstract types" begin
                Test.@test Differentiation.DifferentiationInterface <:
                    Differentiation.AbstractADBackend
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_differentiation_module() = TestDifferentiationModule.test_differentiation_module()
