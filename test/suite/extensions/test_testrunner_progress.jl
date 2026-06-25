module TestTestRunnerProgress

using Test: Test
using CTBase: CTBase

const TestRunner = Base.get_extension(CTBase, :TestRunner)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_testrunner_progress()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Progress display" begin
        progress_bar = TestRunner._progress_bar
        bar_width = TestRunner._bar_width
        default_on_test_done = TestRunner._default_on_test_done

        Test.@testset "_bar_width adaptive" begin
            Test.@test bar_width(1) == 1
            Test.@test bar_width(10) == 10
            Test.@test bar_width(20) == 20
            Test.@test bar_width(21) == 21
            Test.@test bar_width(30) == 30
            Test.@test bar_width(50) == 50
            Test.@test bar_width(100) == 100
            Test.@test bar_width(101) == 100
            Test.@test bar_width(500) == 100
            Test.@test bar_width(1000) == 100
            Test.@test bar_width(0) == 0
        end

        Test.@testset "_bar_width with custom progress_bar_threshold" begin
            # Custom threshold of 30
            Test.@test bar_width(1, 30) == 1
            Test.@test bar_width(10, 30) == 10
            Test.@test bar_width(30, 30) == 30
            Test.@test bar_width(31, 30) == 30
            Test.@test bar_width(100, 30) == 30

            # Custom threshold of 100
            Test.@test bar_width(1, 100) == 1
            Test.@test bar_width(50, 100) == 50
            Test.@test bar_width(100, 100) == 100
            Test.@test bar_width(101, 100) == 100
            Test.@test bar_width(500, 100) == 100

            # Custom threshold of 10
            Test.@test bar_width(1, 10) == 1
            Test.@test bar_width(10, 10) == 10
            Test.@test bar_width(11, 10) == 10
            Test.@test bar_width(100, 10) == 10
        end

        Test.@testset "_progress_bar rendering" begin
            # Full bar (explicit width)
            bar = progress_bar(10, 10; width=10)
            Test.@test bar == "[██████████]"

            # Empty bar
            bar = progress_bar(0, 10; width=10)
            Test.@test bar == "[░░░░░░░░░░]"

            # Half bar
            bar = progress_bar(5, 10; width=10)
            Test.@test bar == "[█████░░░░░]"

            # Auto width: 2 tests → width=2
            bar = progress_bar(1, 2)
            Test.@test length(bar) == 4  # 2 chars + 2 brackets

            # Auto width: 50 tests → width=50
            bar = progress_bar(25, 50)
            Test.@test length(bar) == 52  # 50 chars + 2 brackets

            # Auto width: 100 tests → width=100
            bar = progress_bar(50, 100)
            Test.@test length(bar) == 102  # 100 chars + 2 brackets

            # Auto width: 500 tests → width=100
            bar = progress_bar(250, 500)
            Test.@test length(bar) == 102  # 100 chars + 2 brackets

            # Edge case: total=0
            bar = progress_bar(0, 0; width=10)
            Test.@test bar == "[░░░░░░░░░░]"
        end

        Test.@testset "_format_progress_line output" begin
            fmt = TestRunner._format_progress_line

            info = TestRunner.TestRunInfo(
                :my_test,
                "/tmp/test_my_test.jl",
                :test_my_test,
                3,
                10,
                :post_eval,
                nothing,
                1.234,
            )
            buf = IOBuffer()
            fmt(buf, info)
            output = String(take!(buf))
            Test.@test contains(output, "✓")
            Test.@test contains(output, "[03/10]")
            Test.@test contains(output, "my_test")
            Test.@test contains(output, "1.2s")
            Test.@test contains(output, "█")

            # Error status
            info_err = TestRunner.TestRunInfo(
                "suite/test_fail.jl",
                "/tmp/test_fail.jl",
                :test_fail,
                5,
                10,
                :error,
                ErrorException("boom"),
                0.5,
            )
            buf_err = IOBuffer()
            fmt(buf_err, info_err)
            output_err = String(take!(buf_err))
            Test.@test contains(output_err, "✗")
            Test.@test contains(output_err, "FAILED")
            Test.@test contains(output_err, "[05/10]")

            # test_failed status (from Test.@test failures)
            info_tf = TestRunner.TestRunInfo(
                :my_test,
                "/tmp/test_my_test.jl",
                :test_my_test,
                7,
                10,
                :test_failed,
                nothing,
                2.0,
            )
            buf_tf = IOBuffer()
            fmt(buf_tf, info_tf)
            output_tf = String(take!(buf_tf))
            Test.@test contains(output_tf, "✗")
            Test.@test contains(output_tf, "FAILED")

            # Skipped status
            info_skip = TestRunner.TestRunInfo(
                :skipped_test,
                "/tmp/test_skip.jl",
                :test_skip,
                1,
                5,
                :skipped,
                nothing,
                nothing,
            )
            buf_skip = IOBuffer()
            fmt(buf_skip, info_skip)
            output_skip = String(take!(buf_skip))
            Test.@test contains(output_skip, "○")
            Test.@test !contains(output_skip, "FAILED")

            # Fixed bar of 20 chars even for >400 tests (empty at start)
            info_large = TestRunner.TestRunInfo(
                :big_test, "/tmp/test_big.jl", :test_big, 1, 500, :post_eval, nothing, 0.1
            )
            buf_large = IOBuffer()
            fmt(buf_large, info_large)
            output_large = String(take!(buf_large))
            Test.@test contains(output_large, "✓")
            Test.@test contains(output_large, "░")

            # Test with some progress (25%)
            info_large_progress = TestRunner.TestRunInfo(
                :big_test, "/tmp/test_big.jl", :test_big, 125, 500, :post_eval, nothing, 0.1
            )
            buf_large_progress = IOBuffer()
            fmt(buf_large_progress, info_large_progress)
            output_large_progress = String(take!(buf_large_progress))
            Test.@test contains(output_large_progress, "✓")
            Test.@test contains(output_large_progress, "█")
            Test.@test contains(output_large_progress, "░")
        end

        Test.@testset "_format_progress_line cumulative coloring (full width)" begin
            fmt = TestRunner._format_progress_line
            history = [1, 1, 2, 3, 1]  # green, green, yellow, red, green
            info = TestRunner.TestRunInfo(
                :final, "/tmp/final.jl", :final, 5, 5, :post_eval, nothing, 0.5
            )
            buf = IOBuffer()
            # Use a color-enabled IOContext so ANSI codes are actually emitted
            io_c = IOContext(buf, :color => true)
            fmt(io_c, info; history=history, cumulative_severity=maximum(history))
            output = String(take!(buf))
            Test.@test contains(output, "[")
            Test.@test occursin("\e[31m[", output)  # brackets red because of failure
            Test.@test occursin("\e[33m┆", output)  # yellow block present (skip glyph)
        end

        Test.@testset "_format_progress_line compressed coloring" begin
            fmt = TestRunner._format_progress_line
            info = TestRunner.TestRunInfo(
                :compressed,
                "/tmp/compressed.jl",
                :compressed,
                10,
                50,
                :post_eval,
                nothing,
                0.2,
            )
            buf = IOBuffer()
            # Use a color-enabled IOContext so ANSI codes are actually emitted
            io_c = IOContext(buf, :color => true)
            fmt(io_c, info; cumulative_severity=2)
            output = String(take!(buf))
            Test.@test occursin("\e[33m[", output) ||
                occursin("\e[33m[", replace(output, "\e[0m"=>""))
        end

        Test.@testset "_format_progress_line show_progress_bar=false" begin
            fmt = TestRunner._format_progress_line
            info = TestRunner.TestRunInfo(
                :test_example,
                "/tmp/test.jl",
                :test_example,
                5,
                10,
                :post_eval,
                nothing,
                1.2,
            )
            buf = IOBuffer()
            fmt(buf, info; show_progress_bar=false)
            output = String(take!(buf))
            # Bar glyphs should not be present
            Test.@test !occursin("█", output)
            Test.@test !occursin("░", output)
            # No bar pattern like [█ or [░
            Test.@test !occursin("[█", output)
            Test.@test !occursin("[░", output)
            # Rest of line should be present
            Test.@test contains(output, "✓")
            Test.@test contains(output, "[05/10]")
            Test.@test contains(output, "test_example")
            Test.@test contains(output, "(1.2s)")
        end

        Test.@testset "palette IO-awareness — no ANSI in plain IO buffer" begin
            info = TestRunner.TestRunInfo(
                :test_example,
                "/tmp/test.jl",
                :test_example,
                5,
                10,
                :post_eval,
                nothing,
                1.23,
            )
            buf = IOBuffer()
            # Plain IOBuffer without :color => true must produce zero ANSI codes
            TestRunner._format_progress_line(buf, info; show_progress_bar=false)
            output = String(take!(buf))
            Test.@test !occursin("\e[", output) && !occursin("\033[", output)
        end
    end

    return nothing
end

end # module

test_testrunner_progress() = TestTestRunnerProgress.test_testrunner_progress()
