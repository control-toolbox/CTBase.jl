module TestVariableDependence

import Test
import CTBase.Exceptions
import CTBase.Traits

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ==============================================================================
# Fake types for contract testing
# ==============================================================================

"""
Fake type for testing variable-dependence trait pattern.
Implements both required methods: has_variable_dependence_trait and variable_dependence.
"""
struct FakeFixed end

Traits.has_variable_dependence_trait(::FakeFixed) = true
Traits.variable_dependence(::FakeFixed) = Traits.Fixed

"""
Fake type for testing variable-dependence trait pattern with NonFixed.
"""
struct FakeNonFixed end

Traits.has_variable_dependence_trait(::FakeNonFixed) = true
Traits.variable_dependence(::FakeNonFixed) = Traits.NonFixed

function test_variable_dependence()
    Test.@testset "Variable Dependence Trait Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Trait Types
        # ====================================================================

        Test.@testset "UNIT TESTS - Trait Types" begin
            Test.@testset "VariableDependence abstract type" begin
                Test.@test isdefined(Traits, :VariableDependence)
                Test.@test Traits.Fixed <: Traits.VariableDependence
                Test.@test Traits.NonFixed <: Traits.VariableDependence
            end

            Test.@testset "Concrete trait types" begin
                Test.@test Traits.Fixed() isa Traits.Fixed
                Test.@test Traits.NonFixed() isa Traits.NonFixed
            end
        end

        # ====================================================================
        # ERROR TESTS - Fallback Methods
        # ====================================================================

        Test.@testset "ERROR TESTS - Fallback Methods" begin
            Test.@testset "has_variable_dependence_trait throws IncorrectArgument" begin
                obj = "not a trait object"
                Test.@test_throws Exceptions.IncorrectArgument Traits.has_variable_dependence_trait(obj)
            end

            Test.@testset "variable_dependence throws IncorrectArgument" begin
                obj = "not a trait object"
                Test.@test_throws Exceptions.IncorrectArgument Traits.variable_dependence(obj)
            end
        end

        # ====================================================================
        # CONTRACT TESTS - Variable-Dependence Trait Pattern
        # ====================================================================

        Test.@testset "CONTRACT TESTS - Variable-Dependence Trait Pattern" begin
            Test.@testset "FakeFixed trait implementation" begin
                obj = FakeFixed()
                Test.@test Traits.has_variable_dependence_trait(obj) === true
                Test.@test Traits.variable_dependence(obj) === Traits.Fixed
                Test.@test Traits.is_variable(obj) === false
                Test.@test Traits.is_nonvariable(obj) === true
                Test.@test Traits.has_variable(obj) === false
            end

            Test.@testset "FakeNonFixed trait implementation" begin
                obj = FakeNonFixed()
                Test.@test Traits.has_variable_dependence_trait(obj) === true
                Test.@test Traits.variable_dependence(obj) === Traits.NonFixed
                Test.@test Traits.is_variable(obj) === true
                Test.@test Traits.is_nonvariable(obj) === false
                Test.@test Traits.has_variable(obj) === true
            end
        end

        # ====================================================================
        # Exports Verification
        # ====================================================================

        Test.@testset "Exports Verification" begin
            Test.@testset "Exported variable-dependence trait types" begin
                for sym in (:VariableDependence, :Fixed, :NonFixed)
                    Test.@test isdefined(Traits, sym)
                end
            end

            Test.@testset "Exported variable-dependence trait functions" begin
                for sym in (:has_variable_dependence_trait, :variable_dependence)
                    Test.@test isdefined(Traits, sym)
                end
            end
        end
    end
end

end # module

test_variable_dependence() = TestVariableDependence.test_variable_dependence()
