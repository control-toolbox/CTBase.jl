module TestStrategiesAbstractStrategy

using Test: Test
import CTBase.Core
import CTBase.Exceptions
import CTBase.Strategies
import CTBase.Options

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

function Strategies.metadata(::Type{<:FakeStrategy})
    Strategies.StrategyMetadata(
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

# Fake strategy with description for testing multi-line display
struct FakeStrategyWithDescription <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:FakeStrategyWithDescription}) = :fake_described
function Strategies.metadata(::Type{<:FakeStrategyWithDescription})
    Strategies.StrategyMetadata(
        Options.OptionDefinition(; name=:n, type=Int, default=10, description="Grid size.")
    )
end
Strategies.options(s::FakeStrategyWithDescription) = s.options
function Strategies.description(::Type{<:FakeStrategyWithDescription})
    "A strategy for testing description display.\nSee: https://example.com"
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

            Test.@testset "Collection interface - getindex" begin
                # Use build_strategy_options to properly initialize alias_map
                fake_opts = Strategies.build_strategy_options(FakeStrategy; max_iter=200, tol=1e-8)
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
                fake_opts = Strategies.build_strategy_options(FakeStrategy; max_iter=200, tol=1e-8)
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
                fake_opts = Strategies.build_strategy_options(FakeStrategy; max_iter=200, tol=1e-8)
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
        end
    end
end

end # module

test_abstract_strategy() = TestStrategiesAbstractStrategy.test_abstract_strategy()
