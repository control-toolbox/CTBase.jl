module TestCoverageHelpers

using Test: Test
using CTBase: CTBase
using Coverage: Coverage

const CP = Base.get_extension(CTBase, :CoveragePostprocessing)

const VERBOSE = isdefined(Main, :TestData) ? Main.TestData.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestData) ? Main.TestData.SHOWTIMING : true

function test_coverage_helpers()
    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_reset_coverage_dir" begin
        mktempdir() do temp_dir
            cov_dir = joinpath(temp_dir, "coverage")
            cov_storage_dir = joinpath(temp_dir, "cov")
            mkpath(cov_dir)
            touch(joinpath(cov_dir, "test.jl.123.cov"))

            redirect_stdout(devnull) do
                return CP._reset_coverage_dir(cov_dir, cov_storage_dir)
            end
            Test.@test !isdir(cov_dir)
            Test.@test isdir(cov_storage_dir)
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_count_cov_files" begin
        mktempdir() do temp_dir
            # Create some .cov files
            touch(joinpath(temp_dir, "test1.jl.123.cov"))
            touch(joinpath(temp_dir, "test2.jl.456.cov"))
            touch(joinpath(temp_dir, "readme.md"))  # Should be ignored

            count = CP._count_cov_files([temp_dir])
            Test.@test count == 2
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_clean_stale_cov_files!" begin
        mktempdir() do temp_dir
            # Create .cov files with same PID (should be kept)
            touch(joinpath(temp_dir, "test1.jl.123.cov"))
            touch(joinpath(temp_dir, "test2.jl.123.cov"))
            touch(joinpath(temp_dir, "readme.md"))

            # Clean should keep files with same PID
            CP._clean_stale_cov_files!([temp_dir])
            Test.@test isfile(joinpath(temp_dir, "test1.jl.123.cov"))
            Test.@test isfile(joinpath(temp_dir, "test2.jl.123.cov"))
            Test.@test isfile(joinpath(temp_dir, "readme.md"))
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_collect_and_move_cov_files!" begin
        mktempdir() do temp_dir
            src_dir = joinpath(temp_dir, "src")
            cov_dir = joinpath(temp_dir, "coverage")
            mkpath(src_dir)
            mkpath(cov_dir)

            # Create .cov files in src
            touch(joinpath(src_dir, "test1.jl.123.cov"))
            touch(joinpath(src_dir, "test2.jl.456.cov"))

            # Collect and move
            CP._collect_and_move_cov_files!([src_dir], cov_dir)

            # Files should be moved to cov_dir
            Test.@test !isfile(joinpath(src_dir, "test1.jl.123.cov"))
            Test.@test !isfile(joinpath(src_dir, "test2.jl.456.cov"))
            Test.@test isfile(joinpath(cov_dir, "test1.jl.123.cov"))
            Test.@test isfile(joinpath(cov_dir, "test2.jl.456.cov"))
        end
    end

    Test.@testset verbose = VERBOSE showtiming = SHOWTIMING "_get_pid_suffix" begin
        # Test that _get_pid_suffix extracts PID from file path
        suffix = CP._get_pid_suffix("src/test.jl.12345.cov")
        Test.@test suffix == "12345"

        # Test with no PID suffix
        suffix_empty = CP._get_pid_suffix("src/test.jl.cov")
        Test.@test suffix_empty == ""
    end

    return nothing
end

end # module

test_coverage_helpers() = TestCoverageHelpers.test_coverage_helpers()
