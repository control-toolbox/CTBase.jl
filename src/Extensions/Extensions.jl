"""
    Extensions

Extension system for CTBase with tag-based dispatch.

This module provides the extension point infrastructure used throughout
the CTBase ecosystem, including abstract tags, concrete implementations,
and extension functions.
"""
module Extensions

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using ..Exceptions

# --------------------------------------------------------------------------------------------------
# Documentation extension system
"""
$(TYPEDEF)

Abstract supertype for tags used to select a particular implementation of
`automatic_reference_documentation`.

Concrete subtypes identify a specific backend that provides the actual
documentation generation logic.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.DocumenterReferenceTag() isa CTBase.AbstractDocumenterReferenceTag
true
```
"""
abstract type AbstractDocumenterReferenceTag end

"""
$(TYPEDEF)

Concrete tag type used to dispatch to the `DocumenterReference` extension.

Instances of this type are passed to `automatic_reference_documentation` to
enable the integration with Documenter.jl when the `DocumenterReference`
extension is available.

# Example

```julia-repl
julia> using CTBase

julia> tag = CTBase.DocumenterReferenceTag()
CTBase.DocumenterReferenceTag()
```
"""
struct DocumenterReferenceTag <: AbstractDocumenterReferenceTag end

"""
$(TYPEDSIGNATURES)

Generate API reference documentation pages for one or more modules.

This method is an **extension point**: the default implementation throws an
`CTBase.Exceptions.ExtensionError` unless a backend extension providing the actual
implementation is loaded (e.g. the `DocumenterReference` extension).

# Keyword Arguments

Forwarded to the active backend implementation.

# Throws

- `CTBase.Exceptions.ExtensionError`: If no backend extension is loaded.

# Example

```julia
using CTBase
# Requires DocumenterReference extension to be active
automatic_reference_documentation(
    subdirectory="api",
    primary_modules=[MyModule],
    title="My API"
)
```
"""
function automatic_reference_documentation(::AbstractDocumenterReferenceTag; kwargs...)
    throw(
        Exceptions.ExtensionError(
            :Documenter,
            :Markdown,
            :MarkdownAST;
            feature="automatic documentation generation",
            context="reference generation",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Convenience wrapper for `automatic_reference_documentation` using the
default backend tag.

# Keyword Arguments

Forwarded to `automatic_reference_documentation(DocumenterReferenceTag(); kwargs...)`.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the required backend extension is not loaded.

# Example

```julia
using CTBase
# automatic_reference_documentation(subdirectory="api")
```
"""
function automatic_reference_documentation(; kwargs...)
    return automatic_reference_documentation(DocumenterReferenceTag(); kwargs...)
end

# --------------------------------------------------------------------------------------------------
# Coverage extension system
"""
$(TYPEDEF)

Abstract supertype for tags used to select a particular implementation of
`postprocess_coverage`.

Concrete subtypes identify a specific backend that provides the actual coverage
post-processing logic.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.CoveragePostprocessingTag() isa CTBase.AbstractCoveragePostprocessingTag
true
```
"""
abstract type AbstractCoveragePostprocessingTag end

"""
$(TYPEDEF)

Concrete tag type used to dispatch to the `CoveragePostprocessing` extension.

Instances of this type are passed to `postprocess_coverage` to enable
coverage post-processing when the extension is available.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.CoveragePostprocessingTag() isa CTBase.AbstractCoveragePostprocessingTag
true
```

See also: [`CTBase.Extensions.AbstractCoveragePostprocessingTag`](@ref)
"""
struct CoveragePostprocessingTag <: AbstractCoveragePostprocessingTag end

"""
$(TYPEDSIGNATURES)

Post-process coverage artifacts produced by `Pkg.test(; coverage=true)`.

This is an **extension point**: the default implementation throws an
`CTBase.Exceptions.ExtensionError` unless a backend extension (e.g. `CoveragePostprocessing`)
is loaded.

# Keyword Arguments

- `generate_report::Bool=true`: Whether to generate summary reports.
- `root_dir::String=pwd()`: Project root directory used to locate coverage artifacts.
- `dest_dir::String="coverage"`: Destination directory for coverage artifacts.
- `worst_n_files::Int=20`: Maximum number of lowest-covered files to list in the report.
- `max_uncovered_lines::Int=200`: Maximum number of uncovered lines to display in the report.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the coverage post-processing extension is not loaded.

# Example

```julia
using CTBase
# postprocess_coverage(generate_report=true)
```
"""
function postprocess_coverage(
    ::AbstractCoveragePostprocessingTag;
    generate_report::Bool=true,
    root_dir::String=pwd(),
    dest_dir::String="coverage",
    worst_n_files::Int=20,
    max_uncovered_lines::Int=200,
)
    throw(
        Exceptions.ExtensionError(
            :Coverage;
            feature="coverage analysis and reporting",
            context="coverage postprocessing",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Convenience wrapper for `postprocess_coverage` using the default backend tag.

# Keyword Arguments

Forwarded to `postprocess_coverage(CoveragePostprocessingTag(); kwargs...)`.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the coverage post-processing extension is not loaded.

# Example

```julia
using CTBase
# postprocess_coverage()
```
"""
function postprocess_coverage(; kwargs...)
    return postprocess_coverage(CoveragePostprocessingTag(); kwargs...)
end

# --------------------------------------------------------------------------------------------------
# Test runner extension system
"""
$(TYPEDEF)

Abstract supertype for tags used to select a particular implementation of
`run_tests`.

Concrete subtypes identify a specific backend that provides the actual test
runner logic.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.TestRunnerTag() isa CTBase.AbstractTestRunnerTag
true
```

See also: [`CTBase.Extensions.TestRunnerTag`](@ref)
"""
abstract type AbstractTestRunnerTag end

"""
$(TYPEDEF)

Concrete tag type used to dispatch to the `TestRunner` extension.

Instances of this type are passed to `run_tests` to enable the
extension-based test runner when the extension is available.

# Example

```julia-repl
julia> using CTBase

julia> tag = CTBase.TestRunnerTag()
CTBase.TestRunnerTag()
```

See also: [`CTBase.Extensions.AbstractTestRunnerTag`](@ref)
"""
struct TestRunnerTag <: AbstractTestRunnerTag end

"""
$(TYPEDSIGNATURES)

Run the project test suite using an extension-provided test runner.

This is an **extension point**: the default implementation throws an
`CTBase.Exceptions.ExtensionError` unless a backend extension is loaded.

# Keyword Arguments

Forwarded to the active backend implementation.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the test runner extension is not loaded.

# Example

```julia
using CTBase
# run_tests()
```
"""
function run_tests(::AbstractTestRunnerTag; kwargs...)
    throw(
        Exceptions.ExtensionError(
            :Test; feature="test execution and reporting", context="test running"
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Convenience wrapper for `run_tests` using the default backend tag.

# Keyword Arguments

Forwarded to `run_tests(TestRunnerTag(); kwargs...)`.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the test runner extension is not loaded.

# Example

```julia
using CTBase
# run_tests()
```
"""
function run_tests(; kwargs...)
    return run_tests(TestRunnerTag(); kwargs...)
end

# Export public API
export automatic_reference_documentation, postprocess_coverage, run_tests
export AbstractDocumenterReferenceTag, DocumenterReferenceTag
export AbstractCoveragePostprocessingTag, CoveragePostprocessingTag
export AbstractTestRunnerTag, TestRunnerTag

end # module
