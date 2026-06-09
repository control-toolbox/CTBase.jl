module TestTestRunnerArgParsing

import Test
import CTBase
import CTBase.Exceptions

const TestRunner = Base.get_extension(CTBase, :TestRunner)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_testrunner_arg_parsing()
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

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_normalize_available_tests" begin
        normalize_available = TestRunner._normalize_available_tests

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
    end

    return nothing
end

end # module

test_testrunner_arg_parsing() = TestTestRunnerArgParsing.test_testrunner_arg_parsing()
