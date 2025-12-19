# ==============================================================================
# CTBase Test Runner
# ==============================================================================
#
# This test runner uses the TestRunner extension (triggered by `using Test`)
# to execute tests with configurable file/function name builders and optional
# test selection via command-line arguments.
#
# ## Running Tests
#
# ### Default (all available tests)
#
#   julia --project -e 'using Pkg; Pkg.test("CTBase")'
#
# ### Run a specific test group
#
#   julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["utils"])'
#   julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["testrunner", "exceptions"])'
#
# Note: 
# - Passing `-a` or `--all` is equivalent to running without arguments.
# - Passing `--dry-run` will print the list of tests that would be run, but not execute them.
#
# ## Coverage Mode
#
# Run tests with code coverage instrumentation:
#
#   julia --project -e '
#       using Pkg; 
#       Pkg.test("CTBase"; coverage=true); 
#       include("test/coverage.jl")
#   '
#
# This produces:
#   - coverage/lcov.info      — LCOV format for CI integration
#   - coverage/cov_report.md  — Human-readable summary with uncovered lines
#   - coverage/cov/           — Archived .cov files
#
# ## Test Groups
#
# Each test group corresponds to a file `test/test_<name>.jl` that defines
# a function `test_<name>()`. The `available_tests` list below controls
# which groups are valid; requests for unlisted groups will error.
#
# ==============================================================================

# Test dependencies
using CTBase
using Aqua
using Documenter

# Trigger loading of optional extensions
using Test
using Markdown
using MarkdownAST
using Coverage

# Optional extension module access (loaded only when the package defines it).
const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)
const TestRunner = Base.get_extension(CTBase, :TestRunner)
const CoveragePostprocessing = Base.get_extension(CTBase, :CoveragePostprocessing)

# Controls nested testset output formatting (used by individual test files)
const VERBOSE = true
const SHOWTIMING = true

# Macro to check if an expression is type-stable and inferred correctly
macro test_inferred(expr)
    q = quote
        try
            @inferred $expr
            @test true
        catch e
            @test false
            println("Error in @inferred: ", e)
        end
    end
    return esc(q)
end

# Run tests using the TestRunner extension
CTBase.run_tests(;
    args=String.(ARGS),
    testset_name="CTBase tests",
    available_tests=(:code_quality, "suite_src/*", "suite_ext/*"),
    filename_builder=name -> "test_$(name).jl",
    funcname_builder=name -> "test_$(name)",
    verbose=VERBOSE,
    showtiming=SHOWTIMING,
    test_dir=@__DIR__,
)

# If running with coverage enabled, remind the user to run the post-processing script
# because .cov files are flushed at process exit and cannot be cleaned up by this script.
if Base.JLOptions().code_coverage != 0
    println(
        """
        ================================================================================
        Coverage files generated. To process them, please run:

            julia --project -e '
                using Pkg; 
                Pkg.test("CTBase"; coverage=true); 
                include("test/coverage.jl")'
            '
        ================================================================================
        """
    )
end
