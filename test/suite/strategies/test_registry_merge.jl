module TestRegistryMerge

using Test: Test
import CTBase.Exceptions
import CTBase.Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Define all structs here

abstract type FakeMergeFamilyA <: Strategies.AbstractStrategy end
abstract type FakeMergeFamilyB <: Strategies.AbstractStrategy end

struct FakeMergeStratA <: FakeMergeFamilyA end
Strategies.id(::Type{<:FakeMergeStratA}) = :merge_a
Strategies.parameter(::Type{<:FakeMergeStratA}) = nothing
Strategies.metadata(::Type{<:FakeMergeStratA}) = Strategies.StrategyMetadata()

struct FakeMergeStratA2 <: FakeMergeFamilyA end
Strategies.id(::Type{<:FakeMergeStratA2}) = :merge_a2
Strategies.parameter(::Type{<:FakeMergeStratA2}) = nothing
Strategies.metadata(::Type{<:FakeMergeStratA2}) = Strategies.StrategyMetadata()

struct FakeMergeStratA3 <: FakeMergeFamilyA end
Strategies.id(::Type{<:FakeMergeStratA3}) = :merge_a3
Strategies.parameter(::Type{<:FakeMergeStratA3}) = nothing
Strategies.metadata(::Type{<:FakeMergeStratA3}) = Strategies.StrategyMetadata()

# Same id as FakeMergeStratA, same family, different registry — must be REJECTED, not
# silently unioned. Distinguishes "different strategies, shared family" (allowed, above)
# from "same strategy id, shared family, different registry" (a real collision).
struct FakeMergeStratA1Again <: FakeMergeFamilyA end
Strategies.id(::Type{<:FakeMergeStratA1Again}) = :merge_a
Strategies.parameter(::Type{<:FakeMergeStratA1Again}) = nothing
Strategies.metadata(::Type{<:FakeMergeStratA1Again}) = Strategies.StrategyMetadata()

struct FakeMergeStratB <: FakeMergeFamilyB end
Strategies.id(::Type{<:FakeMergeStratB}) = :merge_b
Strategies.parameter(::Type{<:FakeMergeStratB}) = nothing
Strategies.metadata(::Type{<:FakeMergeStratB}) = Strategies.StrategyMetadata()

# Same id as FakeMergeStratA, but a DIFFERENT family, different registry — global
# strategy-id collision case (the check is global, not per-family).
struct FakeMergeStratDup <: FakeMergeFamilyB end
Strategies.id(::Type{<:FakeMergeStratDup}) = :merge_a
Strategies.parameter(::Type{<:FakeMergeStratDup}) = nothing
Strategies.metadata(::Type{<:FakeMergeStratDup}) = Strategies.StrategyMetadata()

# Parameterized strategies for the family-union and parameter-agreement tests.
struct FakeMergeStratAParam{P<:Strategies.AbstractStrategyParameter} <: FakeMergeFamilyA end
Strategies.id(::Type{<:FakeMergeStratAParam}) = :merge_a_param
Strategies.parameter(::Type{<:FakeMergeStratAParam{P}}) where {P} = P
Strategies.metadata(::Type{<:FakeMergeStratAParam}) = Strategies.StrategyMetadata()

struct FakeMergeStratBParam{P<:Strategies.AbstractStrategyParameter} <: FakeMergeFamilyB end
Strategies.id(::Type{<:FakeMergeStratBParam}) = :merge_b_param
Strategies.parameter(::Type{<:FakeMergeStratBParam{P}}) where {P} = P
Strategies.metadata(::Type{<:FakeMergeStratBParam}) = Strategies.StrategyMetadata()

# Two fake parameter types sharing an id but distinct — for the "parameter bound to
# different types across registries" error case (mirrors FakeParam/FakeParam2 in
# test_registry_parameters.jl).
struct FakeMergeParam1 <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{FakeMergeParam1}) = :merge_param

struct FakeMergeParam2 <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{FakeMergeParam2}) = :merge_param

# For the strategy-id-vs-parameter-id cross-registry conflict case.
struct FakeMergeConflictStrat <: FakeMergeFamilyB end
Strategies.id(::Type{<:FakeMergeConflictStrat}) = :merge_conflict
Strategies.parameter(::Type{<:FakeMergeConflictStrat}) = nothing
Strategies.metadata(::Type{<:FakeMergeConflictStrat}) = Strategies.StrategyMetadata()

struct FakeMergeConflictParam <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{FakeMergeConflictParam}) = :merge_conflict

