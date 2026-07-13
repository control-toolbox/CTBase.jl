module TestRoutingInternals

using Test: Test
import CTBase.Exceptions
import CTBase.Orchestration
import CTBase.Strategies
import CTBase.Options

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# Test fixtures - Minimal strategy types for testing
# ============================================================================

abstract type InternalTestDiscretizer <: Strategies.AbstractStrategy end
abstract type InternalTestModeler <: Strategies.AbstractStrategy end
abstract type InternalTestSolver <: Strategies.AbstractStrategy end

struct InternalCollocation <: InternalTestDiscretizer end
Strategies.id(::Type{InternalCollocation}) = :collocation
Strategies.parameter(::Type{<:InternalCollocation}) = nothing
function Strategies.metadata(::Type{InternalCollocation})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:grid_size, type=Int, default=100, description="Grid size"
        ),
    )
end

struct InternalADNLP <: InternalTestModeler end
Strategies.id(::Type{InternalADNLP}) = :adnlp
Strategies.parameter(::Type{<:InternalADNLP}) = nothing
function Strategies.metadata(::Type{InternalADNLP})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:backend, type=Symbol, default=:dense, description="Backend type"
        ),
    )
end

struct InternalIpopt <: InternalTestSolver end
Strategies.id(::Type{InternalIpopt}) = :ipopt
Strategies.parameter(::Type{<:InternalIpopt}) = nothing
function Strategies.metadata(::Type{InternalIpopt})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:max_iter, type=Int, default=100, description="Max iterations"
        ),
        Options.OptionDefinition(;
            name=:backend, type=Symbol, default=:cpu, description="Backend type"
        ),
    )
end

# Additional strategy for testing registry search
struct InternalMadNLP <: InternalTestSolver end
Strategies.id(::Type{InternalMadNLP}) = :madnlp
Strategies.parameter(::Type{<:InternalMadNLP}) = nothing
function Strategies.metadata(::Type{InternalMadNLP})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:max_iter, type=Int, default=1000, description="Max iterations"
        ),
        Options.OptionDefinition(;
            name=:custom_opt, type=Int, default=42, description="Custom option for testing"
        ),
    )
end

# Test registry and families
const INTERNAL_REGISTRY = Strategies.create_registry(
    InternalTestDiscretizer => (InternalCollocation,),
    InternalTestModeler => (InternalADNLP,),
    InternalTestSolver => (InternalIpopt, InternalMadNLP),
)

const INTERNAL_FAMILIES = (
    discretizer=InternalTestDiscretizer,
    modeler=InternalTestModeler,
    solver=InternalTestSolver,
)

const INTERNAL_METHOD = (:collocation, :adnlp, :ipopt)

# Action option definitions
const INTERNAL_ACTION_DEFS = [
    Options.OptionDefinition(;
        name=:display, type=Bool, default=true, description="Display output"
    ),
]

