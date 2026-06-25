"""
# ============================================================================
# Data Module Exports Tests
# ============================================================================
# This file tests the exports from the `Data` module. It verifies that
# the expected types are properly exported by `CTBase.Data` and readily
# accessible to the end user.
#
# Functionality tests are in separate files:
# - test_abstract_vector_field.jl for abstract vector field types
# - test_vector_field.jl for VectorField constructor and functionality
# - test_abstract_hamiltonian.jl for abstract Hamiltonian types
# - test_hamiltonian.jl for Hamiltonian constructor and functionality
# - test_abstract_hamiltonian_vector_field.jl for abstract HVF types
# - test_hamiltonian_vector_field.jl for HVF constructor and functionality
# - test_helpers.jl for helper functions
"""

module TestDataModule

import Test
import CTBase
import CTBase.Data
using CTBase.Data  # For testing exported symbols

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

const CurrentModule = TestDataModule

# ============================================================================
# Hardcoded export lists
# ============================================================================
# These lists define the expected public API of the Data module.

const EXPORTED_ABSTRACT_TYPES = (
    :AbstractVectorField,
    :AbstractHamiltonianVectorField,
    :AbstractHamiltonian,
)

const EXPORTED_CONCRETE_TYPES = (
    :VectorField,
    :HamiltonianVectorField,
    :Hamiltonian,
)

const PRIVATE_SYMBOLS = (
    :__is_autonomous,
    :__is_inplace,
    :__is_variable,
    :_detect_mutability_hvf,
    :_detect_mutability_vf,
    :_md_label,
    :_natural_sig_h,
    :_natural_sig_hvf,
    :_natural_sig_vf,
    :_oop_arity_hvf,
    :_oop_arity_vf,
    :_td_label,
    :_uniform_sig_h,
    :_uniform_sig_hvf,
    :_uniform_sig_vf,
    :_vd_label,
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

function test_data_module()
    Test.@testset "Data Module Exports" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # Module availability
        # ====================================================================

        Test.@testset "Module availability" begin
            Test.@testset "Data module exists" begin
                Test.@test isdefined(CTBase, :Data)
                Test.@test CTBase.Data isa Module
            end
        end

        # ====================================================================
        # Exported abstract types verification
        # ====================================================================

        Test.@testset "Exported abstract types" begin
            test_exported_symbols(Data, EXPORTED_ABSTRACT_TYPES, CurrentModule)
        end

        # ====================================================================
        # Exported concrete types verification
        # ====================================================================

        Test.@testset "Exported concrete types" begin
            test_exported_symbols(Data, EXPORTED_CONCRETE_TYPES, CurrentModule)
        end

        # ====================================================================
        # Private symbols (not exported) verification
        # ====================================================================

        Test.@testset "Private symbols (not exported)" begin
            test_internal_symbols(Data, PRIVATE_SYMBOLS, CurrentModule)
        end

        # ====================================================================
        # Type hierarchy tests
        # ====================================================================

        Test.@testset "Type hierarchy" begin
            Test.@testset "Abstract types are abstract" begin
                Test.@test isabstracttype(Data.AbstractVectorField)
                Test.@test isabstracttype(Data.AbstractHamiltonianVectorField)
                Test.@test isabstracttype(Data.AbstractHamiltonian)
            end

            Test.@testset "Concrete types inherit from abstract types" begin
                Test.@test Data.VectorField <: Data.AbstractVectorField
                Test.@test Data.HamiltonianVectorField <: Data.AbstractHamiltonianVectorField
                # Note: Hamiltonian is parametric (Hamiltonian{F, TD, VD} <: AbstractHamiltonian{TD, VD})
                # Test via instance instead of type
                h = Data.Hamiltonian((x, p) -> 0.0)
                Test.@test h isa Data.AbstractHamiltonian
            end
        end
    end
end

end # module TestDataModule

# CRITICAL: Redefine in outer scope for TestRunner
test_data_module() = TestDataModule.test_data_module()
