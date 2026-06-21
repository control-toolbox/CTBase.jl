module TestParameters

using Test: Test
import CTBase.Exceptions
import CTBase.Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Define all structs here
struct BadParam <: Strategies.AbstractStrategyParameter end

function test_parameters()
    Test.@testset "AbstractStrategyParameter Contract" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Contract Implementation
        # ====================================================================

        Test.@testset "Built-in parameter IDs" begin
            Test.@test Strategies.id(Strategies.CPU) == :cpu
            Test.@test Strategies.id(Strategies.GPU) == :gpu
        end

        Test.@testset "NotImplemented for parameter without id()" begin
            Test.@test_throws Exceptions.NotImplemented Strategies.id(BadParam)
        end

        Test.@testset "Singleton types (no state)" begin
            Test.@test sizeof(Strategies.CPU) == 0
            Test.@test sizeof(Strategies.GPU) == 0
            Test.@test fieldcount(Strategies.CPU) == 0
            Test.@test fieldcount(Strategies.GPU) == 0
        end

        Test.@testset "Parameter inheritance" begin
            Test.@test Strategies.CPU <: Strategies.AbstractStrategyParameter
            Test.@test Strategies.GPU <: Strategies.AbstractStrategyParameter
            Test.@test Strategies.AbstractStrategyParameter isa Type
        end

        Test.@testset "Parameter type stability" begin
            Test.@test_nowarn Test.@inferred Strategies.id(Strategies.CPU)
            Test.@test_nowarn Test.@inferred Strategies.id(Strategies.GPU)
        end

        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================

        Test.@testset "Parameter uniqueness" begin
            # CPU and GPU should have different IDs
            Test.@test Strategies.id(Strategies.CPU) != Strategies.id(Strategies.GPU)
        end

        Test.@testset "Parameter in registry context" begin
            # Test that parameters can be used in registry creation
            # This will be tested more thoroughly in registry tests
            Test.@test Strategies.id(Strategies.CPU) isa Symbol
            Test.@test Strategies.id(Strategies.GPU) isa Symbol
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_parameters() = TestParameters.test_parameters()
