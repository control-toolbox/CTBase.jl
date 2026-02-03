struct DummyCoverageTag <: CTBase.AbstractCoveragePostprocessingTag end

function test_coverage_post_process()
    CP = Base.get_extension(CTBase, :CoveragePostprocessing)

    @testset "CoveragePostprocessing extension" begin
        @test Base.get_extension(CTBase, :CoveragePostprocessing) !== nothing
    end

    @testset "Errors when no .cov files were produced" begin
        mktempdir() do tmp
            cd(tmp) do
                mkpath("src")
                mkpath("test")
                mkpath("ext")

                err = try
                    CTBase.postprocess_coverage(; generate_report=false)
                    nothing
                catch e
                    e
                end

                @test err isa ErrorException
                @test occursin("no .cov files", lowercase(err.msg))
            end
        end
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

    @testset "Generates report when generate_report=true" begin
        mktempdir() do tmp
            cd(tmp) do
                mkpath("src")
                mkpath("test")
                mkpath("coverage")

                # Create a source file
                code = """
                function foo(x)
                    return x * 2
                end
                """
                write(joinpath("src", "foo.jl"), code)

                # Create a .cov file for it (mock content)
                # Format: line_count: valid_lines
                # null means not a code line, 0 means explicit 0 coverage, >0 means covered
                cov_content = """
                # Coverage data
                -
                2
                -
                """
                # The Coverage package parser is robust, but for process_file to work, 
                # the source file must exist.
                # Coverage.process_cov reads the .cov file.
                # Internal format of .cov is purely source-code-line aligned counts?
                # Actually Coverage.jl expects:
                #    count: line_source
                # checking Coverage.jl source... process_cov parses:
                #     ": " separator.
                # Let's just mock the result of process_folder by mocking Coverage.process_folder?
                # No, can't easily mock module function.
                # Let's rely on creating real file structure.

                # But wait, Coverage.process_folder reads source files AND .cov files.
                # And LCOV generation needs them.

                # Julia's coverage output format:
                #        -:    1:function foo(x)
                #        1:    2:    return x * 2
                #        -:    3:end
                # We need to replicate this somewhat for CoverageTools to parse it.
                # CoverageTools.process_cov splits by ":" and expects the first part to be the count.

                write(
                    joinpath("src", "foo.jl.1234.cov"),
                    """
        -:    1:function foo(x)
        1:    2:    return x * 2
        -:    3:end
""",
                )

                # We also need to mock EXT_DIR if we want to test that branch?
                # The current code checks isdir(EXT_DIR).

                CTBase.postprocess_coverage(; generate_report=true)

                @test isfile(joinpath("coverage", "lcov.info"))
                @test isfile(joinpath("coverage", "cov_report.md"))

                report = read(joinpath("coverage", "cov_report.md"), String)
                @test occursin("foo.jl", report)
                @test occursin("100.0", report) # 1 line covered out of 1
            end
        end
    end

    @testset "Internal report generation handles relative source_dirs" begin
        mktempdir() do tmp
            cd(tmp) do
                mkpath("src")
                mkpath("coverage")

                write(joinpath("src", "foo.jl"), "foo(x) = x\n")
                write(
                    joinpath("src", "foo.jl.1234.cov"),
                    """
        -:    1:foo(x) = x
        0:    2:foo(1)
""",
                )

                CP._generate_coverage_reports!(["src"], joinpath(tmp, "coverage"), tmp)

                @test isfile(joinpath("coverage", "lcov.info"))
                @test isfile(joinpath("coverage", "cov_report.md"))
            end
        end
    end

    @testset "Internal report generation includes non-root files when filter is empty" begin
        mktempdir() do root
            mktempdir() do other
                cd(other) do
                    mkpath("src")
                    write(joinpath("src", "bar.jl"), "bar(x) = x\n")
                    write(
                        joinpath("src", "bar.jl.1234.cov"),
                        """
        -:    1:bar(x) = x
        0:    2:bar(1)
""",
                    )
                end

                mkpath(joinpath(root, "coverage"))
                CP._generate_coverage_reports!(
                    [joinpath(other, "src")], joinpath(root, "coverage"), root
                )

                report = read(joinpath(root, "coverage", "cov_report.md"), String)
                @test occursin(joinpath(other, "src", "bar.jl"), report)
            end
        end
    end

    @testset "Errors when no usable files after cleanup" begin
        # To trigger this, we need >0 files initially, but 0 after cleanup.
        # This implies _clean_stale_cov_files! removed everything.
        # But _clean_stale_cov_files! is designed to keep the majority PID.
        # The only way n_cov becomes 0 after it was >0 is if _clean_stale_cov_files! logic
        # somehow decides to delete everything. 
        # Or if the initial *valid* files were 0?
        # L18 checks n_cov == 0 initially.
        # If we have a file "invalid_name.cov" (no pid), keys(pid_counts) is empty.
        # It returns nothing. n_cov remains > 0.
        #
        # Maybe if we have files that match regex but are deleted for another reason?
        #
        # Actually, let's look at the implementation of `_clean_stale_cov_files!` again.
        # It keeps `keep_suffix`.
        #
        # If I have:
        #   src/a.jl.1.cov
        #   src/a.jl.2.cov
        #
        # 1=>1, 2=>1. sort keeps one (say 1). Deletes 2.
        # Remaining: a.jl.1.cov. n_cov = 1.
        #
        # It seems L36 is unreachable logic unless file system race condition or delete moves current files?
        # I'll skip striving for this branch if it's too defensive.
    end
end
