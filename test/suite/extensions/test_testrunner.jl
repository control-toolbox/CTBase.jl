module TestTestRunner

import Test
import CTBase
import CTBase.Extensions
import CTBase.Exceptions

const TestRunner = Base.get_extension(CTBase, :TestRunner)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

struct DummyTestRunnerTag <: Extensions.AbstractTestRunnerTag end

function test_testrunner()
    # ============================================================================
    # UNIT TESTS - TestRunner extension
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "TestRunner extension" begin
        Test.@test Base.get_extension(CTBase, :TestRunner) !== nothing
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "TestRunner stub dispatch" begin
        err = try
            Extensions.run_tests(DummyTestRunnerTag())
            nothing
        catch e
            e
        end

        Test.@test err isa Exceptions.ExtensionError
        Test.@test err.weakdeps == (:Test,)
    end

    # ============================================================================
    # UNIT TESTS - _parse_test_args
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_parse_test_args" begin
        # Access the private function via the loaded extension module
        parse_args = TestRunner._parse_test_args

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "empty args with defaults" begin
            (sel, all_flag, dry_flag) = parse_args(String[])
            Test.@test sel == String[]
            Test.@test all_flag == false

            Test.@test dry_flag == false
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "single test name" begin
            (sel, _, _) = parse_args(["utils"])
            Test.@test sel == ["utils"]
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "multiple test names" begin
            (sel, _, _) = parse_args(["utils", "default"])
            Test.@test sel == ["utils", "default"]
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "coverage flags are filtered out" begin
            (sel, _, _) = parse_args(["coverage=true"])
            Test.@test sel == String[]
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "CLI flags -a / --all" begin
            # -a should set run_all=true
            (_, run_all, _) = parse_args(["-a"])
            Test.@test run_all == true

            (_, run_all, _) = parse_args(["--all"])
            Test.@test run_all == true
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "CLI flags -n / --dryrun" begin
            # -n should set dry_run=true
            (_, _, dry_run) = parse_args(["-n"])
            Test.@test dry_run == true

            (_, _, dry_run) = parse_args(["--dryrun"])
            Test.@test dry_run == true
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "mixed flags and tests" begin
            (sel, run_all, dry_run) = parse_args(["utils", "-n", "--all"])
            Test.@test sel == ["utils"]
            Test.@test run_all == true
            Test.@test dry_run == true
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "test/ prefix is stripped" begin
            (sel, _, _) = parse_args(["test/suite/foo"])
            Test.@test sel == ["suite/foo"]

            (sel, _, _) = parse_args(["test/suite"])
            Test.@test sel == ["suite"]

            # No prefix → unchanged
            (sel, _, _) = parse_args(["suite/foo"])
            Test.@test sel == ["suite/foo"]

            # Exact "test" (no slash) → unchanged
            (sel, _, _) = parse_args(["test"])
            Test.@test sel == ["test"]

            # Multiple args with mixed prefixes
            (sel, _, _) = parse_args(["test/suite/a", "suite/b"])
            Test.@test sel == ["suite/a", "suite/b"]
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_strip_test_prefix" begin
        strip_prefix = TestRunner._strip_test_prefix

        Test.@test strip_prefix("test/suite/foo") == "suite/foo"
        Test.@test strip_prefix("test/a") == "a"
        Test.@test strip_prefix("suite/foo") == "suite/foo"
        Test.@test strip_prefix("test") == "test"
        Test.@test strip_prefix("testing/foo") == "testing/foo"
        Test.@test strip_prefix("test/") == ""
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "run_tests (dry run)" begin
        mktempdir() do temp_dir
            touch(joinpath(temp_dir, "test_dummy.jl"))

            # Use Pipe for redirect_stdout (IOBuffer not supported in Julia 1.12+)
            old_stdout = stdout
            rd, wr = redirect_stdout()
            try
                Extensions.run_tests(;
                    args=["--dryrun", "test_dummy.jl"],
                    testset_name="DryRun",
                    available_tests=("*.jl",),
                    filename_builder=identity,
                    funcname_builder=identity,
                    eval_mode=false,
                    verbose=false,
                    showtiming=false,
                    test_dir=temp_dir,
                )
            finally
                redirect_stdout(old_stdout)
                close(wr)
            end
            s = read(rd, String)

            Test.@test occursin("Dry run", s)
            Test.@test occursin("test_dummy.jl", s)
        end
    end

    # ============================================================================
    # UNIT TESTS - _select_tests
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_select_tests" begin
        select_tests = TestRunner._select_tests

        # Mock filename builder for testing
        test_builder_sym = name -> Symbol(:test_, name)
        test_builder_str = name -> "test_" * String(name)

        # Mocking readdir requires a temporary directory or we mock the fs behavior? 
        # Easier: we test the filtering logic with a custom test_dir.
        # Let's create a temporary directory structure for testing.

        mktempdir() do temp_dir
            # Create some dummy test files
            touch(joinpath(temp_dir, "test_utils.jl"))
            touch(joinpath(temp_dir, "test_core.jl"))
            touch(joinpath(temp_dir, "runtests.jl")) # Should be ignored
            touch(joinpath(temp_dir, "readme.md"))   # Should be ignored

            # ==========================================================
            # Scenario 1: Auto-discovery (available_tests empty)
            # ==========================================================
            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Auto-discovery (empty available_tests)" begin
                # Empty args -> run all .jl files (excluding runtests.jl)
                # Names derived as basenames
                sel = select_tests(String[], Symbol[], false, identity; test_dir=temp_dir)
                Test.@test sort(sel) == ["test_core.jl", "test_utils.jl"]

                # Run all (-a) -> same result
                sel = select_tests(String[], Symbol[], true, identity; test_dir=temp_dir)
                Test.@test sort(sel) == ["test_core.jl", "test_utils.jl"]

                # Globbing: select only utils
                sel = select_tests(
                    ["test_utils"], Symbol[], false, identity; test_dir=temp_dir
                )
                Test.@test sel == ["test_utils.jl"]

                # Globbing: pattern matching
                sel = select_tests(
                    ["test_c*"], Symbol[], false, identity; test_dir=temp_dir
                )
                Test.@test sel == ["test_core.jl"]

                # Globbing: match filename?
                sel = select_tests(
                    ["test_core_jl"], Symbol[], false, identity; test_dir=temp_dir
                )
                # "^test_core_jl$" doesn't match "test_core.jl" or "test_core"
                Test.@test isempty(sel)

                sel = select_tests(
                    ["test_core.jl"], Symbol[], false, identity; test_dir=temp_dir
                )
                Test.@test sel == ["test_core.jl"]
            end

            # ==========================================================
            # Scenario 2: With available_tests
            # ==========================================================
            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "With available_tests" begin
                available = [:utils, :core]

                # Note: TestRunner checks if file exists via builder
                # test_utils.jl exists -> :utils is valid
                # test_core.jl exists -> :core is valid

                # Empty args -> run all valid available tests
                sel = select_tests(
                    String[], available, false, test_builder_sym; test_dir=temp_dir
                )
                Test.@test sort(sel) == [:core, :utils]

                # Selection
                sel = select_tests(
                    ["utils"], available, false, test_builder_sym; test_dir=temp_dir
                )
                Test.@test sel == [:utils]

                # Globbing over available names
                # available test :core, file: test_core.jl
                sel = select_tests(
                    ["c*"], available, false, test_builder_sym; test_dir=temp_dir
                )
                Test.@test sel == [:core]

                # Globbing over filename without extension
                # available test :core, file: test_core.jl
                sel = select_tests(
                    ["test_core"], available, false, test_builder_sym; test_dir=temp_dir
                )
                Test.@test sel == [:core]

                # Builder may return String
                sel = select_tests(
                    ["core"], available, false, test_builder_str; test_dir=temp_dir
                )
                Test.@test sel == [:core]
            end

            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "symbol in subdirectory" begin
                mkpath(joinpath(temp_dir, "suite_src"))
                touch(joinpath(temp_dir, "suite_src", "test_utils.jl"))

                available = [:utils]

                sel = select_tests(
                    String[], available, false, test_builder_sym; test_dir=temp_dir
                )
                Test.@test sel == [:utils]
            end

            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "available_tests may be directories" begin
                mkpath(joinpath(temp_dir, "suite"))
                touch(joinpath(temp_dir, "suite", "test_a.jl"))
                touch(joinpath(temp_dir, "suite", "test_b.jl"))

                available = TestRunner.TestSpec["suite"]
                sel = select_tests(String[], available, false, identity; test_dir=temp_dir)
                Test.@test sel == ["suite/test_a.jl", "suite/test_b.jl"]

                sel = select_tests(
                    ["suite/test_a"], available, false, identity; test_dir=temp_dir
                )
                Test.@test sel == ["suite/test_a.jl"]
            end

            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "glob: match basename without test_ prefix" begin
                mkpath(joinpath(temp_dir, "suite_src"))
                touch(joinpath(temp_dir, "suite_src", "test_utils.jl"))

                available = TestRunner.TestSpec["suite_src/*"]

                sel = select_tests(["utils"], available, false, identity; test_dir=temp_dir)
                Test.@test sel == ["suite_src/test_utils.jl"]
            end

            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "bare directory selection" begin
                mkpath(joinpath(temp_dir, "suite_norm"))
                touch(joinpath(temp_dir, "suite_norm", "test_x.jl"))
                touch(joinpath(temp_dir, "suite_norm", "test_y.jl"))

                available = TestRunner.TestSpec["suite_norm/*"]

                # "suite_norm" (no wildcard) should behave like "suite_norm/*"
                sel = select_tests(
                    ["suite_norm"], available, false, identity; test_dir=temp_dir
                )
                Test.@test sort(sel) == ["suite_norm/test_x.jl", "suite_norm/test_y.jl"]

                # Trailing slash should also work
                sel = select_tests(
                    ["suite_norm/"], available, false, identity; test_dir=temp_dir
                )
                Test.@test sort(sel) == ["suite_norm/test_x.jl", "suite_norm/test_y.jl"]

                # Explicit wildcard still works
                sel = select_tests(
                    ["suite_norm/*"], available, false, identity; test_dir=temp_dir
                )
                Test.@test sort(sel) == ["suite_norm/test_x.jl", "suite_norm/test_y.jl"]
            end

            Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "bare nested directory selection" begin
                mkpath(joinpath(temp_dir, "suite_deep", "sub"))
                touch(joinpath(temp_dir, "suite_deep", "sub", "test_z.jl"))

                available = TestRunner.TestSpec["suite_deep/sub/*"]

                # "suite_deep/sub" should match "suite_deep/sub/*"
                sel = select_tests(
                    ["suite_deep/sub"], available, false, identity; test_dir=temp_dir
                )
                Test.@test sel == ["suite_deep/sub/test_z.jl"]
            end
        end
    end

    # ============================================================================
    # UNIT TESTS - _normalize_selections
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_normalize_selections" begin
        normalize = TestRunner._normalize_selections

        candidates = TestRunner.TestSpec[
            "suite/exceptions/test_display.jl",
            "suite/exceptions/test_types.jl",
            "suite/core/test_core.jl",
        ]

        Test.@testset "bare directory expands to dir/*" begin
            result = normalize(["suite/exceptions"], candidates)
            Test.@test "suite/exceptions" in result
            Test.@test "suite/exceptions/*" in result
        end

        Test.@testset "trailing slash is stripped and expanded" begin
            result = normalize(["suite/exceptions/"], candidates)
            Test.@test "suite/exceptions" in result
            Test.@test "suite/exceptions/*" in result
        end

        Test.@testset "pattern with wildcard is kept as-is" begin
            result = normalize(["suite/exceptions/*"], candidates)
            Test.@test result == ["suite/exceptions/*"]
        end

        Test.@testset "non-matching directory is not expanded" begin
            result = normalize(["nonexistent"], candidates)
            Test.@test result == ["nonexistent"]
        end

        Test.@testset "parent directory expands" begin
            result = normalize(["suite"], candidates)
            Test.@test "suite" in result
            Test.@test "suite/*" in result
        end

        Test.@testset "no duplicates" begin
            result = normalize(["suite/exceptions", "suite/exceptions/"], candidates)
            Test.@test count(==("suite/exceptions"), result) == 1
            Test.@test count(==("suite/exceptions/*"), result) == 1
        end
    end

    # ============================================================================
    # UNIT TESTS - Progress display
    # ============================================================================

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
            fmt(buf, info; history=history, cumulative_severity=maximum(history))
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
            fmt(buf, info; cumulative_severity=2)
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
    end

    # ============================================================================
    # EDGE CASES
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Edge cases" begin
        parse_args = TestRunner._parse_test_args
        select_tests = TestRunner._select_tests
        normalize_available = TestRunner._normalize_available_tests
        find_symbol_file = TestRunner._find_symbol_test_file_rel

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "mixed case & special chars" begin
            # Test names are converted to Symbols, preserving case
            (sel, _, _) = parse_args(["MyTest", "test_123"])
            Test.@test sel == ["MyTest", "test_123"]
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "available_tests may be a Tuple" begin
            out = normalize_available((:a, "suite_ext/*"))
            Test.@test out == TestRunner.TestSpec[:a, "suite_ext/*"]
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "available_tests may be Vector{Any}" begin
            out = normalize_available(Any[:a, "suite_ext/*"])
            Test.@test out == TestRunner.TestSpec[:a, "suite_ext/*"]
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "available_tests input validation" begin
            Test.@test_throws Exceptions.IncorrectArgument normalize_available(123)
            Test.@test_throws Exceptions.IncorrectArgument normalize_available(Any[1])
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "symbol resolution: shallowest match" begin
            mktempdir() do temp_dir
                mkpath(joinpath(temp_dir, "a"))
                mkpath(joinpath(temp_dir, "a", "b"))
                touch(joinpath(temp_dir, "a", "test_x.jl"))
                touch(joinpath(temp_dir, "a", "b", "test_x.jl"))

                rel = find_symbol_file(:x, n -> "test_" * String(n); test_dir=temp_dir)
                Test.@test rel == joinpath("a", "test_x.jl")
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "order preservation" begin
            # Selections should preserve order in ARGS parsing
            (sel, _, _) = parse_args(["z", "a", "m"])
            Test.@test sel == ["z", "a", "m"]

            # Using custom select_tests to verify preservation behavior
            mktempdir() do temp_dir
                touch(joinpath(temp_dir, "z.jl"))
                touch(joinpath(temp_dir, "a.jl"))
                touch(joinpath(temp_dir, "m.jl"))
                touch(joinpath(temp_dir, "b.jl"))

                # Case 1: Available list order determines output order if provided
                sel = select_tests(
                    ["z", "a"], [:a, :b, :z], false, identity; test_dir=temp_dir
                )
                Test.@test sel == [:a, :z] # candidates order candidate list order

                # Case 2: Auto-discovery order (filesystem order, filtered)
                # We can't guarantee FS order, so checking set equality
                sel = select_tests(["z", "a"], Symbol[], false, identity; test_dir=temp_dir)
                Test.@test Set(sel) == Set(["a.jl", "z.jl"])
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "duplicate selections preserved" begin
            # Duplicates are not filtered (caller's responsibility)
            (sel, _, _) = parse_args(["utils", "utils"])
            Test.@test sel == ["utils", "utils"]
        end
    end

    # ============================================================================
    # UNIT TESTS - _run_single_test error branches
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_run_single_test" begin
        run_single = TestRunner._run_single_test

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "error when file not found" begin
            # L112: error branch when test file doesn't exist
            err = try
                run_single(
                    :nonexistent_file_xyz123;
                    filename_builder=identity,
                    funcname_builder=identity,
                    eval_mode=true,
                    test_dir=mktempdir(),
                )
                nothing
            catch e
                e
            end
            Test.@test err isa Exceptions.IncorrectArgument
            Test.@test occursin("not found", err.msg)
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "string spec: file not found" begin
            err = try
                run_single(
                    "does_not_exist_abc123.jl";
                    filename_builder=identity,
                    funcname_builder=identity,
                    eval_mode=true,
                    test_dir=mktempdir(),
                )
                nothing
            catch e
                e
            end
            Test.@test err isa Exceptions.IncorrectArgument
            Test.@test occursin("not found", err.msg)
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "string spec: eval_mode=false" begin
            mktempdir() do temp_dir
                stem = "testrunner_evalmode_false"
                file = joinpath(temp_dir, stem * ".jl")
                write(
                    file,
                    "const __ctbase_tr_flag__ = Ref(false)\n" *
                    "function $(stem)()\n" *
                    "    __ctbase_tr_flag__[] = true\n" *
                    "    return nothing\n" *
                    "end\n",
                )

                run_single(
                    stem;
                    filename_builder=identity,
                    funcname_builder=identity,
                    eval_mode=false,
                    test_dir=temp_dir,
                )
                # Use invokelatest to avoid world age warning in Julia 1.12+
                flag_value = Base.invokelatest(getfield, Main, :__ctbase_tr_flag__)
                Test.@test flag_value[] == false
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "symbol spec: eval_mode=false" begin
            mktempdir() do temp_dir
                touch(joinpath(temp_dir, "test_sym_noeval.jl"))
                write(
                    joinpath(temp_dir, "test_sym_noeval.jl"),
                    "const __ctbase_sym_tr_flag__ = Ref(false)\n" *
                    "function test_sym_noeval()\n" *
                    "    __ctbase_sym_tr_flag__[] = true\n" *
                    "    return nothing\n" *
                    "end\n",
                )

                run_single(
                    :sym_noeval;
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> "test_" * String(n),
                    eval_mode=false,
                    test_dir=temp_dir,
                )

                flag_value = Base.invokelatest(getfield, Main, :__ctbase_sym_tr_flag__)
                Test.@test flag_value[] == false
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "string spec: missing function" begin
            mktempdir() do temp_dir
                stem = "testrunner_missing_func"
                file = joinpath(temp_dir, stem * ".jl")
                write(file, "x = 1\n")

                err = try
                    run_single(
                        stem;
                        filename_builder=identity,
                        funcname_builder=identity,
                        eval_mode=true,
                        test_dir=temp_dir,
                    )
                    nothing
                catch e
                    e
                end

                Test.@test err isa Exceptions.PreconditionError
                Test.@test occursin("not found", err.msg)
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "symbol spec: funcname_builder returns nothing" begin
            mktempdir() do temp_dir
                touch(joinpath(temp_dir, "test_foo.jl"))

                err = try
                    run_single(
                        :foo;
                        filename_builder=n -> "test_" * String(n),
                        funcname_builder=_ -> nothing,
                        eval_mode=true,
                        test_dir=temp_dir,
                    )
                    nothing
                catch e
                    e
                end

                Test.@test err isa Exceptions.PreconditionError
                Test.@test occursin("eval_mode=true", err.msg)
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "symbol spec: built function missing" begin
            mktempdir() do temp_dir
                write(joinpath(temp_dir, "test_bar.jl"), "x = 1\n")

                err = try
                    run_single(
                        :bar;
                        filename_builder=n -> "test_" * String(n),
                        funcname_builder=n -> "test_" * String(n),
                        eval_mode=true,
                        test_dir=temp_dir,
                    )
                    nothing
                catch e
                    e
                end

                Test.@test err isa Exceptions.PreconditionError
                Test.@test occursin("not found", err.msg)
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "funcname_builder: String or Symbol" begin
            mktempdir() do temp_dir
                # Create two test files with different names to avoid redefinition warning
                write(
                    joinpath(temp_dir, "test_baz_string.jl"),
                    "function test_baz_string()\n    Test.@test true\nend\n",
                )
                write(
                    joinpath(temp_dir, "test_baz_symbol.jl"),
                    "function test_baz_symbol()\n    Test.@test true\nend\n",
                )

                # Test with funcname_builder returning String
                run_single(
                    :baz_string;
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> "test_" * String(n),  # Returns String
                    eval_mode=true,
                    test_dir=temp_dir,
                )
                # If no error, the test passed

                # Test with funcname_builder returning Symbol
                run_single(
                    :baz_symbol;
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),  # Returns Symbol
                    eval_mode=true,
                    test_dir=temp_dir,
                )
                # If no error, the test passed

                Test.@test true  # Explicit pass if both succeeded
            end
        end

        # Note: Other error branches (L126, L134, L139) are not directly tested
        # because they require Base.include(Main, ...) which causes side effects.
        # They are tested indirectly through normal test execution.
    end

    # ============================================================================
    # UNIT TESTS - TestRunInfo struct
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "TestRunInfo" begin
        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "construction with all fields" begin
            info = TestRunner.TestRunInfo(
                :my_test,
                "/tmp/test_my_test.jl",
                :test_my_test,
                1,
                5,
                :pre_eval,
                nothing,
                nothing,
            )
            Test.@test info.spec === :my_test
            Test.@test info.filename == "/tmp/test_my_test.jl"
            Test.@test info.func_symbol === :test_my_test
            Test.@test info.index == 1
            Test.@test info.total == 5
            Test.@test info.status === :pre_eval
            Test.@test info.error === nothing
            Test.@test info.elapsed === nothing
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "construction with String spec" begin
            info = TestRunner.TestRunInfo(
                "suite/test_a.jl",
                "/tmp/suite/test_a.jl",
                :test_a,
                3,
                10,
                :post_eval,
                nothing,
                1.5,
            )
            Test.@test info.spec == "suite/test_a.jl"
            Test.@test info.elapsed == 1.5
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "construction with error" begin
            ex = ErrorException("boom")
            info = TestRunner.TestRunInfo(
                :failing, "/tmp/test_failing.jl", :test_failing, 2, 3, :error, ex, 0.1
            )
            Test.@test info.status === :error
            Test.@test info.error === ex
            Test.@test info.elapsed == 0.1
        end
    end

    # ============================================================================
    # UNIT TESTS - Callbacks via _run_single_test
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Callbacks" begin
        run_single = TestRunner._run_single_test

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_start receives :pre_eval" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_start.jl"),
                    "function test_cb_start()\n    Test.@test true\nend\n",
                )

                captured = Ref{Any}(nothing)
                run_single(
                    :cb_start;
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),
                    eval_mode=true,
                    test_dir=temp_dir,
                    index=2,
                    total=7,
                    on_test_start=info -> (captured[]=info; true),
                    on_test_done=nothing,
                )

                info = captured[]
                Test.@test info isa TestRunner.TestRunInfo
                Test.@test info.spec === :cb_start
                Test.@test info.func_symbol === :test_cb_start
                Test.@test info.index == 2
                Test.@test info.total == 7
                Test.@test info.status === :pre_eval
                Test.@test info.error === nothing
                Test.@test info.elapsed === nothing
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_done receives :post_eval" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_done.jl"),
                    "function test_cb_done()\n    Test.@test true\nend\n",
                )

                captured = Ref{Any}(nothing)
                run_single(
                    :cb_done;
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),
                    eval_mode=true,
                    test_dir=temp_dir,
                    index=1,
                    total=3,
                    on_test_start=nothing,
                    on_test_done=info -> (captured[] = info),
                )

                info = captured[]
                Test.@test info isa TestRunner.TestRunInfo
                Test.@test info.spec === :cb_done
                Test.@test info.status === :post_eval
                Test.@test info.error === nothing
                Test.@test info.elapsed isa Float64
                Test.@test info.elapsed >= 0.0
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_start false skips eval" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_skip.jl"),
                    "const __ctbase_cb_skip_flag__ = Ref(false)\n" *
                    "function test_cb_skip()\n" *
                    "    __ctbase_cb_skip_flag__[] = true\n" *
                    "    return nothing\n" *
                    "end\n",
                )

                done_captured = Ref{Any}(nothing)
                run_single(
                    :cb_skip;
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),
                    eval_mode=true,
                    test_dir=temp_dir,
                    index=1,
                    total=1,
                    on_test_start=_ -> false,
                    on_test_done=info -> (done_captured[] = info),
                )

                # Function was NOT called
                flag_value = Base.invokelatest(getfield, Main, :__ctbase_cb_skip_flag__)
                Test.@test flag_value[] == false

                # on_test_done was called with :skipped
                info = done_captured[]
                Test.@test info isa TestRunner.TestRunInfo
                Test.@test info.status === :skipped
                Test.@test info.elapsed === nothing
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_done receives :skipped" begin
            mktempdir() do temp_dir
                write(joinpath(temp_dir, "test_cb_noeval.jl"), "x = 1\n")

                done_captured = Ref{Any}(nothing)
                run_single(
                    :cb_noeval;
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),
                    eval_mode=false,
                    test_dir=temp_dir,
                    index=1,
                    total=1,
                    on_test_start=nothing,
                    on_test_done=info -> (done_captured[] = info),
                )

                info = done_captured[]
                Test.@test info isa TestRunner.TestRunInfo
                Test.@test info.status === :skipped
                Test.@test info.func_symbol === nothing
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_done receives :error on eval failure" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_err.jl"),
                    "function test_cb_err()\n    error(\"intentional failure\")\nend\n",
                )

                done_captured = Ref{Any}(nothing)
                err = try
                    run_single(
                        :cb_err;
                        filename_builder=n -> "test_" * String(n),
                        funcname_builder=n -> Symbol(:test_, n),
                        eval_mode=true,
                        test_dir=temp_dir,
                        index=1,
                        total=1,
                        on_test_start=_ -> true,
                        on_test_done=info -> (done_captured[] = info),
                    )
                    nothing
                catch e
                    e
                end

                # Error is rethrown
                Test.@test err isa ErrorException
                Test.@test occursin("intentional failure", err.msg)

                # on_test_done was called with :error
                info = done_captured[]
                Test.@test info isa TestRunner.TestRunInfo
                Test.@test info.status === :error
                Test.@test info.error isa ErrorException
                Test.@test info.elapsed isa Float64
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "both callbacks work together" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_both.jl"),
                    "function test_cb_both()\n    Test.@test true\nend\n",
                )

                start_captured = Ref{Any}(nothing)
                done_captured = Ref{Any}(nothing)
                run_single(
                    :cb_both;
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),
                    eval_mode=true,
                    test_dir=temp_dir,
                    index=3,
                    total=5,
                    on_test_start=info -> (start_captured[]=info; true),
                    on_test_done=info -> (done_captured[] = info),
                )

                Test.@test start_captured[].status === :pre_eval
                Test.@test start_captured[].index == 3
                Test.@test start_captured[].total == 5
                Test.@test done_captured[].status === :post_eval
                Test.@test done_captured[].index == 3
                Test.@test done_captured[].total == 5
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "callbacks with String spec" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_str.jl"),
                    "function test_cb_str()\n    Test.@test true\nend\n",
                )

                start_captured = Ref{Any}(nothing)
                done_captured = Ref{Any}(nothing)
                run_single(
                    "test_cb_str.jl";
                    filename_builder=identity,
                    funcname_builder=identity,
                    eval_mode=true,
                    test_dir=temp_dir,
                    index=1,
                    total=2,
                    on_test_start=info -> (start_captured[]=info; true),
                    on_test_done=info -> (done_captured[] = info),
                )

                Test.@test start_captured[].spec == "test_cb_str.jl"
                Test.@test start_captured[].status === :pre_eval
                Test.@test done_captured[].spec == "test_cb_str.jl"
                Test.@test done_captured[].status === :post_eval
            end
        end

        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "no callbacks (nothing) preserves original behavior" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_none.jl"),
                    "function test_cb_none()\n    Test.@test true\nend\n",
                )

                # Should not error when callbacks are nothing
                run_single(
                    :cb_none;
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),
                    eval_mode=true,
                    test_dir=temp_dir,
                    on_test_start=nothing,
                    on_test_done=nothing,
                )
                Test.@test true
            end
        end
    end

    # ============================================================================
    # INTEGRATION TESTS - Callbacks via run_tests
    # ============================================================================

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "Callbacks via run_tests" begin
        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_start and on_test_done called for each test" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_int_a.jl"),
                    "function test_int_a()\n    Test.@test true\nend\n",
                )
                write(
                    joinpath(temp_dir, "test_int_b.jl"),
                    "function test_int_b()\n    Test.@test true\nend\n",
                )

                start_log = TestRunner.TestRunInfo[]
                done_log = TestRunner.TestRunInfo[]

                Extensions.run_tests(;
                    args=String[],
                    testset_name="CallbackIntegration",
                    available_tests=(:int_a, :int_b),
                    filename_builder=n -> Symbol(:test_, n),
                    funcname_builder=n -> Symbol(:test_, n),
                    eval_mode=true,
                    verbose=false,
                    showtiming=false,
                    test_dir=temp_dir,
                    on_test_start=info -> (push!(start_log, info); true),
                    on_test_done=info -> push!(done_log, info),
                )

                Test.@test length(start_log) == 2
                Test.@test length(done_log) == 2

                # Check index/total progression
                Test.@test start_log[1].index == 1
                Test.@test start_log[1].total == 2
                Test.@test start_log[2].index == 2
                Test.@test start_log[2].total == 2

                # Check statuses
                Test.@test all(info -> info.status === :pre_eval, start_log)
                Test.@test all(info -> info.status === :post_eval, done_log)

                # Check elapsed is populated
                Test.@test all(info -> info.elapsed isa Float64, done_log)
            end
        end
    end

    return nothing
end

end # module

# Re-export for TestRunner discovery
test_testrunner() = TestTestRunner.test_testrunner()