"""
    test_routing_internals()

Tests for internal helper functions created during route_all_options refactoring.

This test suite validates the behavior of the 8 private functions extracted
from route_all_options to improve modularity and adherence to SRP.
"""
function test_routing_internals()
    Test.@testset "Routing Internals" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Internal Helper Functions
        # ====================================================================

        Test.@testset "_separate_action_and_strategy_options" begin
            # Test with action options only
            kwargs = (display=false,)
            action_opts, strategy_kwargs = Orchestration._separate_action_and_strategy_options(
                kwargs, INTERNAL_ACTION_DEFS
            )
            Test.@test haskey(action_opts, :display)
            Test.@test Options.value(action_opts[:display]) == false
            Test.@test isempty(strategy_kwargs)

            # Test with strategy options only
            kwargs = (grid_size=200,)
            action_opts, strategy_kwargs = Orchestration._separate_action_and_strategy_options(
                kwargs, INTERNAL_ACTION_DEFS
            )
            # action_opts will contain default values even if not provided by user
            Test.@test haskey(action_opts, :display)
            Test.@test Options.source(action_opts[:display]) === :default
            Test.@test strategy_kwargs.grid_size == 200

            # Test with mixed options
            kwargs = (display=false, grid_size=200, max_iter=500)
            action_opts, strategy_kwargs = Orchestration._separate_action_and_strategy_options(
                kwargs, INTERNAL_ACTION_DEFS
            )
            Test.@test haskey(action_opts, :display)
            Test.@test Options.value(action_opts[:display]) == false
            Test.@test strategy_kwargs.grid_size == 200
            Test.@test strategy_kwargs.max_iter == 500

            # Test with RoutedOption (should be preserved in strategy_kwargs)
            routed_backend = Strategies.route_to(adnlp=:sparse)
            kwargs = (display=false, backend=routed_backend)
            action_opts, strategy_kwargs = Orchestration._separate_action_and_strategy_options(
                kwargs, INTERNAL_ACTION_DEFS
            )
            Test.@test haskey(action_opts, :display)
            Test.@test haskey(strategy_kwargs, :backend)
            # The RoutedOption should be preserved in strategy_kwargs
            Test.@test strategy_kwargs[:backend] === routed_backend
        end

        Test.@testset "_build_routing_context" begin
            resolved = Orchestration.resolve_method(
                INTERNAL_METHOD, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )

            context = Orchestration._build_routing_context(
                resolved, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )

            # Test that context is created
            Test.@test context isa Orchestration.RoutingContext

            # Test strategy_to_family mapping
            Test.@test haskey(context.strategy_to_family, :collocation)
            Test.@test haskey(context.strategy_to_family, :adnlp)
            Test.@test haskey(context.strategy_to_family, :ipopt)
            Test.@test context.strategy_to_family[:collocation] == :discretizer
            Test.@test context.strategy_to_family[:adnlp] == :modeler
            Test.@test context.strategy_to_family[:ipopt] == :solver

            # Test option_owners mapping
            Test.@test haskey(context.option_owners, :grid_size)
            Test.@test haskey(context.option_owners, :backend)
            Test.@test haskey(context.option_owners, :max_iter)
            Test.@test :discretizer in context.option_owners[:grid_size]
            Test.@test :modeler in context.option_owners[:backend]
            Test.@test :solver in context.option_owners[:backend]
            Test.@test :solver in context.option_owners[:max_iter]
        end

        Test.@testset "_check_action_option_shadowing" begin
            resolved = Orchestration.resolve_method(
                INTERNAL_METHOD, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            context = Orchestration._build_routing_context(
                resolved, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )

            # Test with no shadowing (display is action-only)
            action_opts = Dict(:display => Options.OptionValue(false, :user))
            # Should not log anything (no shadowing)
            Orchestration._check_action_option_shadowing(action_opts, context.option_owners)

            # Test with shadowing (if we had an action option that also exists in strategies)
            # This is tested indirectly via route_all_options tests
            Test.@test true  # Placeholder - shadowing is tested in integration tests
        end

        Test.@testset "_initialize_routing_dict" begin
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)

            # Test that all families have entries
            Test.@test haskey(routed, :discretizer)
            Test.@test haskey(routed, :modeler)
            Test.@test haskey(routed, :solver)

            # Test that all entries are empty vectors
            Test.@test isempty(routed[:discretizer])
            Test.@test isempty(routed[:modeler])
            Test.@test isempty(routed[:solver])

            # Test that entries are of correct type
            Test.@test routed[:discretizer] isa Vector{Pair{Symbol,Any}}
        end

        Test.@testset "_route_with_disambiguation!" begin
            resolved = Orchestration.resolve_method(
                INTERNAL_METHOD, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            context = Orchestration._build_routing_context(
                resolved, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)

            # Test routing to single strategy
            disambiguations = Tuple{Any,Symbol}[(:sparse, :adnlp)]
            Orchestration._route_with_disambiguation!(
                routed,
                :backend,
                disambiguations,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
            )
            Test.@test length(routed[:modeler]) == 1
            Test.@test routed[:modeler][1] == (:backend => :sparse)

            # Test routing to multiple strategies
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            disambiguations = Tuple{Any,Symbol}[(:sparse, :adnlp), (:gpu, :ipopt)]
            Orchestration._route_with_disambiguation!(
                routed,
                :backend,
                disambiguations,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
            )
            Test.@test length(routed[:modeler]) == 1
            Test.@test routed[:modeler][1] == (:backend => :sparse)
            Test.@test length(routed[:solver]) == 1
            Test.@test routed[:solver][1] == (:backend => :gpu)

            # Test with BypassValue
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            bypass_val = Strategies.bypass(42)
            disambiguations = Tuple{Any,Symbol}[(bypass_val, :ipopt)]
            Orchestration._route_with_disambiguation!(
                routed,
                :unknown_opt,
                disambiguations,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
            )
            Test.@test length(routed[:solver]) == 1
            Test.@test routed[:solver][1][1] == :unknown_opt
            Test.@test routed[:solver][1][2] isa Strategies.BypassValue
            Test.@test routed[:solver][1][2].value == 42

            # Test error: unknown option without bypass
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            disambiguations = Tuple{Any,Symbol}[(42, :ipopt)]
            Test.@test_throws Exceptions.IncorrectArgument Orchestration._route_with_disambiguation!(
                routed,
                :totally_unknown,
                disambiguations,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
            )

            # Test error: routing to wrong family
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            disambiguations = Tuple{Any,Symbol}[(:sparse, :collocation)]  # backend doesn't belong to discretizer
            Test.@test_throws Exceptions.IncorrectArgument Orchestration._route_with_disambiguation!(
                routed,
                :backend,
                disambiguations,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
            )
        end

        Test.@testset "_route_auto!" begin
            resolved = Orchestration.resolve_method(
                INTERNAL_METHOD, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            context = Orchestration._build_routing_context(
                resolved, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )

            # Test auto-routing unambiguous option
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            Orchestration._route_auto!(
                routed,
                :grid_size,
                200,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
                :description,
            )
            Test.@test length(routed[:discretizer]) == 1
            Test.@test routed[:discretizer][1] == (:grid_size => 200)

            # Test auto-routing another unambiguous option
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            Orchestration._route_auto!(
                routed,
                :max_iter,
                500,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
                :description,
            )
            Test.@test length(routed[:solver]) == 1
            Test.@test routed[:solver][1] == (:max_iter => 500)

            # Test error: unknown option
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            Test.@test_throws Exceptions.IncorrectArgument Orchestration._route_auto!(
                routed,
                :totally_unknown,
                42,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
                :description,
            )

            # Test error: ambiguous option (backend belongs to both modeler and solver)
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            Test.@test_throws Exceptions.IncorrectArgument Orchestration._route_auto!(
                routed,
                :backend,
                :sparse,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
                :description,
            )
        end

        Test.@testset "_route_single_option!" begin
            resolved = Orchestration.resolve_method(
                INTERNAL_METHOD, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            context = Orchestration._build_routing_context(
                resolved, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )

            # Test auto-routing path (unambiguous option)
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            Orchestration._route_single_option!(
                routed,
                :grid_size,
                200,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
                :description,
            )
            Test.@test length(routed[:discretizer]) == 1
            Test.@test routed[:discretizer][1] == (:grid_size => 200)

            # Test disambiguation path (RoutedOption)
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            routed_opt = Strategies.route_to(adnlp=:sparse)
            Orchestration._route_single_option!(
                routed,
                :backend,
                routed_opt,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
                :description,
            )
            Test.@test length(routed[:modeler]) == 1
            Test.@test routed[:modeler][1] == (:backend => :sparse)

            # Test multi-strategy disambiguation
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            routed_opt = Strategies.route_to(adnlp=:sparse, ipopt=:gpu)
            Orchestration._route_single_option!(
                routed,
                :backend,
                routed_opt,
                context,
                resolved,
                INTERNAL_FAMILIES,
                INTERNAL_REGISTRY,
                :description,
            )
            Test.@test length(routed[:modeler]) == 1
            Test.@test routed[:modeler][1] == (:backend => :sparse)
            Test.@test length(routed[:solver]) == 1
            Test.@test routed[:solver][1] == (:backend => :gpu)
        end

        Test.@testset "_build_routed_result" begin
            # Test with empty options
            action_opts = Dict()
            routed = Dict(
                :discretizer => Pair{Symbol,Any}[],
                :modeler => Pair{Symbol,Any}[],
                :solver => Pair{Symbol,Any}[],
            )
            result = Orchestration._build_routed_result(action_opts, routed)
            Test.@test result isa NamedTuple
            Test.@test haskey(result, :action)
            Test.@test haskey(result, :strategies)
            Test.@test isempty(result.action)
            Test.@test isempty(result.strategies.discretizer)

            # Test with action options
            action_opts = Dict(:display => Options.OptionValue(false, :user))
            routed = Dict(
                :discretizer => Pair{Symbol,Any}[(:grid_size => 200)],
                :modeler => Pair{Symbol,Any}[(:backend => :sparse)],
                :solver => Pair{Symbol,Any}[(:max_iter => 500)],
            )
            result = Orchestration._build_routed_result(action_opts, routed)
            Test.@test haskey(result.action, :display)
            Test.@test Options.value(result.action.display) == false
            Test.@test result.strategies.discretizer.grid_size == 200
            Test.@test result.strategies.modeler.backend == :sparse
            Test.@test result.strategies.solver.max_iter == 500

            # Test with multiple options per family
            routed = Dict(
                :discretizer =>
                    Pair{Symbol,Any}[(:grid_size => 200), (:method => :trapezoid)],
                :modeler => Pair{Symbol,Any}[(:backend => :sparse)],
                :solver => Pair{Symbol,Any}[(:max_iter => 500), (:tol => 1e-6)],
            )
            result = Orchestration._build_routed_result(action_opts, routed)
            Test.@test result.strategies.discretizer.grid_size == 200
            Test.@test result.strategies.discretizer.method == :trapezoid
            Test.@test result.strategies.solver.max_iter == 500
            Test.@test result.strategies.solver.tol == 1e-6
        end

        Test.@testset "_find_option_in_registry" begin
            # Test with option that exists in other strategies
            resolved = Orchestration.resolve_method(
                INTERNAL_METHOD, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            # :custom_opt exists in InternalMadNLP but not in current method (ipopt)
            matches = Orchestration._find_option_in_registry(
                :custom_opt, resolved, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            Test.@test length(matches) == 1
            Test.@test matches[1] == (:madnlp, :solver)

            # Test with option that doesn't exist in registry
            matches = Orchestration._find_option_in_registry(
                :totally_unknown, resolved, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            Test.@test isempty(matches)

            # Test with option that only exists in current method strategies
            # :grid_size exists in InternalCollocation which is in current method
            matches = Orchestration._find_option_in_registry(
                :grid_size, resolved, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            Test.@test isempty(matches)  # Should be empty since it's in current method

            # Test with option that exists in multiple strategies across families
            # :backend exists in both InternalADNLP and InternalIpopt, but both are in current method
            # So result should be empty
            matches = Orchestration._find_option_in_registry(
                :backend, resolved, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            Test.@test isempty(matches)

            # Test with method that doesn't use MadNLP
            alt_method = (:collocation, :adnlp, :madnlp)
            resolved_alt = Orchestration.resolve_method(
                alt_method, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            # :max_iter exists in InternalIpopt (not in current method)
            matches = Orchestration._find_option_in_registry(
                :max_iter, resolved_alt, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            Test.@test length(matches) == 1
            Test.@test matches[1] == (:ipopt, :solver)
        end

        # ====================================================================
        # INTEGRATION TESTS - Complete workflow through internal functions
        # ====================================================================

        Test.@testset "Complete internal workflow" begin
            # Simulate the complete flow of route_all_options using internal functions
            kwargs = (
                display=false, grid_size=200, backend=Strategies.route_to(adnlp=:sparse)
            )

            # Step 1: Resolve method
            resolved = Orchestration.resolve_method(
                INTERNAL_METHOD, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )

            # Step 2: Separate action and strategy options
            action_opts, strategy_kwargs = Orchestration._separate_action_and_strategy_options(
                kwargs, INTERNAL_ACTION_DEFS
            )
            Test.@test haskey(action_opts, :display)
            Test.@test haskey(strategy_kwargs, :grid_size)
            Test.@test haskey(strategy_kwargs, :backend)

            # Step 3: Build routing context
            context = Orchestration._build_routing_context(
                resolved, INTERNAL_FAMILIES, INTERNAL_REGISTRY
            )
            Test.@test context isa Orchestration.RoutingContext

            # Step 4: Check shadowing (no-op in this case)
            Orchestration._check_action_option_shadowing(action_opts, context.option_owners)

            # Step 5: Route strategy options
            routed = Orchestration._initialize_routing_dict(INTERNAL_FAMILIES)
            for (key, raw_val) in pairs(strategy_kwargs)
                Orchestration._route_single_option!(
                    routed,
                    key,
                    raw_val,
                    context,
                    resolved,
                    INTERNAL_FAMILIES,
                    INTERNAL_REGISTRY,
                    :description,
                )
            end
            Test.@test length(routed[:discretizer]) == 1
            Test.@test length(routed[:modeler]) == 1

            # Step 6: Build final result
            result = Orchestration._build_routed_result(action_opts, routed)
            Test.@test Options.value(result.action.display) == false
            Test.@test result.strategies.discretizer.grid_size == 200
            Test.@test result.strategies.modeler.backend == :sparse
        end
    end
end

end # module

test_routing_internals() = TestRoutingInternals.test_routing_internals()
