module TestParametersCoverage

using Test: Test
import CTBase.Exceptions
import CTBase.Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Define all test types here (never inside test functions)
abstract type TestAbstractParam <: Strategies.AbstractStrategyParameter end

struct TestParamWithFields <: Strategies.AbstractStrategyParameter
    value::Int
end
Strategies.id(::Type{TestParamWithFields}) = :test_with_fields

struct TestValidParam <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{TestValidParam}) = :test_valid

struct TestParamNoId <: Strategies.AbstractStrategyParameter end

"""
    test_parameters_coverage()

🧪 **Applying Testing Rule**: Unit Tests for strategy parameters

Tests uncovered lines in parameters.jl:
- Line 149: validate_parameter_type with non-concrete type
- Lines 193-194: id() for CPU and GPU parameters
"""
function test_parameters_coverage()
    Test.@testset "Strategy Parameters Coverage" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - id() for Built-in Parameters
        # ====================================================================

        Test.@testset "id() for Built-in Parameters" begin
            # Test id() for CPU and GPU (covers parameters.jl:193-194)
            Test.@test Strategies.id(Strategies.CPU) === :cpu
            Test.@test Strategies.id(Strategies.GPU) === :gpu
        end

        # ====================================================================
        # UNIT TESTS - validate_parameter_type Error Cases
        # ====================================================================

        Test.@testset "validate_parameter_type - Non-Concrete Type" begin
            # Test validation with non-concrete type (covers parameters.jl:149)
            # TestAbstractParam is defined at module top-level

            # Should throw IncorrectArgument for abstract type
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_parameter_type(
                    TestAbstractParam
                )
            end

            # Verify error message content
            err = try
                Strategies.validate_parameter_type(TestAbstractParam)
            catch e
                e
            end
            Test.@test err isa Exceptions.IncorrectArgument
            Test.@test occursin("concrete", string(err))
        end

        Test.@testset "validate_parameter_type - Parameter with Fields" begin
            # Test validation with parameter that has fields
            # TestParamWithFields is defined at module top-level

            # Should throw IncorrectArgument for non-singleton type
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_parameter_type(
                    TestParamWithFields
                )
            end

            # Verify error message content
            err = try
                Strategies.validate_parameter_type(TestParamWithFields)
            catch e
                e
            end
            Test.@test err isa Exceptions.IncorrectArgument
            Test.@test occursin("singleton", string(err))
        end

        Test.@testset "validate_parameter_type - Valid Parameters" begin
            # Test validation with valid parameters

            # CPU and GPU should validate successfully
            Test.@test_nowarn Strategies.validate_parameter_type(Strategies.CPU)
            Test.@test_nowarn Strategies.validate_parameter_type(Strategies.GPU)

            # TestValidParam is defined at module top-level
            Test.@test_nowarn Strategies.validate_parameter_type(TestValidParam)
        end

        # ====================================================================
        # UNIT TESTS - parameter_id() Alias
        # ====================================================================

        Test.@testset "parameter_id() Alias" begin
            # Test parameter_id() as alias for id()
            Test.@test Strategies.parameter_id(Strategies.CPU) === :cpu
            Test.@test Strategies.parameter_id(Strategies.GPU) === :gpu

            # Should be identical to id()
            Test.@test Strategies.parameter_id(Strategies.CPU) ===
                Strategies.id(Strategies.CPU)
            Test.@test Strategies.parameter_id(Strategies.GPU) ===
                Strategies.id(Strategies.GPU)
        end

        # ====================================================================
        # UNIT TESTS - is_a_parameter() Predicate
        # ====================================================================

        Test.@testset "is_a_parameter() Predicate" begin
            # Test is_a_parameter() predicate
            Test.@test Strategies.is_a_parameter(Strategies.CPU) === true
            Test.@test Strategies.is_a_parameter(Strategies.GPU) === true
            Test.@test Strategies.is_a_parameter(Int) === false
            Test.@test Strategies.is_a_parameter(String) === false
            Test.@test Strategies.is_a_parameter(Strategies.AbstractStrategyParameter) ===
                true
        end

        # ====================================================================
        # UNIT TESTS - NotImplemented Error for id()
        # ====================================================================

        Test.@testset "id() NotImplemented Error" begin
            # Test that id() throws NotImplemented for types without implementation
            # TestParamNoId is defined at module top-level

            Test.@test_throws Exceptions.NotImplemented Strategies.id(TestParamNoId)

            # Verify error message content
            err = try
                Strategies.id(TestParamNoId)
            catch e
                e
            end
            Test.@test err isa Exceptions.NotImplemented
            Test.@test occursin("id()", string(err))
        end
    end
end

end # module

test_parameters_coverage() = TestParametersCoverage.test_parameters_coverage()
