module TestParameterContractHelpers

using Test: Test
import CTBase.Exceptions
import CTBase.Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Define all structs here
struct FakeParamOk <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{FakeParamOk}) = :fake_param_ok

struct FakeParamWithField <: Strategies.AbstractStrategyParameter
    x::Int
end
Strategies.id(::Type{FakeParamWithField}) = :fake_param_with_field

function test_parameter_contract_helpers()
    Test.@testset "Strategy Parameter Contract Helpers" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Predicates and Aliases
        # ====================================================================

        Test.@testset "Predicates and aliases" begin
            Test.@test Strategies.is_a_parameter(Strategies.CPU)
            Test.@test Strategies.is_a_parameter(Strategies.GPU)
            Test.@test Strategies.is_a_parameter(FakeParamOk)
            Test.@test !Strategies.is_a_parameter(Int)

            Test.@test Strategies.parameter_id(Strategies.CPU) == :cpu
            Test.@test Strategies.parameter_id(Strategies.GPU) == :gpu
            Test.@test Strategies.parameter_id(FakeParamOk) == :fake_param_ok
        end

        # ====================================================================
        # UNIT TESTS - validate_parameter_type
        # ====================================================================

        Test.@testset "validate_parameter_type" begin
            Test.@test Strategies.validate_parameter_type(Strategies.CPU) === nothing
            Test.@test Strategies.validate_parameter_type(FakeParamOk) === nothing

            Test.@test_throws Exceptions.IncorrectArgument Strategies.validate_parameter_type(
                FakeParamWithField
            )
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
function test_parameter_contract_helpers()
    TestParameterContractHelpers.test_parameter_contract_helpers()
end
