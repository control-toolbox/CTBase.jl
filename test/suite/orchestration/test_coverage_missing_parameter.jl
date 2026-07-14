module TestCoverageMissingParameter

using Test: Test
import CTBase.Exceptions
import CTBase.Orchestration
import CTBase.Strategies
import CTBase.Options

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# FAKE TYPES FOR TESTING (TOP-LEVEL)
# ============================================================================

abstract type FakeFamily <: Strategies.AbstractStrategy end

# Parameterized fake strategy
struct FakeParamStrategy{P<:Strategies.AbstractStrategyParameter} <: FakeFamily
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:FakeParamStrategy}) = :fake_param
function Strategies.parameter(
    ::Type{<:FakeParamStrategy{P}}
) where {P<:Strategies.AbstractStrategyParameter}
    return P
end

function Strategies.metadata(
    ::Type{<:FakeParamStrategy{P}}
) where {P<:Strategies.AbstractStrategyParameter}
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:test_opt, type=Int, default=42, description="Test option"
        ),
    )
end

Strategies.options(s::FakeParamStrategy) = s.options

function FakeParamStrategy{P}(;
    mode::Symbol=:strict, kwargs...
) where {P<:Strategies.AbstractStrategyParameter}
    opts = Strategies.build_strategy_options(FakeParamStrategy{P}; mode=mode, kwargs...)
    return FakeParamStrategy{P}(opts)
end

# ============================================================================
# TEST FUNCTION
# ============================================================================

"""
    test_coverage_missing_parameter()

🧪 **Applying Testing Rule**: Unit Tests for missing parameter error branches

Tests uncovered lines in Orchestration:
- builders.jl:47, 109, 117 - Missing parameter errors for parameterized strategies
"""
function test_coverage_missing_parameter()
    Test.@testset "Orchestration Missing Parameter Coverage" verbose=VERBOSE showtiming=SHOWTIMING begin

        # Create registry with parameterized strategy
        registry = Strategies.create_registry(
            FakeFamily => ((FakeParamStrategy, [Strategies.CPU, Strategies.GPU]),)
        )

        families = (fake=FakeFamily,)

        # ====================================================================
        # UNIT TESTS - option_names_from_resolved with missing parameter
        # ====================================================================

        Test.@testset "option_names_from_resolved - Missing Parameter Error" begin
            # Create a resolved method WITHOUT parameter (parameter=nothing)
            # but with a parameterized strategy
            method = (:fake_param,)

            # Manually construct ResolvedMethod with parameter=nothing
            # to trigger the error branch at builders.jl:47
            ids_by_family = (fake=:fake_param,)
            strategy_to_family = Dict(:fake_param => :fake)
            strategy_ids = (:fake_param,)
            parameter = nothing  # This will trigger the error

            resolved = Orchestration.ResolvedMethod(
                method, ids_by_family, strategy_to_family, strategy_ids, parameter
            )

            # This should throw IncorrectArgument because parameter is nothing
            # but the strategy is parameterized (covers builders.jl:47)
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.option_names_from_resolved(
                resolved, :fake, families, registry
            )
        end

        # ====================================================================
        # UNIT TESTS - build_strategy_from_resolved with missing parameter
        # ====================================================================

        Test.@testset "build_strategy_from_resolved - Missing Parameter Error" begin
            # Same setup as above
            method = (:fake_param,)
            ids_by_family = (fake=:fake_param,)
            strategy_to_family = Dict(:fake_param => :fake)
            strategy_ids = (:fake_param,)
            parameter = nothing

            resolved = Orchestration.ResolvedMethod(
                method, ids_by_family, strategy_to_family, strategy_ids, parameter
            )

            # This should throw IncorrectArgument at builders.jl:109 or 117
            Test.@test_throws Exceptions.IncorrectArgument Orchestration.build_strategy_from_resolved(
                resolved, :fake, families, registry
            )
        end

        # ====================================================================
        # UNIT TESTS - Successful cases with parameter provided
        # ====================================================================

        Test.@testset "Successful cases with parameter" begin
            # Create proper resolved method WITH parameter
            method = (:fake_param, :cpu)
            resolved = Orchestration.resolve_method(method, families, registry)

            # This should work fine
            Test.@test_nowarn Orchestration.option_names_from_resolved(
                resolved, :fake, families, registry
            )

            Test.@test_nowarn Orchestration.build_strategy_from_resolved(
                resolved, :fake, families, registry
            )
        end
    end
end

end # module

function test_coverage_missing_parameter()
    return TestCoverageMissingParameter.test_coverage_missing_parameter()
end
