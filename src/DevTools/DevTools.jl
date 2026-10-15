"""
    DevTools

Developer tools for CTBase with tag-based dispatch.

This module provides the extension point infrastructure for internal
control-toolbox development tools: test running, API documentation
generation, documentation helpers, and coverage post-processing.
"""
module DevTools

using DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using ..Exceptions

include("documenter_reference.jl")
include("documentation_helpers.jl")
include("coverage_postprocessing.jl")
include("test_runner.jl")

# Export public API
export automatic_reference_documentation, postprocess_coverage, run_tests
export repl_without_extensions, warnings_without_paths
export AbstractDocumenterReferenceTag, DocumenterReferenceTag
export AbstractCoveragePostprocessingTag, CoveragePostprocessingTag
export AbstractTestRunnerTag, TestRunnerTag

end # module
