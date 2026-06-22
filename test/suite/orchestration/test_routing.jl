module TestOrchestrationRouting

using Test: Test
import CTBase.Exceptions
using CTBase: CTBase
import CTBase.Orchestration
import CTBase.Strategies
import CTBase.Options

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true
const CurrentModule = TestOrchestrationRouting

# ============================================================================
# Test fixtures
# ============================================================================

abstract type RoutingTestDiscretizer <: Strategies.AbstractStrategy end
abstract type RoutingTestModeler <: Strategies.AbstractStrategy end
abstract type RoutingTestSolver <: Strategies.AbstractStrategy end

struct RoutingCollocation <: RoutingTestDiscretizer end
Strategies.id(::Type{RoutingCollocation}) = :collocation
function Strategies.metadata(::Type{RoutingCollocation})
    Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:grid_size, type=Int, default=100, description="Grid size"
        ),
    )
end

struct RoutingADNLP <: RoutingTestModeler end
Strategies.id(::Type{RoutingADNLP}) = :adnlp
function Strategies.metadata(::Type{RoutingADNLP})
    Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:backend,
            type=Symbol,
            default=:dense,
            description="Backend type",
            aliases=(:adnlp_backend,),
        ),
    )
end

struct RoutingIpopt <: RoutingTestSolver end
Strategies.id(::Type{RoutingIpopt}) = :ipopt
function Strategies.metadata(::Type{RoutingIpopt})
    Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:max_iter, type=Int, default=1000, description="Maximum iterations"
        ),
        Options.OptionDefinition(;
            name=:backend,
            type=Symbol,
            default=:cpu,
            description="Solver backend",
            aliases=(:ipopt_backend,),
        ),
    )
end

struct ShadowingSolver <: RoutingTestSolver end
Strategies.id(::Type{ShadowingSolver}) = :shadow_solver
function Strategies.metadata(::Type{ShadowingSolver})
    Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:display, type=Bool, default=false, description="Solver display"
        ),
    )
end

const ROUTING_REGISTRY = Strategies.create_registry(
    RoutingTestDiscretizer => (RoutingCollocation,),
    RoutingTestModeler => (RoutingADNLP,),
    RoutingTestSolver => (RoutingIpopt,),
)

const ROUTING_METHOD = (:collocation, :adnlp, :ipopt)

const ROUTING_FAMILIES = (
    discretizer=RoutingTestDiscretizer, modeler=RoutingTestModeler, solver=RoutingTestSolver
)

const ROUTING_ACTION_DEFS = [
    Options.OptionDefinition(;
        name=:display, type=Bool, default=true, description="Display progress"
    ),
    Options.OptionDefinition(;
        name=:initial_guess, type=Any, default=nothing, description="Initial guess"
    ),
]

# ============================================================================
# Test function
# ============================================================================

