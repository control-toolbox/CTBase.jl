module TestDescribeRegistry

using Test: Test
using CTBase: Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Define all structs here
struct FakeGenericStrat{P<:Strategies.AbstractStrategyParameter} end
struct FakeConcreteStrat end

# Parametric-arity matrix (issue #516): strategies with 1, 2, 3 and 4 total type
# parameters, only the first of which is the strategy parameter. `describe(id, registry)`
# must work for all of them — 3+ used to throw `FieldError` because the private helpers
# assumed a `DataType` sat directly under a single `UnionAll` layer.
abstract type FakeArityFamily <: Strategies.AbstractStrategy end
struct FakeArityP1{P<:Strategies.AbstractStrategyParameter} <: FakeArityFamily end
struct FakeArityP2{P<:Strategies.AbstractStrategyParameter,O} <: FakeArityFamily end
struct FakeArityP3{P<:Strategies.AbstractStrategyParameter,O,Q} <: FakeArityFamily end
struct FakeArityP4{P<:Strategies.AbstractStrategyParameter,O,Q,R} <: FakeArityFamily end

Strategies.id(::Type{<:FakeArityP1}) = :arity_p1
Strategies.id(::Type{<:FakeArityP2}) = :arity_p2
Strategies.id(::Type{<:FakeArityP3}) = :arity_p3
Strategies.id(::Type{<:FakeArityP4}) = :arity_p4

Strategies.parameter(::Type{<:FakeArityP1{P}}) where {P} = P
Strategies.parameter(::Type{<:FakeArityP2{P}}) where {P} = P
Strategies.parameter(::Type{<:FakeArityP3{P}}) where {P} = P
Strategies.parameter(::Type{<:FakeArityP4{P}}) where {P} = P

Strategies.metadata(::Type{<:FakeArityP1}) = Strategies.StrategyMetadata()
Strategies.metadata(::Type{<:FakeArityP2}) = Strategies.StrategyMetadata()
Strategies.metadata(::Type{<:FakeArityP3}) = Strategies.StrategyMetadata()
Strategies.metadata(::Type{<:FakeArityP4}) = Strategies.StrategyMetadata()

function test_describe_registry()
    Test.@testset "Describe registry - private helpers" verbose = VERBOSE showtiming =
        SHOWTIMING begin

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

        # ====================================================================
        # REGRESSION - public describe(id, registry) across type-parameter arity
        # ====================================================================

        for (id_symbol, strat_type, label) in (
            (:arity_p1, FakeArityP1, "1 type parameter"),
            (:arity_p2, FakeArityP2, "2 type parameters"),
            (:arity_p3, FakeArityP3, "3 type parameters"),
            (:arity_p4, FakeArityP4, "4 type parameters"),
        )
            Test.@testset "describe(:$id_symbol, registry) - $label" begin
                r = Strategies.create_registry(
                    FakeArityFamily => ((strat_type, [Strategies.CPU, Strategies.GPU]),)
                )
                buf = IOBuffer()
                Test.@test_nowarn Strategies.describe(buf, id_symbol, r)
                output = String(take!(buf))
                Test.@test occursin(string(nameof(strat_type)), output)
            end
        end

        Test.@testset "describe(:cpu, registry) with a 3-param strategy present" begin
            # Blast-radius regression: the parameter branch walks every strategy in the
            # registry and previously hit the same UnionAll-depth bug via
            # `_strategy_type_name` when rendering "used by strategies".
            r = Strategies.create_registry(
                FakeArityFamily => ((FakeArityP3, [Strategies.CPU, Strategies.GPU]),)
            )
            buf = IOBuffer()
            Test.@test_nowarn Strategies.describe(buf, :cpu, r)
            output = String(take!(buf))
            Test.@test occursin("FakeArityP3", output)
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_describe_registry() = TestDescribeRegistry.test_describe_registry()
