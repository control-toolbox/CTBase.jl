module TestRegistryParameters

using Test: Test
import CTBase.Exceptions
import CTBase.Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Define all structs here
abstract type FakeFamily <: Strategies.AbstractStrategy end
struct FakeStratA <: FakeFamily end
struct FakeStratB{P<:Strategies.AbstractStrategyParameter} <: FakeFamily end

# Implement contracts
Strategies.id(::Type{<:FakeStratA}) = :fakestrata
Strategies.id(::Type{<:FakeStratB}) = :fakestratb
Strategies.parameter(::Type{<:FakeStratA}) = nothing
Strategies.parameter(::Type{<:FakeStratB{P}}) where {P<:Strategies.AbstractStrategyParameter} = P

# Fake parameter for testing
struct FakeParam <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{FakeParam}) = :fakeparam

# Additional test structs (must be at top level)
struct FakeStratWithIdCpu <: FakeFamily end
Strategies.id(::Type{<:FakeStratWithIdCpu}) = :cpu
Strategies.parameter(::Type{<:FakeStratWithIdCpu}) = nothing

struct FakeParam2 <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{FakeParam2}) = :fakeparam

struct FakeStratC <: FakeFamily end
Strategies.id(::Type{<:FakeStratC}) = :fakestrata  # Same as FakeStratA
Strategies.parameter(::Type{<:FakeStratC}) = nothing

function test_registry_parameters()
    Test.@testset "Registry with Parameters" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - create_registry with parameterized strategies
        # ====================================================================

        Test.@testset "create_registry parameterized" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA, (FakeStratB, [Strategies.CPU, Strategies.GPU]))
            )

            # Check that the registry contains the correct types
            types = r.families[FakeFamily]
            Test.@test FakeStratA in types
            Test.@test FakeStratB{Strategies.CPU} in types
            Test.@test FakeStratB{Strategies.GPU} in types
            Test.@test length(types) == 3
        end

        Test.@testset "create_registry with multiple parameterized strategies" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA, (FakeStratB, [Strategies.CPU, Strategies.GPU]))
            )

            types = r.families[FakeFamily]
            Test.@test FakeStratA in types
            Test.@test FakeStratB{Strategies.CPU} in types
            Test.@test FakeStratB{Strategies.GPU} in types
            Test.@test length(types) == 3
        end

        Test.@testset "create_registry validation - invalid strategy type" begin
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((String, [Strategies.CPU]),),  # String is not a strategy
            )
        end

        Test.@testset "create_registry validation - invalid parameter type" begin
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((FakeStratB, [String]),),  # String is not a parameter
            )
        end

        Test.@testset "create_registry validation - invalid parameter format" begin
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((FakeStratB, "not a tuple"),),  # Not a tuple/vector
            )
        end

        # ====================================================================
        # UNIT TESTS - Global ID uniqueness
        # ====================================================================

        Test.@testset "Global ID uniqueness - strategy vs parameter" begin
            # :cpu cannot be both a strategy ID and a parameter ID
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => (FakeStratWithIdCpu, (FakeStratB, [Strategies.CPU]))
            )
        end

        Test.@testset "Global ID uniqueness - parameter vs parameter" begin
            # :fakeparam cannot be used by two different parameter types
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => ((FakeStratB, [FakeParam, FakeParam2]),)
            )
        end

        Test.@testset "Global ID uniqueness - strategy vs strategy" begin
            # Same ID for two different strategies should fail
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                FakeFamily => (FakeStratA, FakeStratC)
            )
        end

        # ====================================================================
        # UNIT TESTS - strategy_ids deduplication
        # ====================================================================

        Test.@testset "strategy_ids deduplication" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA, (FakeStratB, [Strategies.CPU, Strategies.GPU]))
            )
            ids = Strategies.strategy_ids(FakeFamily, r)
            Test.@test length(ids) == length(unique(ids))  # No duplicates
            Test.@test :fakestrata in ids
            Test.@test :fakestratb in ids
            Test.@test length(ids) == 2  # Only 2 unique IDs despite 3 types
        end

        Test.@testset "strategy_ids with only parameterized strategies" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratB, [Strategies.CPU, Strategies.GPU]),)
            )
            ids = Strategies.strategy_ids(FakeFamily, r)
            Test.@test length(ids) == 1  # :fakestratb
            Test.@test :fakestratb in ids
        end

        # ====================================================================
        # UNIT TESTS - parameter
        # ====================================================================

        Test.@testset "parameter" begin
            Test.@test Strategies.parameter(FakeStratB{Strategies.CPU}) == Strategies.CPU
            Test.@test Strategies.parameter(FakeStratB{Strategies.GPU}) == Strategies.GPU
            Test.@test Strategies.parameter(FakeStratA) === nothing
        end

        Test.@testset "parameter type stability" begin
            Test.@test_nowarn Test.@inferred Strategies.parameter(
                FakeStratB{Strategies.CPU}
            )
            Test.@test_nowarn Test.@inferred Strategies.parameter(FakeStratA)
        end

        # ====================================================================
        # UNIT TESTS - type_from_id with parameter
        # ====================================================================

        Test.@testset "type_from_id with parameter" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratB, [Strategies.CPU, Strategies.GPU]),)
            )

            T_cpu = Strategies.type_from_id(
                :fakestratb, FakeFamily, r; parameter=Strategies.CPU
            )
            T_gpu = Strategies.type_from_id(
                :fakestratb, FakeFamily, r; parameter=Strategies.GPU
            )

            Test.@test T_cpu == FakeStratB{Strategies.CPU}
            Test.@test T_gpu == FakeStratB{Strategies.GPU}
        end

        Test.@testset "type_from_id without parameter" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratB, [Strategies.CPU, Strategies.GPU]),)
            )

            # Should return the first match (implementation-dependent but should work)
            T = Strategies.type_from_id(:fakestratb, FakeFamily, r)
            Test.@test T in (FakeStratB{Strategies.CPU}, FakeStratB{Strategies.GPU})
        end

        Test.@testset "type_from_id parameter not found" begin
            r = Strategies.create_registry(
                FakeFamily => ((FakeStratB, [Strategies.CPU]),),  # Only CPU
            )

            Test.@test_throws Exceptions.IncorrectArgument Strategies.type_from_id(
                :fakestratb, FakeFamily, r; parameter=Strategies.GPU
            )
        end

        Test.@testset "type_from_id strategy not found" begin
            r = Strategies.create_registry(FakeFamily => (FakeStratA,))

            Test.@test_throws Exceptions.IncorrectArgument Strategies.type_from_id(
                :nonexistent, FakeFamily, r
            )
        end

        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================

        Test.@testset "Registry display with parameterized strategies" begin
            r = Strategies.create_registry(
                FakeFamily => (FakeStratA, (FakeStratB, [Strategies.CPU, Strategies.GPU]))
            )

            # Test that display works without errors
            io = IOBuffer()
            show(io, r)
            output = String(take!(io))
            Test.@test occursin("StrategyRegistry", output)

            io = IOBuffer()
            show(io, MIME"text/plain"(), r)
            output = String(take!(io))
            Test.@test occursin("FakeFamily", output)
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_registry_parameters() = TestRegistryParameters.test_registry_parameters()
