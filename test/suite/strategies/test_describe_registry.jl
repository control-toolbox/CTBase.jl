module TestDescribeRegistry

using Test: Test
import CTBase.Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Define all structs here
struct FakeGenericStrat{P<:Strategies.AbstractStrategyParameter} end
struct FakeConcreteStrat end

function test_describe_registry()
    Test.@testset "Describe registry - private helpers" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - _strategy_type_name
        # ====================================================================

        Test.@testset "_strategy_type_name(::DataType) - no parameters" begin
            Test.@test Strategies._strategy_type_name(FakeConcreteStrat) ==
                "FakeConcreteStrat"
        end

        Test.@testset "_strategy_type_name(::DataType) - instantiated parameter" begin
            Test.@test Strategies._strategy_type_name(FakeGenericStrat{Strategies.CPU}) ==
                "FakeGenericStrat{CPU}"
        end

        Test.@testset "_strategy_type_name(::UnionAll) - uninstantiated generic type" begin
            # Regression test: `FakeGenericStrat` (bare, not applied to a concrete
            # parameter) is a `UnionAll`, not a `DataType`. Prior to the fix this
            # threw a `MethodError` from `nameof(::TypeVar)` (no such method exists) —
            # `TypeVar` exposes its name via the `.name` field, not `nameof`.
            Test.@test FakeGenericStrat isa UnionAll
            Test.@test Strategies._strategy_type_name(FakeGenericStrat) ==
                "FakeGenericStrat{P}"
        end

        Test.@testset "_strategy_type_name(::Type) - generic fallback" begin
            Test.@test Strategies._strategy_type_name(Union{Int,String}) ==
                string(Union{Int,String})
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_describe_registry() = TestDescribeRegistry.test_describe_registry()
