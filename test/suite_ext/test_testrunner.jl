struct DummyTestRunnerTag <: CTBase.AbstractTestRunnerTag end

function test_testrunner()
    # ============================================================================
    # UNIT TESTS - TestRunner extension
    # ============================================================================

    @testset "TestRunner extension" begin
        @test Base.get_extension(CTBase, :TestRunner) !== nothing
    end

    @testset "TestRunner stub dispatch" begin
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

        @testset "empty args returns empty with default flags" begin
            (sel, all_flag, dry_flag) = parse_args(String[])
            @test sel == String[]
            @test all_flag == false

            @test dry_flag == false
        end



        @testset "single test name" begin
            (sel, _, _) = parse_args(["utils"])
            @test sel == ["utils"]
        end

        @testset "multiple test names" begin
            (sel, _, _) = parse_args(["utils", "default"])
            @test sel == ["utils", "default"]
        end

        @testset "coverage flags are filtered out" begin
            (sel, _, _) = parse_args(["coverage=true"])
            @test sel == String[]
        end

        @testset "CLI flags -a / --all" begin
            # -a should set run_all=true
            (_, run_all, _) = parse_args(["-a"])
            @test run_all == true

            (_, run_all, _) = parse_args(["--all"])
            @test run_all == true
        end

        @testset "CLI flags -n / --dryrun" begin
            # -n should set dry_run=true
            (_, _, dry_run) = parse_args(["-n"])
            @test dry_run == true

            (_, _, dry_run) = parse_args(["--dryrun"])
            @test dry_run == true
        end
        
        @testset "mixed flags and tests" begin
            (sel, run_all, dry_run) = parse_args(["utils", "-n", "--all"])
            @test sel == ["utils"]
            @test run_all == true
            @test dry_run == true
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
            @testset "Auto-discovery (empty available_tests)" begin
                # Empty args -> run all .jl files (excluding runtests.jl)
                # Names derived as basenames
                sel = select_tests(String[], Symbol[], false, identity; test_dir=temp_dir)
                @test sort(sel) == [:test_core, :test_utils]

                # Run all (-a) -> same result
                sel = select_tests(String[], Symbol[], true, identity; test_dir=temp_dir)
                @test sort(sel) == [:test_core, :test_utils]

                # Globbing: select only utils
                sel = select_tests(["test_utils"], Symbol[], false, identity; test_dir=temp_dir)
                @test sel == [:test_utils]

                # Globbing: pattern matching
                sel = select_tests(["test_c*"], Symbol[], false, identity; test_dir=temp_dir)
                @test sel == [:test_core]
                
                # Globbing: match filename? 
                # candidate=:test_core -> filename="test_core.jl"
                sel = select_tests(["test_core_jl"], Symbol[], false, identity; test_dir=temp_dir)
                # This won't match regex "^test_core_jl$" against "test_core" or "test_core.jl"
                @test isempty(sel)

                sel = select_tests(["test_core.jl"], Symbol[], false, identity; test_dir=temp_dir)
                @test sel == [:test_core]
            end

            # ==========================================================
            # Scenario 2: With available_tests
            # ==========================================================
            @testset "With available_tests" begin
                available = [:utils, :core]
                
                # Note: TestRunner checks if file exists via builder
                # test_utils.jl exists -> :utils is valid
                # test_core.jl exists -> :core is valid
                
                # Empty args -> run all valid available tests
                sel = select_tests(String[], available, false, test_builder_sym; test_dir=temp_dir)
                @test sort(sel) == [:core, :utils]

                # Selection
                sel = select_tests(["utils"], available, false, test_builder_sym; test_dir=temp_dir)
                @test sel == [:utils]

                # Globbing over available names
                # available test :core, file: test_core.jl
                sel = select_tests(["c*"], available, false, test_builder_sym; test_dir=temp_dir)
                @test sel == [:core] 

                # Globbing over filename without extension
                # available test :core, file: test_core.jl
                sel = select_tests(["test_core"], available, false, test_builder_sym; test_dir=temp_dir)
                @test sel == [:core]

                # Builder may return String
                sel = select_tests(["core"], available, false, test_builder_str; test_dir=temp_dir)
                @test sel == [:core]
            end

            @testset "With available_tests (symbol located in subdirectory)" begin
                mkpath(joinpath(temp_dir, "suite_src"))
                touch(joinpath(temp_dir, "suite_src", "test_utils.jl"))

                available = [:utils]

                sel = select_tests(String[], available, false, test_builder_sym; test_dir=temp_dir)
                @test sel == [:utils]
            end

            @testset "available_tests may include directories" begin
                mkpath(joinpath(temp_dir, "suite"))
                touch(joinpath(temp_dir, "suite", "test_a.jl"))
                touch(joinpath(temp_dir, "suite", "test_b.jl"))

                available = TestRunner.TestSpec["suite"]
                sel = select_tests(String[], available, false, identity; test_dir=temp_dir)
                @test sel == ["suite/test_a.jl", "suite/test_b.jl"]

                sel = select_tests(["suite/test_a"], available, false, identity; test_dir=temp_dir)
                @test sel == ["suite/test_a.jl"]
            end
        end
    end

    # ============================================================================
    # EDGE CASES
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Edge cases" begin
        parse_args = TestRunner._parse_test_args
        select_tests = TestRunner._select_tests
        normalize_available = TestRunner._normalize_available_tests

        @testset "mixed case and special characters in test names" begin
            # Test names are converted to Symbols, preserving case
            (sel, _, _) = parse_args(["MyTest", "test_123"])
            @test sel == ["MyTest", "test_123"]
        end

        @testset "available_tests may be a Tuple" begin
            out = normalize_available((:a, "suite_ext/*"))
            @test out == TestRunner.TestSpec[:a, "suite_ext/*"]
        end

        @testset "available_tests may be Vector{Any}" begin
            out = normalize_available(Any[:a, "suite_ext/*"])
            @test out == TestRunner.TestSpec[:a, "suite_ext/*"]
        end

        @testset "order preservation" begin
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
                 sel = select_tests(["z", "a"], [:a, :b, :z], false, identity; test_dir=temp_dir)
                 @test sel == [:a, :z] # candidates order candidate list order
                 
                 # Case 2: Auto-discovery order (filesystem order, filtered)
                 # We can't guarantee FS order, so checking set equality
                 sel = select_tests(["z", "a"], Symbol[], false, identity; test_dir=temp_dir)
                 @test Set(sel) == Set([:z, :a])
            end
        end

        @testset "duplicate selections are preserved" begin
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

        @testset "error when file not found" begin
            # L112: error branch when test file doesn't exist
            err = try
                run_single(
                    :nonexistent_file_xyz123;
                    available_tests = Symbol[],
                    filename_builder = identity,
                    funcname_builder = identity,
                    eval_mode = true,
                    test_dir = mktempdir(),
                )
                nothing
            catch e
                e
            end
            @test err isa ErrorException
            @test occursin("not found", err.msg)
        end

        # Note: Other error branches (L126, L134, L139) are not directly tested
        # because they require Base.include(Main, ...) which causes side effects.
        # They are tested indirectly through normal test execution.
    end

    return nothing
end