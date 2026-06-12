module TestTestRunnerExecution

using Test: Test
using CTBase: CTBase
import CTBase.Exceptions

const TestRunner = Base.get_extension(CTBase, :TestRunner)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_testrunner_execution()
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

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "TestRunner: file exists then disappears" begin
        Test.@test TestRunner !== nothing
        mktempdir() do tmp
            # Create a test file that will be deleted before execution
            test_file = joinpath(tmp, "phantom_test.jl")
            touch(test_file)

            # Delete the file before calling _run_single_test
            rm(test_file)

            err = try
                TestRunner._run_single_test(
                    :phantom_test;
                    filename_builder=identity,
                    funcname_builder=identity,
                    eval_mode=false,
                    test_dir=tmp,
                )
                nothing
            catch e
                e
            end

            Test.@test err isa CTBase.Exceptions.IncorrectArgument
            Test.@test occursin("not found", err.msg)
        end
    end

    return nothing
end

end # module

test_testrunner_execution() = TestTestRunnerExecution.test_testrunner_execution()
