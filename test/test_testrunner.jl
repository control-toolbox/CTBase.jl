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

        @testset "empty args returns empty" begin
            @test parse_args(String[]) == Symbol[]
        end

        @testset "single test name is converted to Symbol" begin
            @test parse_args(["utils"]) == [:utils]
        end

        @testset "multiple test names are converted to Symbols" begin
            @test parse_args(["utils", "default", "exceptions"]) == [:utils, :default, :exceptions]
        end

        @testset "coverage flags are filtered out" begin
            # All coverage-related flags should be ignored
            @test parse_args(["coverage=true"]) == Symbol[]
            @test parse_args(["coverage=false"]) == Symbol[]
            @test parse_args(["coverage"]) == Symbol[]
            @test parse_args(["--coverage"]) == Symbol[]
        end

        @testset "coverage flags are filtered while keeping test names" begin
            @test parse_args(["utils", "coverage=true"]) == [:utils]
            @test parse_args(["coverage=true", "utils", "default"]) == [:utils, :default]
            @test parse_args(["utils", "--coverage", "default"]) == [:utils, :default]
        end

        @testset "'all' is preserved as a symbol" begin
            @test parse_args(["all"]) == [:all]
            @test parse_args(["all", "coverage=true"]) == [:all]
        end
    end

    # ============================================================================
    # UNIT TESTS - _select_tests
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "_select_tests" begin
        select_tests = TestRunner._select_tests

        available = [:code_quality, :default, :utils, :integration]

        @testset "no selections returns all available tests" begin
            # When no CLI args, return all available tests
            @test select_tests(Symbol[], available) == available
        end

        @testset "empty available_tests with selections returns selections" begin
            # When available_tests is empty, all selections are allowed
            @test select_tests([:foo, :bar], Symbol[]) == [:foo, :bar]
        end

        @testset ":all returns all available tests" begin
            # :all should return the full available_tests list
            @test select_tests([:all], available) == available
        end

        @testset ":all with empty available returns selections" begin
            # Edge case: :all with no available_tests
            @test select_tests([:all], Symbol[]) == [:all]
        end

        @testset "valid selection returns that selection" begin
            @test select_tests([:utils], available) == [:utils]
            @test select_tests([:utils, :default], available) == [:utils, :default]
        end

        @testset "invalid selection throws error with helpful message" begin
            # When a selection is not in available_tests, error with guidance
            err = try
                select_tests([:nonexistent], available)
                nothing
            catch e
                e
            end
            @test err isa ErrorException
            @test occursin("nonexistent", err.msg)
            @test occursin("available_tests", err.msg)
        end
    end

    # ============================================================================
    # EDGE CASES
    # ============================================================================

    @testset verbose = VERBOSE showtiming = SHOWTIMING "Edge cases" begin
        parse_args = TestRunner._parse_test_args
        select_tests = TestRunner._select_tests

        @testset "mixed case and special characters in test names" begin
            # Test names are converted to Symbols, preserving case
            @test parse_args(["MyTest", "test_123"]) == [:MyTest, :test_123]
        end

        @testset "order preservation" begin
            # Selections should preserve order
            @test parse_args(["z", "a", "m"]) == [:z, :a, :m]
            @test select_tests([:z, :a], [:a, :b, :z]) == [:z, :a]
        end

        @testset "duplicate selections are preserved" begin
            # Duplicates are not filtered (caller's responsibility)
            @test parse_args(["utils", "utils"]) == [:utils, :utils]
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