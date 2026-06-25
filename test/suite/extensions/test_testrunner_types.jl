module TestTestRunnerTypes

using Test: Test
using CTBase: CTBase
import CTBase.DevTools

const TestRunner = Base.get_extension(CTBase, :TestRunner)

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_testrunner_types()
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

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "TestSpec" begin
        Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "TestSpec is Vector{Union{String, Symbol}}" begin
            spec = TestRunner.TestSpec[:a, "suite/*"]
            Test.@test spec isa Vector{Union{String,Symbol}}
            Test.@test spec == [:a, "suite/*"]
        end
    end

    return nothing
end

end # module

test_testrunner_types() = TestTestRunnerTypes.test_testrunner_types()
