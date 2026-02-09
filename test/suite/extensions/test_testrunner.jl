module TestTestRunner

using Test
using CTBase

const TestRunner = Base.get_extension(CTBase, :TestRunner)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

struct DummyTestRunnerTag <: CTBase.Extensions.AbstractTestRunnerTag end

function test_testrunner()
    # ============================================================================
    # UNIT TESTS - TestRunner extension
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "TestRunner extension" begin
        @test Base.get_extension(CTBase, :TestRunner) !== nothing
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "TestRunner stub dispatch" begin
        err = try
            CTBase.run_tests(DummyTestRunnerTag())
            nothing
        catch e
            e
        end

        @test err isa CTBase.ExtensionError
        @test err.weakdeps == (:Test,)
    end

    # ============================================================================
    # UNIT TESTS - _parse_test_args
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_parse_test_args" begin
        # Access the private function via the loaded extension module
        parse_args = TestRunner._parse_test_args

        @testset verbose = VERBOSE showtiming = SHOWTIMING "empty args with defaults" begin
            (sel, all_flag, dry_flag) = parse_args(String[])
            @test sel == String[]
            @test all_flag == false

            @test dry_flag == false
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "single test name" begin
            (sel, _, _) = parse_args(["utils"])
            @test sel == ["utils"]
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "multiple test names" begin
            (sel, _, _) = parse_args(["utils", "default"])
            @test sel == ["utils", "default"]
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "coverage flags are filtered out" begin
            (sel, _, _) = parse_args(["coverage=true"])
            @test sel == String[]
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "CLI flags -a / --all" begin
            # -a should set run_all=true
            (_, run_all, _) = parse_args(["-a"])
            @test run_all == true

            (_, run_all, _) = parse_args(["--all"])
            @test run_all == true
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "CLI flags -n / --dryrun" begin
            # -n should set dry_run=true
            (_, _, dry_run) = parse_args(["-n"])
            @test dry_run == true

            (_, _, dry_run) = parse_args(["--dryrun"])
            @test dry_run == true
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "mixed flags and tests" begin
            (sel, run_all, dry_run) = parse_args(["utils", "-n", "--all"])
            @test sel == ["utils"]
            @test run_all == true
            @test dry_run == true
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "test/ prefix is stripped" begin
            (sel, _, _) = parse_args(["test/suite/foo"])
            @test sel == ["suite/foo"]

            (sel, _, _) = parse_args(["test/suite"])
            @test sel == ["suite"]

            # No prefix → unchanged
            (sel, _, _) = parse_args(["suite/foo"])
            @test sel == ["suite/foo"]

            # Exact "test" (no slash) → unchanged
            (sel, _, _) = parse_args(["test"])
            @test sel == ["test"]

            # Multiple args with mixed prefixes
            (sel, _, _) = parse_args(["test/suite/a", "suite/b"])
            @test sel == ["suite/a", "suite/b"]
        end
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_strip_test_prefix" begin
        strip_prefix = TestRunner._strip_test_prefix

        @test strip_prefix("test/suite/foo") == "suite/foo"
        @test strip_prefix("test/a") == "a"
        @test strip_prefix("suite/foo") == "suite/foo"
        @test strip_prefix("test") == "test"
        @test strip_prefix("testing/foo") == "testing/foo"
        @test strip_prefix("test/") == ""
    end

    @testset verbose = VERBOSE showtiming = SHOWTIMING "run_tests (dry run)" begin
        mktempdir() do temp_dir
            touch(joinpath(temp_dir, "test_dummy.jl"))

            # Use Pipe for redirect_stdout (IOBuffer not supported in Julia 1.12+)
            old_stdout = stdout
            rd, wr = redirect_stdout()
            try
                CTBase.run_tests(;
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

            @test occursin("Dry run", s)
            @test occursin("test_dummy.jl", s)
        end
    end

    # ============================================================================
    # UNIT TESTS - _select_tests
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_select_tests" begin
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
            @testset verbose = VERBOSE showtiming = SHOWTIMING "Auto-discovery (empty available_tests)" begin
                # Empty args -> run all .jl files (excluding runtests.jl)
                # Names derived as basenames
                sel = select_tests(String[], Symbol[], false, identity; test_dir=temp_dir)
                @test sort(sel) == [:test_core, :test_utils]

                # Run all (-a) -> same result
                sel = select_tests(String[], Symbol[], true, identity; test_dir=temp_dir)
                @test sort(sel) == [:test_core, :test_utils]

                # Globbing: select only utils
                sel = select_tests(
                    ["test_utils"], Symbol[], false, identity; test_dir=temp_dir
                )
                @test sel == [:test_utils]

                # Globbing: pattern matching
                sel = select_tests(
                    ["test_c*"], Symbol[], false, identity; test_dir=temp_dir
                )
                @test sel == [:test_core]

                # Globbing: match filename? 
                # candidate=:test_core -> filename="test_core.jl"
                sel = select_tests(
                    ["test_core_jl"], Symbol[], false, identity; test_dir=temp_dir
                )
                # This won't match regex "^test_core_jl$" against "test_core" or "test_core.jl"
                @test isempty(sel)

                sel = select_tests(
                    ["test_core.jl"], Symbol[], false, identity; test_dir=temp_dir
                )
                @test sel == [:test_core]
            end

            # ==========================================================
            # Scenario 2: With available_tests
            # ==========================================================
            @testset verbose = VERBOSE showtiming = SHOWTIMING "With available_tests" begin
                available = [:utils, :core]

                # Note: TestRunner checks if file exists via builder
                # test_utils.jl exists -> :utils is valid
                # test_core.jl exists -> :core is valid

                # Empty args -> run all valid available tests
                sel = select_tests(
                    String[], available, false, test_builder_sym; test_dir=temp_dir
                )
                @test sort(sel) == [:core, :utils]

                # Selection
                sel = select_tests(
                    ["utils"], available, false, test_builder_sym; test_dir=temp_dir
                )
                @test sel == [:utils]

                # Globbing over available names
                # available test :core, file: test_core.jl
                sel = select_tests(
                    ["c*"], available, false, test_builder_sym; test_dir=temp_dir
                )
                @test sel == [:core]

                # Globbing over filename without extension
                # available test :core, file: test_core.jl
                sel = select_tests(
                    ["test_core"], available, false, test_builder_sym; test_dir=temp_dir
                )
                @test sel == [:core]

                # Builder may return String
                sel = select_tests(
                    ["core"], available, false, test_builder_str; test_dir=temp_dir
                )
                @test sel == [:core]
            end

            @testset verbose = VERBOSE showtiming = SHOWTIMING "symbol in subdirectory" begin
                mkpath(joinpath(temp_dir, "suite_src"))
                touch(joinpath(temp_dir, "suite_src", "test_utils.jl"))

                available = [:utils]

                sel = select_tests(
                    String[], available, false, test_builder_sym; test_dir=temp_dir
                )
                @test sel == [:utils]
            end

            @testset verbose = VERBOSE showtiming = SHOWTIMING "available_tests may be directories" begin
                mkpath(joinpath(temp_dir, "suite"))
                touch(joinpath(temp_dir, "suite", "test_a.jl"))
                touch(joinpath(temp_dir, "suite", "test_b.jl"))

                available = TestRunner.TestSpec["suite"]
                sel = select_tests(String[], available, false, identity; test_dir=temp_dir)
                @test sel == ["suite/test_a.jl", "suite/test_b.jl"]

                sel = select_tests(
                    ["suite/test_a"], available, false, identity; test_dir=temp_dir
                )
                @test sel == ["suite/test_a.jl"]
            end

            @testset verbose = VERBOSE showtiming = SHOWTIMING "glob: match basename without test_ prefix" begin
                mkpath(joinpath(temp_dir, "suite_src"))
                touch(joinpath(temp_dir, "suite_src", "test_utils.jl"))

                available = TestRunner.TestSpec["suite_src/*"]

                sel = select_tests(["utils"], available, false, identity; test_dir=temp_dir)
                @test sel == ["suite_src/test_utils.jl"]
            end

            @testset verbose = VERBOSE showtiming = SHOWTIMING "bare directory selection" begin
                mkpath(joinpath(temp_dir, "suite_norm"))
                touch(joinpath(temp_dir, "suite_norm", "test_x.jl"))
                touch(joinpath(temp_dir, "suite_norm", "test_y.jl"))

                available = TestRunner.TestSpec["suite_norm/*"]

                # "suite_norm" (no wildcard) should behave like "suite_norm/*"
                sel = select_tests(
                    ["suite_norm"], available, false, identity; test_dir=temp_dir
                )
                @test sort(sel) == ["suite_norm/test_x.jl", "suite_norm/test_y.jl"]

                # Trailing slash should also work
                sel = select_tests(
                    ["suite_norm/"], available, false, identity; test_dir=temp_dir
                )
                @test sort(sel) == ["suite_norm/test_x.jl", "suite_norm/test_y.jl"]

                # Explicit wildcard still works
                sel = select_tests(
                    ["suite_norm/*"], available, false, identity; test_dir=temp_dir
                )
                @test sort(sel) == ["suite_norm/test_x.jl", "suite_norm/test_y.jl"]
            end

            @testset verbose = VERBOSE showtiming = SHOWTIMING "bare nested directory selection" begin
                mkpath(joinpath(temp_dir, "suite_deep", "sub"))
                touch(joinpath(temp_dir, "suite_deep", "sub", "test_z.jl"))

                available = TestRunner.TestSpec["suite_deep/sub/*"]

                # "suite_deep/sub" should match "suite_deep/sub/*"
                sel = select_tests(
                    ["suite_deep/sub"], available, false, identity; test_dir=temp_dir
                )
                @test sel == ["suite_deep/sub/test_z.jl"]
            end
        end
    end

    # ============================================================================
    # UNIT TESTS - _normalize_selections
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_normalize_selections" begin
        normalize = TestRunner._normalize_selections

        candidates = TestRunner.TestSpec[
            "suite/exceptions/test_display.jl",
            "suite/exceptions/test_types.jl",
            "suite/core/test_core.jl",
        ]

        @testset "bare directory expands to dir/*" begin
            result = normalize(["suite/exceptions"], candidates)
            @test "suite/exceptions" in result
            @test "suite/exceptions/*" in result
        end

        @testset "trailing slash is stripped and expanded" begin
            result = normalize(["suite/exceptions/"], candidates)
            @test "suite/exceptions" in result
            @test "suite/exceptions/*" in result
        end

        @testset "pattern with wildcard is kept as-is" begin
            result = normalize(["suite/exceptions/*"], candidates)
            @test result == ["suite/exceptions/*"]
        end

        @testset "non-matching directory is not expanded" begin
            result = normalize(["nonexistent"], candidates)
            @test result == ["nonexistent"]
        end

        @testset "parent directory expands" begin
            result = normalize(["suite"], candidates)
            @test "suite" in result
            @test "suite/*" in result
        end

        @testset "no duplicates" begin
            result = normalize(["suite/exceptions", "suite/exceptions/"], candidates)
            @test count(==("suite/exceptions"), result) == 1
            @test count(==("suite/exceptions/*"), result) == 1
        end
    end

    # ============================================================================
    # UNIT TESTS - Progress display
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Progress display" begin
        progress_bar = TestRunner._progress_bar
        bar_width = TestRunner._bar_width
        default_on_test_done = TestRunner._default_on_test_done

        @testset "_bar_width adaptive" begin
            @test bar_width(1) == 1
            @test bar_width(10) == 10
            @test bar_width(20) == 20
            @test bar_width(21) == 20
            @test bar_width(30) == 20
            @test bar_width(50) == 20
            @test bar_width(100) == 20
            @test bar_width(500) == 20
            @test bar_width(1000) == 20
            @test bar_width(0) == 0
        end

        @testset "_progress_bar rendering" begin
            # Full bar (explicit width)
            bar = progress_bar(10, 10; width=10)
            @test bar == "[██████████]"

            # Empty bar
            bar = progress_bar(0, 10; width=10)
            @test bar == "[░░░░░░░░░░]"

            # Half bar
            bar = progress_bar(5, 10; width=10)
            @test bar == "[█████░░░░░]"

            # Auto width: 2 tests → width=2
            bar = progress_bar(1, 2)
            @test length(bar) == 4  # 2 chars + 2 brackets

            # Auto width: 50 tests → width=20
            bar = progress_bar(25, 50)
            @test length(bar) == 22  # 20 chars + 2 brackets

            # Auto width: 500 tests → width=20
            bar = progress_bar(250, 500)
            @test length(bar) == 22  # 20 chars + 2 brackets

            # Edge case: total=0
            bar = progress_bar(0, 0; width=10)
            @test bar == "[░░░░░░░░░░]"
        end

        @testset "_format_progress_line output" begin
            fmt = TestRunner._format_progress_line

            info = TestRunner.TestRunInfo(
                :my_test, "/tmp/test_my_test.jl", :test_my_test,
                3, 10, :post_eval, nothing, 1.234,
            )
            buf = IOBuffer()
            fmt(buf, info)
            output = String(take!(buf))
            @test contains(output, "✓")
            @test contains(output, "[03/10]")
            @test contains(output, "my_test")
            @test contains(output, "1.2s")
            @test contains(output, "█")

            # Error status
            info_err = TestRunner.TestRunInfo(
                "suite/test_fail.jl", "/tmp/test_fail.jl", :test_fail,
                5, 10, :error, ErrorException("boom"), 0.5,
            )
            buf_err = IOBuffer()
            fmt(buf_err, info_err)
            output_err = String(take!(buf_err))
            @test contains(output_err, "✗")
            @test contains(output_err, "FAILED")
            @test contains(output_err, "[05/10]")

            # test_failed status (from @test failures)
            info_tf = TestRunner.TestRunInfo(
                :my_test, "/tmp/test_my_test.jl", :test_my_test,
                7, 10, :test_failed, nothing, 2.0,
            )
            buf_tf = IOBuffer()
            fmt(buf_tf, info_tf)
            output_tf = String(take!(buf_tf))
            @test contains(output_tf, "✗")
            @test contains(output_tf, "FAILED")

            # Skipped status
            info_skip = TestRunner.TestRunInfo(
                :skipped_test, "/tmp/test_skip.jl", :test_skip,
                1, 5, :skipped, nothing, nothing,
            )
            buf_skip = IOBuffer()
            fmt(buf_skip, info_skip)
            output_skip = String(take!(buf_skip))
            @test contains(output_skip, "○")
            @test !contains(output_skip, "FAILED")

            # Fixed bar of 20 chars even for >400 tests (empty at start)
            info_large = TestRunner.TestRunInfo(
                :big_test, "/tmp/test_big.jl", :test_big,
                1, 500, :post_eval, nothing, 0.1,
            )
            buf_large = IOBuffer()
            fmt(buf_large, info_large)
            output_large = String(take!(buf_large))
            @test contains(output_large, "✓")
            @test contains(output_large, "░")
            
            # Test with some progress (25%)
            info_large_progress = TestRunner.TestRunInfo(
                :big_test, "/tmp/test_big.jl", :test_big,
                125, 500, :post_eval, nothing, 0.1,
            )
            buf_large_progress = IOBuffer()
            fmt(buf_large_progress, info_large_progress)
            output_large_progress = String(take!(buf_large_progress))
            @test contains(output_large_progress, "✓")
            @test contains(output_large_progress, "█")
            @test contains(output_large_progress, "░")
        end
    end

    # ============================================================================
    # EDGE CASES
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Edge cases" begin
        parse_args = TestRunner._parse_test_args
        select_tests = TestRunner._select_tests
        normalize_available = TestRunner._normalize_available_tests
        find_symbol_file = TestRunner._find_symbol_test_file_rel

        @testset verbose = VERBOSE showtiming = SHOWTIMING "mixed case & special chars" begin
            # Test names are converted to Symbols, preserving case
            (sel, _, _) = parse_args(["MyTest", "test_123"])
            @test sel == ["MyTest", "test_123"]
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "available_tests may be a Tuple" begin
            out = normalize_available((:a, "suite_ext/*"))
            @test out == TestRunner.TestSpec[:a, "suite_ext/*"]
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "available_tests may be Vector{Any}" begin
            out = normalize_available(Any[:a, "suite_ext/*"])
            @test out == TestRunner.TestSpec[:a, "suite_ext/*"]
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "available_tests input validation" begin
            @test_throws ArgumentError normalize_available(123)
            @test_throws ArgumentError normalize_available(Any[1])
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "symbol resolution: shallowest match" begin
            mktempdir() do temp_dir
                mkpath(joinpath(temp_dir, "a"))
                mkpath(joinpath(temp_dir, "a", "b"))
                touch(joinpath(temp_dir, "a", "test_x.jl"))
                touch(joinpath(temp_dir, "a", "b", "test_x.jl"))

                rel = find_symbol_file(:x, n -> "test_" * String(n); test_dir=temp_dir)
                @test rel == joinpath("a", "test_x.jl")
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "order preservation" begin
            # Selections should preserve order in ARGS parsing
            (sel, _, _) = parse_args(["z", "a", "m"])
            @test sel == ["z", "a", "m"]

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
                @test sel == [:a, :z] # candidates order candidate list order

                # Case 2: Auto-discovery order (filesystem order, filtered)
                # We can't guarantee FS order, so checking set equality
                sel = select_tests(["z", "a"], Symbol[], false, identity; test_dir=temp_dir)
                @test Set(sel) == Set([:z, :a])
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "duplicate selections preserved" begin
            # Duplicates are not filtered (caller's responsibility)
            (sel, _, _) = parse_args(["utils", "utils"])
            @test sel == ["utils", "utils"]
        end
    end

    # ============================================================================
    # UNIT TESTS - _run_single_test error branches
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_run_single_test" begin
        run_single = TestRunner._run_single_test

        @testset verbose = VERBOSE showtiming = SHOWTIMING "error when file not found" begin
            # L112: error branch when test file doesn't exist
            err = try
                run_single(
                    :nonexistent_file_xyz123;
                    available_tests=Symbol[],
                    filename_builder=identity,
                    funcname_builder=identity,
                    eval_mode=true,
                    test_dir=mktempdir(),
                )
                nothing
            catch e
                e
            end
            @test err isa ErrorException
            @test occursin("not found", err.msg)
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "string spec: file not found" begin
            err = try
                run_single(
                    "does_not_exist_abc123.jl";
                    available_tests=Symbol[],
                    filename_builder=identity,
                    funcname_builder=identity,
                    eval_mode=true,
                    test_dir=mktempdir(),
                )
                nothing
            catch e
                e
            end
            @test err isa ErrorException
            @test occursin("not found", err.msg)
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "string spec: eval_mode=false" begin
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
                    available_tests=Symbol[],
                    filename_builder=identity,
                    funcname_builder=identity,
                    eval_mode=false,
                    test_dir=temp_dir,
                )
                # Use invokelatest to avoid world age warning in Julia 1.12+
                flag_value = Base.invokelatest(getfield, Main, :__ctbase_tr_flag__)
                @test flag_value[] == false
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "symbol spec: eval_mode=false" begin
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
                    available_tests=Symbol[],
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> "test_" * String(n),
                    eval_mode=false,
                    test_dir=temp_dir,
                )

                flag_value = Base.invokelatest(getfield, Main, :__ctbase_sym_tr_flag__)
                @test flag_value[] == false
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "string spec: missing function" begin
            mktempdir() do temp_dir
                stem = "testrunner_missing_func"
                file = joinpath(temp_dir, stem * ".jl")
                write(file, "x = 1\n")

                err = try
                    run_single(
                        stem;
                        available_tests=Symbol[],
                        filename_builder=identity,
                        funcname_builder=identity,
                        eval_mode=true,
                        test_dir=temp_dir,
                    )
                    nothing
                catch e
                    e
                end

                @test err isa ErrorException
                @test occursin("Function", err.msg)
                @test occursin("not found", err.msg)
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "symbol spec: funcname_builder returns nothing" begin
            mktempdir() do temp_dir
                touch(joinpath(temp_dir, "test_foo.jl"))

                err = try
                    run_single(
                        :foo;
                        available_tests=Symbol[],
                        filename_builder=n -> "test_" * String(n),
                        funcname_builder=_ -> nothing,
                        eval_mode=true,
                        test_dir=temp_dir,
                    )
                    nothing
                catch e
                    e
                end

                @test err isa ErrorException
                @test occursin("Inconsistency", err.msg)
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "symbol spec: built function missing" begin
            mktempdir() do temp_dir
                write(joinpath(temp_dir, "test_bar.jl"), "x = 1\n")

                err = try
                    run_single(
                        :bar;
                        available_tests=Symbol[],
                        filename_builder=n -> "test_" * String(n),
                        funcname_builder=n -> "test_" * String(n),
                        eval_mode=true,
                        test_dir=temp_dir,
                    )
                    nothing
                catch e
                    e
                end

                @test err isa ErrorException
                @test occursin("Function", err.msg)
                @test occursin("not found", err.msg)
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "funcname_builder: String or Symbol" begin
            mktempdir() do temp_dir
                # Create a test file with a function
                write(
                    joinpath(temp_dir, "test_baz.jl"),
                    "function test_baz()\n    @test true\nend\n",
                )

                # Test with funcname_builder returning String
                run_single(
                    :baz;
                    available_tests=Symbol[],
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> "test_" * String(n),  # Returns String
                    eval_mode=true,
                    test_dir=temp_dir,
                )
                # If no error, the test passed

                # Test with funcname_builder returning Symbol
                run_single(
                    :baz;
                    available_tests=Symbol[],
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),  # Returns Symbol
                    eval_mode=true,
                    test_dir=temp_dir,
                )
                # If no error, the test passed

                @test true  # Explicit pass if both succeeded
            end
        end

        # Note: Other error branches (L126, L134, L139) are not directly tested
        # because they require Base.include(Main, ...) which causes side effects.
        # They are tested indirectly through normal test execution.
    end

    # ============================================================================
    # UNIT TESTS - TestRunInfo struct
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "TestRunInfo" begin
        @testset verbose = VERBOSE showtiming = SHOWTIMING "construction with all fields" begin
            info = TestRunner.TestRunInfo(:my_test, "/tmp/test_my_test.jl", :test_my_test, 1, 5, :pre_eval, nothing, nothing)
            @test info.spec === :my_test
            @test info.filename == "/tmp/test_my_test.jl"
            @test info.func_symbol === :test_my_test
            @test info.index == 1
            @test info.total == 5
            @test info.status === :pre_eval
            @test info.error === nothing
            @test info.elapsed === nothing
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "construction with String spec" begin
            info = TestRunner.TestRunInfo("suite/test_a.jl", "/tmp/suite/test_a.jl", :test_a, 3, 10, :post_eval, nothing, 1.5)
            @test info.spec == "suite/test_a.jl"
            @test info.elapsed == 1.5
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "construction with error" begin
            ex = ErrorException("boom")
            info = TestRunner.TestRunInfo(:failing, "/tmp/test_failing.jl", :test_failing, 2, 3, :error, ex, 0.1)
            @test info.status === :error
            @test info.error === ex
            @test info.elapsed == 0.1
        end
    end

    # ============================================================================
    # UNIT TESTS - Callbacks via _run_single_test
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Callbacks" begin
        run_single = TestRunner._run_single_test

        @testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_start receives :pre_eval" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_start.jl"),
                    "function test_cb_start()\n    @test true\nend\n",
                )

                captured = Ref{Any}(nothing)
                run_single(
                    :cb_start;
                    available_tests=Symbol[],
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),
                    eval_mode=true,
                    test_dir=temp_dir,
                    index=2,
                    total=7,
                    on_test_start=info -> (captured[] = info; true),
                    on_test_done=nothing,
                )

                info = captured[]
                @test info isa TestRunner.TestRunInfo
                @test info.spec === :cb_start
                @test info.func_symbol === :test_cb_start
                @test info.index == 2
                @test info.total == 7
                @test info.status === :pre_eval
                @test info.error === nothing
                @test info.elapsed === nothing
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_done receives :post_eval" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_done.jl"),
                    "function test_cb_done()\n    @test true\nend\n",
                )

                captured = Ref{Any}(nothing)
                run_single(
                    :cb_done;
                    available_tests=Symbol[],
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
                @test info isa TestRunner.TestRunInfo
                @test info.spec === :cb_done
                @test info.status === :post_eval
                @test info.error === nothing
                @test info.elapsed isa Float64
                @test info.elapsed >= 0.0
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_start false skips eval" begin
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
                    available_tests=Symbol[],
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
                @test flag_value[] == false

                # on_test_done was called with :skipped
                info = done_captured[]
                @test info isa TestRunner.TestRunInfo
                @test info.status === :skipped
                @test info.elapsed === nothing
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_done receives :skipped" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_noeval.jl"),
                    "x = 1\n",
                )

                done_captured = Ref{Any}(nothing)
                run_single(
                    :cb_noeval;
                    available_tests=Symbol[],
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
                @test info isa TestRunner.TestRunInfo
                @test info.status === :skipped
                @test info.func_symbol === nothing
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_done receives :error on eval failure" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_err.jl"),
                    "function test_cb_err()\n    error(\"intentional failure\")\nend\n",
                )

                done_captured = Ref{Any}(nothing)
                err = try
                    run_single(
                        :cb_err;
                        available_tests=Symbol[],
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
                @test err isa ErrorException
                @test occursin("intentional failure", err.msg)

                # on_test_done was called with :error
                info = done_captured[]
                @test info isa TestRunner.TestRunInfo
                @test info.status === :error
                @test info.error isa ErrorException
                @test info.elapsed isa Float64
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "both callbacks work together" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_both.jl"),
                    "function test_cb_both()\n    @test true\nend\n",
                )

                start_captured = Ref{Any}(nothing)
                done_captured = Ref{Any}(nothing)
                run_single(
                    :cb_both;
                    available_tests=Symbol[],
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),
                    eval_mode=true,
                    test_dir=temp_dir,
                    index=3,
                    total=5,
                    on_test_start=info -> (start_captured[] = info; true),
                    on_test_done=info -> (done_captured[] = info),
                )

                @test start_captured[].status === :pre_eval
                @test start_captured[].index == 3
                @test start_captured[].total == 5
                @test done_captured[].status === :post_eval
                @test done_captured[].index == 3
                @test done_captured[].total == 5
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "callbacks with String spec" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_str.jl"),
                    "function test_cb_str()\n    @test true\nend\n",
                )

                start_captured = Ref{Any}(nothing)
                done_captured = Ref{Any}(nothing)
                run_single(
                    "test_cb_str.jl";
                    available_tests=Symbol[],
                    filename_builder=identity,
                    funcname_builder=identity,
                    eval_mode=true,
                    test_dir=temp_dir,
                    index=1,
                    total=2,
                    on_test_start=info -> (start_captured[] = info; true),
                    on_test_done=info -> (done_captured[] = info),
                )

                @test start_captured[].spec == "test_cb_str.jl"
                @test start_captured[].status === :pre_eval
                @test done_captured[].spec == "test_cb_str.jl"
                @test done_captured[].status === :post_eval
            end
        end

        @testset verbose = VERBOSE showtiming = SHOWTIMING "no callbacks (nothing) preserves original behavior" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_cb_none.jl"),
                    "function test_cb_none()\n    @test true\nend\n",
                )

                # Should not error when callbacks are nothing
                run_single(
                    :cb_none;
                    available_tests=Symbol[],
                    filename_builder=n -> "test_" * String(n),
                    funcname_builder=n -> Symbol(:test_, n),
                    eval_mode=true,
                    test_dir=temp_dir,
                    on_test_start=nothing,
                    on_test_done=nothing,
                )
                @test true
            end
        end
    end

    # ============================================================================
    # INTEGRATION TESTS - Callbacks via run_tests
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Callbacks via run_tests" begin
        @testset verbose = VERBOSE showtiming = SHOWTIMING "on_test_start and on_test_done called for each test" begin
            mktempdir() do temp_dir
                write(
                    joinpath(temp_dir, "test_int_a.jl"),
                    "function test_int_a()\n    @test true\nend\n",
                )
                write(
                    joinpath(temp_dir, "test_int_b.jl"),
                    "function test_int_b()\n    @test true\nend\n",
                )

                start_log = TestRunner.TestRunInfo[]
                done_log = TestRunner.TestRunInfo[]

                CTBase.run_tests(;
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

                @test length(start_log) == 2
                @test length(done_log) == 2

                # Check index/total progression
                @test start_log[1].index == 1
                @test start_log[1].total == 2
                @test start_log[2].index == 2
                @test start_log[2].total == 2

                # Check statuses
                @test all(info -> info.status === :pre_eval, start_log)
                @test all(info -> info.status === :post_eval, done_log)

                # Check elapsed is populated
                @test all(info -> info.elapsed isa Float64, done_log)
            end
        end
    end

    return nothing
end

end # module

# Re-export for TestRunner discovery
test_testrunner() = TestTestRunner.test_testrunner()