function test_registry_merge()
    Test.@testset "Registry merge" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # UNIT - merge mechanics on the families/parameters dicts directly
        # ====================================================================

        Test.@testset "disjoint families" begin
            r1 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA,))
            r2 = Strategies.create_registry(FakeMergeFamilyB => (FakeMergeStratB,))
            merged = merge(r1, r2)

            Test.@test haskey(merged.families, FakeMergeFamilyA)
            Test.@test haskey(merged.families, FakeMergeFamilyB)
            Test.@test length(merged.families) == 2
        end

        Test.@testset "family union - 2 registries, 2 distinct strategies" begin
            r1 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA,))
            r2 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA2,))
            merged = merge(r1, r2)

            # Exactly ONE FakeMergeFamilyA entry, not two separate ones.
            Test.@test length(merged.families) == 1
            Test.@test length(merged.families[FakeMergeFamilyA]) == 2

            ids = Strategies.strategy_ids(FakeMergeFamilyA, merged)
            Test.@test length(ids) == 2
            Test.@test :merge_a in ids
            Test.@test :merge_a2 in ids
        end

        Test.@testset "family union - 3 registries, 3 distinct strategies" begin
            r1 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA,))
            r2 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA2,))
            r3 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA3,))
            merged = merge(r1, r2, r3)

            ids = Strategies.strategy_ids(FakeMergeFamilyA, merged)
            Test.@test length(ids) == 3
            Test.@test :merge_a in ids
            Test.@test :merge_a2 in ids
            Test.@test :merge_a3 in ids
        end

        Test.@testset "identity case - single registry" begin
            r1 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA,))
            merged = merge(r1)

            Test.@test merged.families == r1.families
            Test.@test merged.parameters == r1.parameters
        end

        # ====================================================================
        # INTEGRATION - describe / show exercised through the merged registry
        # ====================================================================

        Test.@testset "describe works for every strategy in a unioned family" begin
            r1 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA,))
            r2 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA2,))
            merged = merge(r1, r2)

            buf_a = IOBuffer()
            Test.@test_nowarn Strategies.describe(buf_a, :merge_a, merged)
            Test.@test occursin("FakeMergeStratA", String(take!(buf_a)))

            buf_a2 = IOBuffer()
            Test.@test_nowarn Strategies.describe(buf_a2, :merge_a2, merged)
            Test.@test occursin("FakeMergeStratA2", String(take!(buf_a2)))
        end

        Test.@testset "show groups a unioned family under one header" begin
            r1 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA,))
            r2 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA2,))
            merged = merge(r1, r2)

            buf = IOBuffer()
            show(buf, MIME("text/plain"), merged)
            output = String(take!(buf))

            Test.@test occursin("merge_a", output)
            Test.@test occursin("merge_a2", output)
            Test.@test count("FakeMergeFamilyA", output) == 1
        end

        # ====================================================================
        # CONTRACT - parameterized strategies and parameter id/type agreement
        # ====================================================================

        Test.@testset "family union with a parameterized strategy" begin
            r1 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA,))
            r2 = Strategies.create_registry(
                FakeMergeFamilyA =>
                    ((FakeMergeStratAParam, [Strategies.CPU, Strategies.GPU]),),
            )
            merged = merge(r1, r2)

            ids = Strategies.strategy_ids(FakeMergeFamilyA, merged)
            Test.@test :merge_a in ids
            Test.@test :merge_a_param in ids

            buf = IOBuffer()
            Test.@test_nowarn Strategies.describe(buf, :merge_a_param, merged)
            output = String(take!(buf))
            Test.@test occursin("CPU", output)
            Test.@test occursin("GPU", output)

            buf_param = IOBuffer()
            Test.@test_nowarn Strategies.describe(buf_param, :cpu, merged)
        end

        Test.@testset "parameter id/type agreement across registries" begin
            r1 = Strategies.create_registry(
                FakeMergeFamilyA =>
                    ((FakeMergeStratAParam, [Strategies.CPU, Strategies.GPU]),),
            )
            r2 = Strategies.create_registry(
                FakeMergeFamilyB =>
                    ((FakeMergeStratBParam, [Strategies.CPU, Strategies.GPU]),),
            )
            merged = merge(r1, r2)

            Test.@test merged.parameters[:cpu] == Strategies.CPU
            Test.@test merged.parameters[:gpu] == Strategies.GPU
        end

        # ====================================================================
        # ERROR - every validation failure mode
        # ====================================================================

        Test.@testset "same id, same family, across registries -> rejected" begin
            r1 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA,))
            r2 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA1Again,))

            Test.@test_throws Exceptions.IncorrectArgument merge(r1, r2)
        end

        Test.@testset "duplicate strategy id across different families" begin
            r1 = Strategies.create_registry(FakeMergeFamilyA => (FakeMergeStratA,))
            r2 = Strategies.create_registry(FakeMergeFamilyB => (FakeMergeStratDup,))

            Test.@test_throws Exceptions.IncorrectArgument merge(r1, r2)
        end

        Test.@testset "parameter id bound to different types across registries" begin
            r1 = Strategies.create_registry(
                FakeMergeFamilyA => ((FakeMergeStratAParam, [FakeMergeParam1]),)
            )
            r2 = Strategies.create_registry(
                FakeMergeFamilyB => ((FakeMergeStratBParam, [FakeMergeParam2]),)
            )

            Test.@test_throws Exceptions.IncorrectArgument merge(r1, r2)
        end

        Test.@testset "strategy id vs parameter id cross-registry conflict" begin
            r1 = Strategies.create_registry(FakeMergeFamilyB => (FakeMergeConflictStrat,))
            r2 = Strategies.create_registry(
                FakeMergeFamilyA => ((FakeMergeStratAParam, [FakeMergeConflictParam]),)
            )

            Test.@test_throws Exceptions.IncorrectArgument merge(r1, r2)
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_registry_merge() = TestRegistryMerge.test_registry_merge()
