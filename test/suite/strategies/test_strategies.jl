module TestStrategies

using Test: Test
import CTBase.Exceptions
using CTBase: CTBase
import CTBase.Strategies
import CTBase.Options
using CTBase.Strategies  # For testing exported symbols

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true
const CurrentModule = TestStrategies

"""
    test_strategies()

Tests for Strategies module exports.

This function tests the complete Strategies module exports including:
- Abstract types (AbstractStrategy, StrategyRegistry, StrategyMetadata, etc.)
- Parameter types (AbstractStrategyParameter, CPU, GPU)
- Utility types (RoutedOption, BypassValue, OptionDefinition)
- Contract functions (id, metadata, options)
- Registry functions (create_registry, strategy_ids, etc.)
- Introspection functions (option_names, option_type, etc.)
- Builder functions (build_strategy, extract_id_from_method, etc.)
- Configuration functions (build_strategy_options, resolve_alias)
- Utility functions (filter_options, suggest_options, etc.)
"""
function test_strategies()
    Test.@testset "Strategies Module" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # META TESTS - Exports / Public API surface
        # ====================================================================

        Test.@testset "Exports verification" begin
            # Test that Strategies module is available
            Test.@testset "Strategies Module" begin
                Test.@test isdefined(CTBase, :Strategies)
                Test.@test CTBase.Strategies isa Module
            end

            # Test exported abstract types
            Test.@testset "Exported Abstract Types" begin
                for T in (AbstractStrategy, StrategyRegistry, AbstractStrategyParameter)
                    Test.@testset "$(nameof(T))" begin
                        Test.@test isdefined(Strategies, nameof(T))
                        Test.@test isdefined(CurrentModule, nameof(T))
                        Test.@test T isa DataType || T isa UnionAll
                    end
                end
            end

            # Test exported concrete types
            Test.@testset "Exported Concrete Types" begin
                for T in (
                    StrategyMetadata,
                    StrategyOptions,
                    OptionDefinition,
                    RoutedOption,
                    BypassValue,
                    CPU,
                    GPU,
                )
                    Test.@testset "$(nameof(T))" begin
                        Test.@test isdefined(Strategies, nameof(T))
                        Test.@test isdefined(CurrentModule, nameof(T))
                        Test.@test T isa DataType || T isa UnionAll
                    end
                end
            end

            # Test exported contract functions
            Test.@testset "Exported Contract Functions" begin
                for f in (:id, :metadata, :options)
                    Test.@testset "$f" begin
                        Test.@test isdefined(Strategies, f)
                        Test.@test isdefined(CurrentModule, f)
                        Test.@test getfield(CurrentModule, f) isa Function
                    end
                end
            end

            # Test exported registry functions
            Test.@testset "Exported Registry Functions" begin
                for f in
                    (:create_registry, :strategy_ids, :type_from_id, :get_parameter_type)
                    Test.@testset "$f" begin
                        Test.@test isdefined(Strategies, f)
                        Test.@test isdefined(CurrentModule, f)
                        Test.@test getfield(CurrentModule, f) isa Function
                    end
                end
            end

            # Test exported introspection functions
            Test.@testset "Exported Introspection Functions" begin
                for f in (
                    :option_names,
                    :option_type,
                    :option_description,
                    :option_default,
                    :option_defaults,
                    :option_is_user,
                    :option_is_default,
                    :option_is_computed,
                    :option_value,
                    :option_source,
                    :has_option,
                )
                    Test.@testset "$f" begin
                        Test.@test isdefined(Strategies, f)
                        Test.@test isdefined(CurrentModule, f)
                        Test.@test getfield(CurrentModule, f) isa Function
                    end
                end
            end

            # Test exported builder functions
            Test.@testset "Exported Builder Functions" begin
                for f in (:build_strategy, :extract_id_from_method, :available_parameters)
                    Test.@testset "$f" begin
                        Test.@test isdefined(Strategies, f)
                        Test.@test isdefined(CurrentModule, f)
                        Test.@test getfield(CurrentModule, f) isa Function
                    end
                end
            end

            # Test exported configuration functions
            Test.@testset "Exported Configuration Functions" begin
                for f in (:build_strategy_options, :resolve_alias)
                    Test.@testset "$f" begin
                        Test.@test isdefined(Strategies, f)
                        Test.@test isdefined(CurrentModule, f)
                        Test.@test getfield(CurrentModule, f) isa Function
                    end
                end
            end

            # Test exported utility functions
            Test.@testset "Exported Utility Functions" begin
                for f in (
                    :describe,
                    :filter_options,
                    :suggest_options,
                    :format_suggestion,
                    :options_dict,
                    :route_to,
                    :bypass,
                    :force,
                )
                    Test.@testset "$f" begin
                        Test.@test isdefined(Strategies, f)
                        Test.@test isdefined(CurrentModule, f)
                        Test.@test getfield(CurrentModule, f) isa Function
                    end
                end
            end

            # Test that internal symbols are NOT exported
            Test.@testset "Internal Functions (not exported)" begin
                for f in (
                    :_strategy_id_set,              # Internal helper function
                    :_error_unknown_options_strict,  # Internal error functions
                    :_warn_unknown_options_permissive,
                    :_default_parameter,            # Internal contract function
                    :validate_parameter_type,        # Internal validation function
                )
                    Test.@testset "$f" begin
                        Test.@test isdefined(Strategies, f)
                        Test.@test !isdefined(CurrentModule, f)
                    end
                end
            end
        end

        # ====================================================================
        # UNIT TESTS - Type hierarchy and interface compliance
        # ====================================================================

        Test.@testset "Type hierarchy" begin
            Test.@testset "Abstract types" begin
                Test.@test Strategies.AbstractStrategy <: Any
                Test.@test Strategies.StrategyRegistry <: Any
                Test.@test Strategies.AbstractStrategyParameter <: Any
            end

            Test.@testset "Parameter types" begin
                Test.@test Strategies.CPU <: Strategies.AbstractStrategyParameter
                Test.@test Strategies.GPU <: Strategies.AbstractStrategyParameter
            end
        end

        Test.@testset "Display and introspection" begin
            Test.@testset "describe function" begin
                # Test that describe function exists and is callable
                Test.@test isdefined(Strategies, :describe)
                Test.@test getfield(Strategies, :describe) isa Function
            end
        end
    end
end

end # module

test_strategies() = TestStrategies.test_strategies()
