# ==============================================================================
# CTBase Test Runner
# ==============================================================================
#
# See test/README.md for usage instructions (running specific tests, coverage, etc.)
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
module TestOptions
const VERBOSE = true
const SHOWTIMING = true
end
using .TestOptions: VERBOSE, SHOWTIMING

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
    available_tests=(
        "suite/*/test_*",
        :code_quality, 
        "suite_src/*", 
        "suite_ext/*",
        ),
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
