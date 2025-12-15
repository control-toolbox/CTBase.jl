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
# ### Default (all enabled tests)
#
#   julia --project -e 'using Pkg; Pkg.test("CTBase")'
#
# ### Run a specific test group
#
#   julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["utils"])'
#   julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["testrunner", "exceptions"])'
#
# ### Run all tests (including those not enabled by default)
#
#   julia --project -e 'using Pkg; Pkg.test("CTBase"; test_args=["all"])'
#
# ## Coverage Mode
#
# Run tests with code coverage instrumentation:
#
#   julia --project=@. -e 'using Pkg; Pkg.test("CTBase"; coverage=true, test_args=["all"])'
#
# After tests complete, generate the coverage report by running:
#
#   julia --project=@. -e 'include("test/coverage.jl")'
#
# This produces:
#   - coverage/lcov.info      — LCOV format for CI integration
#   - coverage/llm_report.md  — Human-readable summary with uncovered lines
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
    testset_name = "CTBase tests",
    available_tests = [
        :code_quality, 
        :default, 
        :description, 
        :exceptions, 
        :utils, 
        :documenter_reference, 
        :integration,
        :coverage_post_process,
        :testrunner,
    ],
    filename_builder = name -> Symbol(:test_, name),
    funcname_builder = name -> Symbol(:test_, name),
    verbose = VERBOSE,
    showtiming = SHOWTIMING,
)