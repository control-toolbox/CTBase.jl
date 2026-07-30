module TestStrategiesAbstractStrategy

using Test: Test
using CTBase: Core
using CTBase: Exceptions
using CTBase: Strategies
using CTBase: Options

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

# ============================================================================
# Fake strategy types for testing (must be at module top-level)
# ============================================================================

struct FakeStrategy <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

struct IncompleteStrategy <: Strategies.AbstractStrategy
    # Missing options field - should trigger error path
end

# ============================================================================
# Implement required contract methods for FakeStrategy
# ============================================================================

Strategies.id(::Type{<:FakeStrategy}) = :fake
Strategies.id(::Type{<:IncompleteStrategy}) = :incomplete
Strategies.parameter(::Type{<:FakeStrategy}) = nothing
Strategies.parameter(::Type{<:IncompleteStrategy}) = nothing

function Strategies.metadata(::Type{<:FakeStrategy})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(;
            name=:max_iter,
            type=Int,
            default=100,
            description="Maximum iterations",
            aliases=(:max, :maxiter),
        ),
        Options.OptionDefinition(;
            name=:tol, type=Float64, default=1e-6, description="Tolerance"
        ),
    )
end

Strategies.metadata(::Type{<:IncompleteStrategy}) = Strategies.StrategyMetadata()

Strategies.options(strategy::FakeStrategy) = strategy.options

# Additional test struct for error handling
struct UnimplementedStrategy <: Strategies.AbstractStrategy end

# Parameterized fake, to prove a real value passes through the 2-arg parameter() unchanged.
struct FakeStrategyParam{P<:Strategies.AbstractStrategyParameter} <:
       Strategies.AbstractStrategy end
Strategies.parameter(::Type{<:FakeStrategyParam{P}}) where {P} = P

# Overrides parameter but throws something OTHER than NotImplemented — proves the 2-arg
# wrapper only swallows NotImplemented and rethrows everything else.
struct FakeStrategyBadParameter <: Strategies.AbstractStrategy end
function Strategies.parameter(::Type{<:FakeStrategyBadParameter})
    return throw(Exceptions.IncorrectArgument("deliberately not NotImplemented"))
end

# Fake strategy with description for testing multi-line display
struct FakeStrategyWithDescription <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:FakeStrategyWithDescription}) = :fake_described
Strategies.parameter(::Type{<:FakeStrategyWithDescription}) = nothing
function Strategies.metadata(::Type{<:FakeStrategyWithDescription})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(; name=:n, type=Int, default=10, description="Grid size.")
    )
end
Strategies.options(s::FakeStrategyWithDescription) = s.options
function Strategies.description(::Type{<:FakeStrategyWithDescription})
    return "A strategy for testing description display.\nSee: https://example.com"
end

# Fake parametric struct simulating a verbose algorithm type (e.g. an ODE solver
# algorithm from OrdinaryDiffEq), used to test `_display_value` shortening.
struct FakeParametricAlgorithm{A,B}
    a::A
    b::B
end

# ============================================================================
# Test function
# ============================================================================

