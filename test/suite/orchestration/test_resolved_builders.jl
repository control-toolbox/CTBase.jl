module TestResolvedBuilders

using Test: Test
import CTBase.Exceptions
import CTBase.Orchestration
import CTBase.Strategies
import CTBase.Options

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

abstract type RBDiscretizer <: Strategies.AbstractStrategy end
abstract type RBModeler <: Strategies.AbstractStrategy end

struct RBDiscA <: RBDiscretizer
    options::Strategies.StrategyOptions
end

struct RBModA <: RBModeler
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{RBDiscA}) = :rb_disc_a
Strategies.id(::Type{RBModA}) = :rb_mod_a

function Strategies.metadata(::Type{RBDiscA})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:grid_size, type=Int, default=10, description="Grid size"
        ),
    )
end

function Strategies.metadata(::Type{RBModA})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:backend, type=Symbol, default=:dense, description="Backend"
        ),
    )
end

Strategies.options(s::Union{RBDiscA,RBModA}) = s.options

function RBDiscA(; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(RBDiscA; mode=mode, kwargs...)
    return RBDiscA(opts)
end

function RBModA(; mode::Symbol=:strict, kwargs...)
    opts = Strategies.build_strategy_options(RBModA; mode=mode, kwargs...)
    return RBModA(opts)
end

const RB_REGISTRY = Strategies.create_registry(
    RBDiscretizer => (RBDiscA,), RBModeler => (RBModA,)
)

const RB_FAMILIES = (discretizer=RBDiscretizer, modeler=RBModeler)

const RB_METHOD = (:rb_disc_a, :rb_mod_a)

function test_resolved_builders()
    Test.@testset "Orchestration resolved builders" verbose=VERBOSE showtiming=SHOWTIMING begin
        resolved = Orchestration.resolve_method(RB_METHOD, RB_FAMILIES, RB_REGISTRY)

        # ====================================================================
        # UNIT TESTS - option_names_from_resolved
        # ====================================================================

        Test.@testset "option_names_from_resolved" begin
            disc_opts = Orchestration.option_names_from_resolved(
                resolved, :discretizer, RB_FAMILIES, RB_REGISTRY
            )
            Test.@test disc_opts == (:grid_size,)

            mod_opts = Orchestration.option_names_from_resolved(
                resolved, :modeler, RB_FAMILIES, RB_REGISTRY
            )
            Test.@test :backend in mod_opts
            Test.@test length(mod_opts) == 1
        end

        # ====================================================================
        # UNIT TESTS - build_strategy_from_resolved
        # ====================================================================

        Test.@testset "build_strategy_from_resolved" begin
            disc = Orchestration.build_strategy_from_resolved(
                resolved, :discretizer, RB_FAMILIES, RB_REGISTRY
            )
            Test.@test disc isa RBDiscA
            Test.@test Strategies.option_value(disc, :grid_size) == 10

            mod = Orchestration.build_strategy_from_resolved(
                resolved, :modeler, RB_FAMILIES, RB_REGISTRY; backend=:sparse
            )
            Test.@test mod isa RBModA
            Test.@test Strategies.option_value(mod, :backend) == :sparse
        end

        # ====================================================================
        # UNIT TESTS - Error path: family_name mismatch
        # ====================================================================

        Test.@testset "build_strategy_from_resolved invalid family_name" begin
            Test.@test_throws Exception Orchestration.build_strategy_from_resolved(
                resolved, :nonexistent, RB_FAMILIES, RB_REGISTRY
            )
        end
    end
end

end # module

test_resolved_builders() = TestResolvedBuilders.test_resolved_builders()