function test_routing()
    Test.@testset "Orchestration Routing" verbose = VERBOSE showtiming = SHOWTIMING begin
        resolved = Orchestration.resolve_method(
            ROUTING_METHOD, ROUTING_FAMILIES, ROUTING_REGISTRY
        )

        # ====================================================================
        # META TESTS - Exports / Public API surface
        # ====================================================================

        Test.@testset "Type stability smoke tests" begin
            Test.@test_nowarn Orchestration.resolve_method(
                ROUTING_METHOD, ROUTING_FAMILIES, ROUTING_REGISTRY
            )
            Test.@test_nowarn Orchestration.extract_strategy_ids(:plain_value, resolved)
        end

        # ====================================================================
        # Action Option Shadowing Detection
        # ====================================================================

        Test.@testset "Action Option Shadowing Detection" begin
            # Use the custom registry/families where solver also has :display option

            shadow_registry = Strategies.create_registry(
                RoutingTestDiscretizer => (RoutingCollocation,),
                RoutingTestModeler => (RoutingADNLP,),
                RoutingTestSolver => (ShadowingSolver,),
            )
            shadow_method = (:collocation, :adnlp, :shadow_solver)

            # 1. When user provides the shadowed option
            kwargs = (display=false,)

            # We expect an @info message explaining the shadowing
            Test.@test_logs (
                :info, r"Option `display` was intercepted.*available for.*solver"
            ) begin
                routed = Orchestration.route_all_options(
                    shadow_method,
                    ROUTING_FAMILIES,
                    ROUTING_ACTION_DEFS,
                    kwargs,
                    shadow_registry,
                )
                Test.@test Options.value(routed.action[:display]) == false
                Test.@test Options.source(routed.action[:display]) === :user
            end

            # 2. When option is not provided by user (default is used), NO warning
            kwargs_empty = NamedTuple()
            routed_empty = Orchestration.route_all_options(
                shadow_method,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs_empty,
                shadow_registry,
            )
            Test.@test Options.value(routed_empty.action[:display]) == true # default
            Test.@test Options.source(routed_empty.action[:display]) === :default

            # 3. When user explicitly routes the shadowed option to the strategy via route_to
            kwargs_routed = (display=Strategies.route_to(shadow_solver=false),)
            routed_explicit = Orchestration.route_all_options(
                shadow_method,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs_routed,
                shadow_registry,
            )

            # The action should get the default value (true) since route_to bypasses action extraction
            Test.@test Options.value(routed_explicit.action[:display]) == true
            Test.@test Options.source(routed_explicit.action[:display]) === :default

            # The strategy should get the explicitly routed value (false)
            Test.@test haskey(routed_explicit.strategies.solver, :display)
            Test.@test routed_explicit.strategies.solver[:display] == false
        end

        # ====================================================================
        # Auto-routing (unambiguous options)
        # ====================================================================

        Test.@testset "Auto-routing unambiguous options" begin
            kwargs = (grid_size=200, max_iter=2000, display=false)

            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY,
            )

            # Check action options (Dict of OptionValue wrappers)
            Test.@test haskey(routed.action, :display)
            Test.@test Options.value(routed.action[:display]) === false
            Test.@test Options.source(routed.action[:display]) === :user

            # Check strategy options (raw NamedTuples)
            Test.@test haskey(routed.strategies, :discretizer)
            Test.@test haskey(routed.strategies, :modeler)
            Test.@test haskey(routed.strategies, :solver)

            # Access raw values from NamedTuples
            Test.@test haskey(routed.strategies.discretizer, :grid_size)
            Test.@test routed.strategies.discretizer[:grid_size] == 200
            Test.@test haskey(routed.strategies.solver, :max_iter)
            Test.@test routed.strategies.solver[:max_iter] == 2000
        end

        # ====================================================================
        # Single strategy disambiguation
        # ====================================================================

        Test.@testset "Single strategy disambiguation" begin
            kwargs = (backend=Strategies.route_to(adnlp=:sparse), display=true)

            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY,
            )

            # backend should be routed to modeler only
            Test.@test haskey(routed.strategies.modeler, :backend)
            Test.@test routed.strategies.modeler[:backend] === :sparse
            Test.@test !haskey(routed.strategies.solver, :backend)
        end

        # ====================================================================
        # Multi-strategy disambiguation
        # ====================================================================

        Test.@testset "Multi-strategy disambiguation" begin
            kwargs = (backend=Strategies.route_to(adnlp=:sparse, ipopt=:cpu),)

            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY,
            )

            # backend should be routed to both
            Test.@test haskey(routed.strategies.modeler, :backend)
            Test.@test routed.strategies.modeler[:backend] === :sparse
            Test.@test haskey(routed.strategies.solver, :backend)
            Test.@test routed.strategies.solver[:backend] === :cpu
        end

        # ====================================================================
        # Error: Unknown option
        # ====================================================================

        Test.@testset "Error on unknown option" begin
            kwargs = (unknown_option=123,)

            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY,
            )
        end

        # ====================================================================
        # Error: Ambiguous option without disambiguation
        # ====================================================================

        Test.@testset "Error on ambiguous option" begin
            kwargs = (backend=:sparse,)  # No disambiguation

            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY,
            )
        end

        # ====================================================================
        # Error: Invalid disambiguation target
        # ====================================================================

        Test.@testset "Error on invalid disambiguation" begin
            # Try to route max_iter to modeler (wrong family)
            kwargs = (max_iter=Strategies.route_to(adnlp=1000),)

            Test.@test_throws Exceptions.IncorrectArgument Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY,
            )
        end

        # ====================================================================
        # Routing via aliases (unambiguous)
        # ====================================================================

        Test.@testset "Auto-routing via alias (unambiguous)" begin
            # adnlp_backend is an alias for backend, only in modeler => unambiguous
            kwargs = (adnlp_backend=:sparse,)

            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY,
            )

            # adnlp_backend should be routed to modeler
            Test.@test haskey(routed.strategies.modeler, :adnlp_backend)
            Test.@test routed.strategies.modeler[:adnlp_backend] === :sparse
            # solver should NOT have it
            Test.@test !haskey(routed.strategies.solver, :adnlp_backend)
        end

        Test.@testset "Auto-routing via solver alias (unambiguous)" begin
            # ipopt_backend is an alias for backend, only in solver => unambiguous
            kwargs = (ipopt_backend=:gpu,)

            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY,
            )

            # ipopt_backend should be routed to solver
            Test.@test haskey(routed.strategies.solver, :ipopt_backend)
            Test.@test routed.strategies.solver[:ipopt_backend] === :gpu
            # modeler should NOT have it
            Test.@test !haskey(routed.strategies.modeler, :ipopt_backend)
        end

        Test.@testset "Mixed alias and primary routing" begin
            # Use alias for one strategy and primary for another
            kwargs = (adnlp_backend=:sparse, max_iter=500, grid_size=200)

            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY,
            )

            Test.@test routed.strategies.modeler[:adnlp_backend] === :sparse
            Test.@test routed.strategies.solver[:max_iter] == 500
            Test.@test routed.strategies.discretizer[:grid_size] == 200
        end

        Test.@testset "Ownership map includes aliases" begin
            map = Orchestration.build_option_ownership_map(
                resolved, ROUTING_FAMILIES, ROUTING_REGISTRY
            )

            # Primary names
            Test.@test haskey(map, :backend)
            Test.@test length(map[:backend]) == 2  # modeler + solver
            Test.@test haskey(map, :max_iter)
            Test.@test length(map[:max_iter]) == 1  # solver only

            # Aliases should be in the map too
            Test.@test haskey(map, :adnlp_backend)
            Test.@test length(map[:adnlp_backend]) == 1  # modeler only
            Test.@test :modeler in map[:adnlp_backend]

            Test.@test haskey(map, :ipopt_backend)
            Test.@test length(map[:ipopt_backend]) == 1  # solver only
            Test.@test :solver in map[:ipopt_backend]
        end

        # ====================================================================
        # Integration: Mixed routing
        # ====================================================================

        Test.@testset "Integration: Mixed routing" begin
            kwargs = (
                grid_size=150,
                backend=Strategies.route_to(adnlp=:sparse, ipopt=:gpu),
                max_iter=500,
                display=false,
                initial_guess=:warm,
            )

            routed = Orchestration.route_all_options(
                ROUTING_METHOD,
                ROUTING_FAMILIES,
                ROUTING_ACTION_DEFS,
                kwargs,
                ROUTING_REGISTRY,
            )

            # Action options (Dict of OptionValue wrappers)
            Test.@test Options.value(routed.action[:display]) === false
            Test.@test Options.value(routed.action[:initial_guess]) === :warm

            # Strategy options (raw NamedTuples)
            Test.@test routed.strategies.discretizer[:grid_size] == 150
            Test.@test routed.strategies.modeler[:backend] === :sparse
            Test.@test routed.strategies.solver[:backend] === :gpu
            Test.@test routed.strategies.solver[:max_iter] == 500
        end
        # ====================================================================
        # Unknown option error suggests closest options (alias-aware)
        # ====================================================================

        Test.@testset "Unknown option error suggests closest (alias-aware)" begin
            # adnlp_backen is close to alias adnlp_backend (distance 1)
            # but far from primary name backend (distance 7)
            # The error should suggest :backend (alias: adnlp_backend)
            try
                Orchestration.route_all_options(
                    ROUTING_METHOD,
                    ROUTING_FAMILIES,
                    ROUTING_ACTION_DEFS,
                    (; adnlp_backen=:sparse),
                    ROUTING_REGISTRY,
                )
                Test.@test false  # Should not reach here
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                msg = sprint(showerror, e)
                # Should suggest backend via alias proximity
                Test.@test occursin("Did you mean?", msg)
                Test.@test occursin("backend", msg)
                Test.@test occursin("adnlp_backend", msg)
            end

            # ipopt_backen is close to alias ipopt_backend (distance 1)
            try
                Orchestration.route_all_options(
                    ROUTING_METHOD,
                    ROUTING_FAMILIES,
                    ROUTING_ACTION_DEFS,
                    (; ipopt_backen=:gpu),
                    ROUTING_REGISTRY,
                )
                Test.@test false
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                msg = sprint(showerror, e)
                Test.@test occursin("Did you mean?", msg)
                Test.@test occursin("backend", msg)
                Test.@test occursin("ipopt_backend", msg)
            end

            # max_ite is close to primary max_iter (distance 1), no alias needed
            try
                Orchestration.route_all_options(
                    ROUTING_METHOD,
                    ROUTING_FAMILIES,
                    ROUTING_ACTION_DEFS,
                    (; max_ite=500),
                    ROUTING_REGISTRY,
                )
                Test.@test false
            catch e
                Test.@test e isa Exceptions.IncorrectArgument
                msg = sprint(showerror, e)
                Test.@test occursin("Did you mean?", msg)
                Test.@test occursin("max_iter", msg)
            end
        end
    end
end

end # module

test_routing() = TestOrchestrationRouting.test_routing()