"""
    test_abstract_strategy()

Tests for abstract strategy contract.
"""
function test_abstract_strategy()
    Test.@testset "Abstract Strategy" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ========================================================================
        # UNIT TESTS
        # ========================================================================

        Test.@testset "Unit Tests" begin
            Test.@testset "AbstractStrategy type" begin
                Test.@test FakeStrategy <: Strategies.AbstractStrategy
                Test.@test IncompleteStrategy <: Strategies.AbstractStrategy
            end

            Test.@testset "id() type-level" begin
                Test.@test Strategies.id(FakeStrategy) == :fake
                Test.@test Strategies.id(IncompleteStrategy) == :incomplete
            end

            Test.@testset "id() with typeof" begin
                fake_opts = Strategies.StrategyOptions(
                    max_iter=Options.OptionValue(200, :user)
                )
                fake_strategy = FakeStrategy(fake_opts)

                Test.@test Strategies.id(typeof(fake_strategy)) == :fake
                Test.@test Strategies.id(typeof(fake_strategy)) ==
                    Strategies.id(FakeStrategy)
            end

            Test.@testset "metadata function" begin
                fake_meta = Strategies.metadata(FakeStrategy)
                Test.@test fake_meta isa Strategies.StrategyMetadata
                Test.@test length(fake_meta) == 2
                Test.@test :max_iter in keys(fake_meta)
                Test.@test :tol in keys(fake_meta)

                incomplete_meta = Strategies.metadata(IncompleteStrategy)
                Test.@test incomplete_meta isa Strategies.StrategyMetadata
                Test.@test length(incomplete_meta) == 0
            end

            Test.@testset "options function" begin
                fake_opts = Strategies.StrategyOptions(
                    max_iter=Options.OptionValue(200, :user)
                )
                fake_strategy = FakeStrategy(fake_opts)

                retrieved_opts = Strategies.options(fake_strategy)
                Test.@test retrieved_opts === fake_opts
                Test.@test retrieved_opts[:max_iter] == 200
            end

            Test.@testset "Error handling" begin
                # Test NotImplemented errors for unimplemented methods
                Test.@test_throws Exceptions.NotImplemented Strategies.id(
                    UnimplementedStrategy
                )
                Test.@test_throws Exceptions.NotImplemented Strategies.metadata(
                    UnimplementedStrategy
                )

                # Test options error for strategy without options field
                incomplete_strategy = IncompleteStrategy()
                Test.@test_throws Exceptions.NotImplemented Strategies.options(
                    incomplete_strategy
                )
            end

            Test.@testset "parameter(T, default) - non-throwing accessor" begin
                # Falls back to default when parameter() is not implemented at all.
                Test.@test Strategies.parameter(UnimplementedStrategy, nothing) === nothing
                Test.@test Strategies.parameter(UnimplementedStrategy, :fallback) ===
                    :fallback

                # A strategy that legitimately returns nothing is NOT conflated with
                # "unimplemented": this just confirms the passthrough works when there is
                # no exception at all.
                Test.@test Strategies.parameter(FakeStrategy, :fallback) === nothing

                # A real parameter value passes through unchanged.
                Test.@test Strategies.parameter(
                    FakeStrategyParam{Strategies.CPU}, :fallback
                ) === Strategies.CPU

                # Non-NotImplemented errors still propagate — the wrapper is not a blanket
                # catch-all.
                Test.@test_throws Exceptions.IncorrectArgument Strategies.parameter(
                    FakeStrategyBadParameter, nothing
                )

                # 1-arg form is unchanged: still throws for a genuinely unimplemented strategy.
                Test.@test_throws Exceptions.NotImplemented Strategies.parameter(
                    UnimplementedStrategy
                )
            end

            Test.@testset "Collection interface - getindex" begin
                # Use build_strategy_options to properly initialize alias_map
                fake_opts = Strategies.build_strategy_options(
                    FakeStrategy; max_iter=200, tol=1e-8
                )
                fake_strategy = FakeStrategy(fake_opts)

                # Test getindex with canonical name
                Test.@test fake_strategy[:max_iter] == 200
                Test.@test fake_strategy[:tol] == 1e-8

                # Test getindex with alias (requires build_strategy_options for alias_map)
                Test.@test fake_strategy[:max] == 200
                Test.@test fake_strategy[:maxiter] == 200
            end

            Test.@testset "Collection interface - haskey" begin
                # Use build_strategy_options to properly initialize alias_map
                fake_opts = Strategies.build_strategy_options(
                    FakeStrategy; max_iter=200, tol=1e-8
                )
                fake_strategy = FakeStrategy(fake_opts)

                # Test haskey with canonical name
                Test.@test haskey(fake_strategy, :max_iter)
                Test.@test haskey(fake_strategy, :tol)

                # Test haskey with alias (requires build_strategy_options for alias_map)
                Test.@test haskey(fake_strategy, :max)
                Test.@test haskey(fake_strategy, :maxiter)

                # Test haskey with non-existent key
                Test.@test !haskey(fake_strategy, :nonexistent)
            end

            Test.@testset "Collection interface - keys" begin
                # Use build_strategy_options to properly initialize alias_map
                fake_opts = Strategies.build_strategy_options(
                    FakeStrategy; max_iter=200, tol=1e-8
                )
                fake_strategy = FakeStrategy(fake_opts)

                # Test keys returns all option names
                key_list = collect(keys(fake_strategy))
                Test.@test :max_iter in key_list
                Test.@test :tol in key_list
                Test.@test length(key_list) == 2
            end
        end

        # ========================================================================
        # UNIT TESTS - description contract
        # ========================================================================

        Test.@testset "description() contract" begin
            Test.@testset "default returns nothing" begin
                Test.@test Strategies.description(FakeStrategy) === nothing
                Test.@test Strategies.description(IncompleteStrategy) === nothing
                Test.@test Strategies.description(UnimplementedStrategy) === nothing
            end

            Test.@testset "concrete implementation returns String" begin
                desc = Strategies.description(FakeStrategyWithDescription)
                Test.@test desc isa String
                Test.@test occursin("testing description", desc)
                Test.@test occursin("https://example.com", desc)
                Test.@test occursin("\n", desc)
            end
        end

        Test.@testset "describe() with description" begin
            Test.@testset "no description — no strategy-level description line" begin
                io = IOBuffer()
                Strategies.describe(io, FakeStrategy)
                output = String(take!(io))
                Test.@test occursin("FakeStrategy", output)
                Test.@test occursin("id", output)
                Test.@test occursin("hierarchy", output)
                # Strategy-level description appears as "├─ description:" (not indented under options)
                lines = split(output, '\n')
                strategy_desc_lines = filter(l -> startswith(l, "├─ description:"), lines)
                Test.@test isempty(strategy_desc_lines)
            end

            Test.@testset "with description — description line shown" begin
                io = IOBuffer()
                Strategies.describe(io, FakeStrategyWithDescription)
                output = String(take!(io))
                Test.@test occursin("description:", output)
                Test.@test occursin("testing description", output)
            end

            Test.@testset "multi-line description — second line indented" begin
                io = IOBuffer()
                Strategies.describe(io, FakeStrategyWithDescription)
                output = String(take!(io))
                lines = split(output, '\n')
                desc_idx = findfirst(l -> occursin("description:", l), lines)
                Test.@test desc_idx !== nothing
                Test.@test occursin("https://example.com", output)
                # The URL line is a continuation: starts with the cont prefix "│"
                url_line = findfirst(l -> occursin("https://example.com", l), lines)
                Test.@test url_line !== nothing
                Test.@test startswith(lines[url_line], "│")
            end
        end

        Test.@testset "_print_labeled_multiline helper" begin
            Test.@testset "single-line text" begin
                io = IOBuffer()
                fmt = Core.get_format_codes(io)
                Strategies._print_labeled_multiline(
                    io, "├─ ", "│  ", fmt, "description: ", "Single line."
                )
                output = String(take!(io))
                # Label and text are present (possibly separated by ANSI fmt codes)
                Test.@test occursin("description: ", output)
                Test.@test occursin("Single line.", output)
                Test.@test length(split(output, '\n'; keepempty=false)) == 1
            end

            Test.@testset "multi-line text — continuation aligned" begin
                io = IOBuffer()
                fmt = Core.get_format_codes(io)
                Strategies._print_labeled_multiline(
                    io, "├─ ", "│  ", fmt, "description: ", "Line one.\nLine two."
                )
                output = String(take!(io))
                lines = split(output, '\n'; keepempty=false)
                Test.@test length(lines) == 2
                Test.@test occursin("Line one.", lines[1])
                Test.@test occursin("Line two.", lines[2])
                # Continuation line has padding (starts with cont prefix, not same as line 1)
                Test.@test !occursin("Line two.", lines[1])
                Test.@test startswith(lines[2], "│")
            end
        end

        Test.@testset "_display_value helper" begin
            Test.@testset "simple values are unaffected" begin
                Test.@test Strategies._display_value(200) == "200"
                Test.@test Strategies._display_value(1.0e-8) == "1.0e-8"
                Test.@test Strategies._display_value(:sparse) == "sparse"
                Test.@test Strategies._display_value("hello") == "hello"
                Test.@test Strategies._display_value(true) == "true"
                Test.@test Strategies._display_value(nothing) == "nothing"
            end

            Test.@testset "parametric struct is shortened to type name" begin
                value = FakeParametricAlgorithm(1, "x")
                Test.@test Strategies._display_value(value) == "FakeParametricAlgorithm"
                # The shortened form must not leak field values or type parameters
                Test.@test !occursin("\"x\"", Strategies._display_value(value))
                Test.@test !occursin("{", Strategies._display_value(value))
            end

            Test.@testset "standard containers are displayed in full" begin
                Test.@test Strategies._display_value([1, 2, 3]) == string([1, 2, 3])
                Test.@test Strategies._display_value((1, 2)) == string((1, 2))
                Test.@test Strategies._display_value((; a=1)) == string((; a=1))
                Test.@test Strategies._display_value(Dict(:a => 1)) == string(Dict(:a => 1))
            end
        end

        # ========================================================================
        # INTEGRATION TESTS
        # ========================================================================

        Test.@testset "Integration Tests" begin
            Test.@testset "Complete strategy workflow" begin
                # Create strategy with options
                opts = Strategies.StrategyOptions(
                    max_iter=Options.OptionValue(200, :user),
                    tol=Options.OptionValue(1e-8, :user),
                )
                strategy = FakeStrategy(opts)

                # Test complete contract
                Test.@test Strategies.id(typeof(strategy)) == :fake
                Test.@test Strategies.metadata(typeof(strategy)) isa
                    Strategies.StrategyMetadata
                Test.@test Strategies.options(strategy) === opts

                # Verify metadata contains expected options
                meta = Strategies.metadata(typeof(strategy))
                Test.@test :max_iter in keys(meta)
                Test.@test meta[:max_iter].type == Int
                Test.@test meta[:max_iter].default == 100
            end

            Test.@testset "Strategy with aliases" begin
                # Test that metadata correctly handles aliases
                meta = Strategies.metadata(FakeStrategy)
                max_iter_def = meta[:max_iter]

                Test.@test max_iter_def.aliases == (:max, :maxiter)
                Test.@test :max_iter in keys(meta)
                Test.@test :tol in keys(meta)
            end

            Test.@testset "Strategy display" begin
                opts = Strategies.StrategyOptions(
                    max_iter=Options.OptionValue(200, :user),
                    tol=Options.OptionValue(1e-8, :default),
                )
                strategy = FakeStrategy(opts)

                # Test that strategy components can be displayed
                redirect_stdout(devnull) do
                    Test.@test_nowarn show(stdout, Strategies.metadata(typeof(strategy)))
                    Test.@test_nowarn show(stdout, Strategies.options(strategy))
                end
            end

            Test.@testset "Strategy display shortens parametric struct option values" begin
                opts = Strategies.StrategyOptions(;
                    alg=Options.OptionValue(FakeParametricAlgorithm(1, "x"), :user)
                )
                strategy = FakeStrategy(opts)

                io = IOBuffer()
                show(io, MIME("text/plain"), strategy)
                verbose_output = String(take!(io))
                Test.@test occursin("FakeParametricAlgorithm", verbose_output)
                Test.@test !occursin("\"x\"", verbose_output)
                Test.@test !occursin("{", verbose_output)

                io = IOBuffer()
                show(io, strategy)
                compact_output = String(take!(io))
                Test.@test occursin("FakeParametricAlgorithm", compact_output)
                Test.@test !occursin("\"x\"", compact_output)
                Test.@test !occursin("{", compact_output)
            end
        end
    end
end

end # module

test_abstract_strategy() = TestStrategiesAbstractStrategy.test_abstract_strategy()
