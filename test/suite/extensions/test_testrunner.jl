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
