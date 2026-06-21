"""
    DevTools

Developer tools for CTBase with tag-based dispatch.

This module provides the extension point infrastructure for internal
control-toolbox development tools: test running, API documentation
generation, and coverage post-processing.
"""
module DevTools

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using ..Exceptions

include("documenter_reference.jl")
include("coverage_postprocessing.jl")
include("test_runner.jl")

# Export public API
export automatic_reference_documentation, postprocess_coverage, run_tests
export AbstractDocumenterReferenceTag, DocumenterReferenceTag
export AbstractCoveragePostprocessingTag, CoveragePostprocessingTag
export AbstractTestRunnerTag, TestRunnerTag

end # module
