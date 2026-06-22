module TestOrchestration

using Test: Test
import CTBase.Exceptions
using CTBase: CTBase
import CTBase.Orchestration
import CTBase.Strategies
import CTBase.Options
using CTBase.Orchestration  # For testing exported symbols

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true
const CurrentModule = TestOrchestration

"""
    test_orchestration()

Tests for Orchestration module exports.

This function tests the complete Orchestration module exports including:
- Abstract types (ResolvedMethod)
- Exported functions (routing, resolution, building functions)
- Internal functions (NOT exported)
"""
function test_orchestration()
    Test.@testset "Orchestration Module" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # META TESTS - Exports / Public API surface
        # ====================================================================

        Test.@testset "Exports verification" begin
            # Test that Orchestration module is available
            Test.@testset "Orchestration Module" begin
                Test.@test isdefined(CTBase, :Orchestration)
                Test.@test CTBase.Orchestration isa Module
            end

            # Test exported types
            Test.@testset "Exported Types" begin
                for T in (ResolvedMethod,)
                    Test.@testset "$(nameof(T))" begin
                        Test.@test isdefined(Orchestration, nameof(T))
                        Test.@test isdefined(CurrentModule, nameof(T))
                        Test.@test T isa DataType || T isa UnionAll
                    end
                end
            end

            # Test exported functions
            Test.@testset "Exported Functions" begin
                for f in (
                    :route_all_options,
                    :resolve_method,
                    :extract_strategy_ids,
                    :build_strategy_to_family_map,
                    :build_option_ownership_map,
                    :build_strategy_from_resolved,
                    :option_names_from_resolved,
                )
                    Test.@testset "$f" begin
                        Test.@test isdefined(Orchestration, f)
                        Test.@test isdefined(CurrentModule, f)
                        Test.@test getfield(CurrentModule, f) isa Function
                    end
                end
            end

            # Test that internal symbols are NOT exported
            Test.@testset "Internal Types (not exported)" begin
                for T in (:RoutingContext,)
                    Test.@testset "$T" begin
                        Test.@test isdefined(Orchestration, T)
                        Test.@test !isdefined(CurrentModule, T)
                    end
                end
            end

            Test.@testset "Internal Functions (not exported)" begin
                for f in (
                    :build_alias_to_primary_map,  # Internal helper function
                    :_error_unknown_option,      # Internal error functions
                    :_collect_suggestions_across_strategies,
                    :_error_ambiguous_option,
                    :_warn_unknown_option_permissive,
                    # New internal functions from route_all_options refactoring
                    :_separate_action_and_strategy_options,
                    :_build_routing_context,
                    :_check_action_option_shadowing,
                    :_initialize_routing_dict,
                    :_route_single_option!,
                    :_route_with_disambiguation!,
                    :_route_auto!,
                    :_build_routed_result,
                )
                    Test.@testset "$f" begin
                        Test.@test isdefined(Orchestration, f)
                        Test.@test !isdefined(CurrentModule, f)
                    end
                end
            end
        end
    end
end

end # module

test_orchestration() = TestOrchestration.test_orchestration()
