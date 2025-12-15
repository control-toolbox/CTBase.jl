struct DummyCoverageTag <: CTBase.AbstractCoveragePostprocessingTag end

function test_coverage_post_process()

    @testset "CoveragePostprocessing extension" begin
        @test Base.get_extension(CTBase, :CoveragePostprocessing) !== nothing
    end

    @testset "Stub dispatch remains available" begin
        err = try
            CTBase.postprocess_coverage(DummyCoverageTag())
            nothing
        catch e
            e
        end

        @test err isa CTBase.ExtensionError
        @test err.weakdeps == (:Coverage,)
    end

    @testset "Post-process moves .cov files" begin
        mktempdir() do tmp
            cd(tmp) do
                mkpath("src")
                mkpath("test")
                mkpath("ext")

                touch(joinpath("src", "a.jl.111.cov"))
                touch(joinpath("src", "b.jl.111.cov"))
                touch(joinpath("test", "t.jl.111.cov"))

                touch(joinpath("src", "old.jl.222.cov"))

                CTBase.postprocess_coverage(; generate_report=false)

                @test isempty(filter(f -> endswith(f, ".cov"), readdir("src")))
                @test isempty(filter(f -> endswith(f, ".cov"), readdir("test")))
                @test isempty(filter(f -> endswith(f, ".cov"), readdir("ext")))

                @test isfile(joinpath("coverage", "cov", "a.jl.111.cov"))
                @test isfile(joinpath("coverage", "cov", "b.jl.111.cov"))
                @test isfile(joinpath("coverage", "cov", "t.jl.111.cov"))
                @test !isfile(joinpath("coverage", "cov", "old.jl.222.cov"))
            end
        end
    end

    @testset "Errors when no .cov files exist" begin
        mktempdir() do tmp
            cd(tmp) do
                mkpath("src")
                mkpath("test")
                mkpath("ext")
                @test_throws ErrorException CTBase.postprocess_coverage(; generate_report=false)
            end
        end
    end
end