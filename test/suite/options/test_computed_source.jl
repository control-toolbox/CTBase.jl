module TestOptionsComputedSource

using Test: Test
import CTBase.Exceptions
import CTBase.Options
import CTBase.Strategies

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# TOP-LEVEL: Define fake parameterized strategy for testing
struct FakeParameterizedStrategy{P} <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

# Implement required contract methods
Strategies.id(::Type{<:FakeParameterizedStrategy}) = :fake_param
Strategies.default_parameter(::Type{<:FakeParameterizedStrategy}) = Strategies.CPU
Strategies.parameter(::Type{<:FakeParameterizedStrategy{P}}) where {P} = P

# Define metadata with computed option
function Strategies.metadata(::Type{<:FakeParameterizedStrategy{P}}) where {P}
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(;
            name=:static_opt, type=Int, default=42, description="Static option"
        ),
        Strategies.OptionDefinition(;
            name=:computed_opt,
            type=Symbol,
            default=(P == Strategies.CPU ? :cpu_value : :gpu_value),
            description="Computed option",
            computed=true,
        ),
    )
end

# Constructor
function FakeParameterizedStrategy{P}(; mode::Symbol=:strict, kwargs...) where {P}
    opts = Strategies.build_strategy_options(
        FakeParameterizedStrategy{P}; mode=mode, kwargs...
    )
    return FakeParameterizedStrategy{P}(opts)
end

function test_computed_source()
    Test.@testset "Computed Source" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - OptionDefinition with computed field
        # ====================================================================

        Test.@testset "OptionDefinition - computed field" begin
            Test.@testset "Default behavior (computed=false)" begin
                def = Options.OptionDefinition(
                    name=:max_iter, type=Int, default=100, description="Maximum iterations"
                )
                Test.@test !Options.is_computed(def)
                Test.@test def.computed == false
            end

            Test.@testset "Explicit computed=true" begin
                def = Options.OptionDefinition(
                    name=:backend,
                    type=Any,
                    default=nothing,
                    description="Computed backend",
                    computed=true,
                )
                Test.@test Options.is_computed(def)
                Test.@test def.computed == true
            end

            Test.@testset "Explicit computed=false" begin
                def = Options.OptionDefinition(
                    name=:tol,
                    type=Float64,
                    default=1e-6,
                    description="Tolerance",
                    computed=false,
                )
                Test.@test !Options.is_computed(def)
                Test.@test def.computed == false
            end

            Test.@testset "Predicate is_computed(def)" begin
                static_def = Options.OptionDefinition(
                    name=:static_opt, type=Int, default=42, description="Static option"
                )
                computed_def = Options.OptionDefinition(
                    name=:computed_opt,
                    type=Int,
                    default=42,
                    description="Computed option",
                    computed=true,
                )

                Test.@test !Options.is_computed(static_def)
                Test.@test Options.is_computed(computed_def)
            end
        end

        # ====================================================================
        # UNIT TESTS - extract_option with computed defaults
        # ====================================================================

        Test.@testset "extract_option - computed source" begin
            Test.@testset "Computed default not overridden → :computed source" begin
                def = Options.OptionDefinition(
                    name=:backend,
                    type=Union{Nothing,Symbol},
                    default=:auto,
                    description="Backend",
                    computed=true,
                )

                kwargs = (other_opt=123,)
                opt_value, remaining = Options.extract_option(kwargs, def)

                Test.@test Options.value(opt_value) == :auto
                Test.@test Options.source(opt_value) == :computed
                Test.@test Options.is_computed(opt_value)
                Test.@test !Options.is_default(opt_value)
                Test.@test !Options.is_user(opt_value)
            end

            Test.@testset "Computed default overridden by user → :user source" begin
                def = Options.OptionDefinition(
                    name=:backend,
                    type=Union{Nothing,Symbol},
                    default=:auto,
                    description="Backend",
                    computed=true,
                )

                kwargs = (backend=:custom, other_opt=123)
                opt_value, remaining = Options.extract_option(kwargs, def)

                Test.@test Options.value(opt_value) == :custom
                Test.@test Options.source(opt_value) == :user
                Test.@test Options.is_user(opt_value)
                Test.@test !Options.is_computed(opt_value)
                Test.@test !Options.is_default(opt_value)
            end

            Test.@testset "Static default not overridden → :default source" begin
                def = Options.OptionDefinition(
                    name=:max_iter,
                    type=Int,
                    default=100,
                    description="Maximum iterations",
                    computed=false,
                )

                kwargs = (other_opt=123,)
                opt_value, remaining = Options.extract_option(kwargs, def)

                Test.@test Options.value(opt_value) == 100
                Test.@test Options.source(opt_value) == :default
                Test.@test Options.is_default(opt_value)
                Test.@test !Options.is_computed(opt_value)
                Test.@test !Options.is_user(opt_value)
            end

            Test.@testset "Static default overridden by user → :user source" begin
                def = Options.OptionDefinition(
                    name=:max_iter,
                    type=Int,
                    default=100,
                    description="Maximum iterations",
                    computed=false,
                )

                kwargs = (max_iter=200, other_opt=123)
                opt_value, remaining = Options.extract_option(kwargs, def)

                Test.@test Options.value(opt_value) == 200
                Test.@test Options.source(opt_value) == :user
                Test.@test Options.is_user(opt_value)
                Test.@test !Options.is_computed(opt_value)
                Test.@test !Options.is_default(opt_value)
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - Strategy with computed options
        # ====================================================================

        Test.@testset "Strategy with computed options" begin
            # Note: FakeParameterizedStrategy is defined at module top-level

            Test.@testset "CPU parameter - computed option has :computed source" begin
                strategy = FakeParameterizedStrategy{Strategies.CPU}()

                # Check static option has :default source
                Test.@test Strategies.option_value(strategy, :static_opt) == 42
                Test.@test Strategies.option_source(strategy, :static_opt) == :default

                # Check computed option has :computed source
                Test.@test Strategies.option_value(strategy, :computed_opt) == :cpu_value
                Test.@test Strategies.option_source(strategy, :computed_opt) == :computed
                Test.@test Strategies.option_is_computed(strategy, :computed_opt)
            end

            Test.@testset "GPU parameter - computed option has :computed source" begin
                strategy = FakeParameterizedStrategy{Strategies.GPU}()

                # Check static option has :default source
                Test.@test Strategies.option_value(strategy, :static_opt) == 42
                Test.@test Strategies.option_source(strategy, :static_opt) == :default

                # Check computed option has :computed source
                Test.@test Strategies.option_value(strategy, :computed_opt) == :gpu_value
                Test.@test Strategies.option_source(strategy, :computed_opt) == :computed
                Test.@test Strategies.option_is_computed(strategy, :computed_opt)
            end

            Test.@testset "User override changes to :user source" begin
                strategy = FakeParameterizedStrategy{Strategies.CPU}(computed_opt=:custom)

                # Check computed option overridden by user has :user source
                Test.@test Strategies.option_value(strategy, :computed_opt) == :custom
                Test.@test Strategies.option_source(strategy, :computed_opt) == :user
                Test.@test Strategies.option_is_user(strategy, :computed_opt)
                Test.@test !Strategies.option_is_computed(strategy, :computed_opt)
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_computed_source() = TestOptionsComputedSource.test_computed_source()
