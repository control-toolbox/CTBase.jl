"""
Core building blocks for the Control Toolbox (CT) ecosystem.

This package defines shared types and utilities that are reused by other
packages such as OptimalControl.jl.
"""
module CTBase

using Base: Base
using DocStringExtensions

# --------------------------------------------------------------------------------------------------
# Aliases for types
"""
Type alias for a real number.

This constant is primarily meant as a short, semantic alias when writing APIs
that accept real-valued quantities.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.ctNumber === Real
true
```
"""
const ctNumber = Real

#
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
[`ExtensionError`](@ref) unless a backend extension providing the actual
implementation is loaded (e.g. the `DocumenterReference` extension).

# Keyword Arguments

Forwarded to the active backend implementation.

# Throws

- [`ExtensionError`](@ref): If no backend extension is loaded.
"""
function automatic_reference_documentation(::AbstractDocumenterReferenceTag; kwargs...)
    throw(CTBase.ExtensionError(:Documenter, :Markdown, :MarkdownAST))
end

"""
$(TYPEDSIGNATURES)

Convenience wrapper for [`automatic_reference_documentation`](@ref) using the
default backend tag.

# Keyword Arguments

Forwarded to `automatic_reference_documentation(DocumenterReferenceTag(); kwargs...)`.

# Throws

- [`ExtensionError`](@ref): If the required backend extension is not loaded.
"""
function automatic_reference_documentation(; kwargs...)
    automatic_reference_documentation(DocumenterReferenceTag(); kwargs...)
end


"""
$(TYPEDEF)

Abstract supertype for tags used to select a particular implementation of
[`postprocess_coverage`](@ref).

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

Instances of this type are passed to [`postprocess_coverage`](@ref) to enable
coverage post-processing when the extension is available.
"""
struct CoveragePostprocessingTag <: AbstractCoveragePostprocessingTag end

"""
$(TYPEDSIGNATURES)

Post-process coverage artifacts produced by `Pkg.test(; coverage=true)`.

This is an **extension point**: the default implementation throws an
[`ExtensionError`](@ref) unless a backend extension (e.g. `CoveragePostprocessing`)
is loaded.

# Keyword Arguments

- `generate_report::Bool=true`: Whether to generate summary reports.
- `root_dir::String=pwd()`: Project root directory used to locate coverage artifacts.

# Throws

- [`ExtensionError`](@ref): If the coverage post-processing extension is not loaded.
"""
function postprocess_coverage(
    ::AbstractCoveragePostprocessingTag;
    generate_report::Bool = true,
    root_dir::String = pwd(),
)
    throw(CTBase.ExtensionError(:Coverage))
end

"""
$(TYPEDSIGNATURES)

Convenience wrapper for [`postprocess_coverage`](@ref) using the default backend tag.

# Keyword Arguments

Forwarded to `postprocess_coverage(CoveragePostprocessingTag(); kwargs...)`.

# Throws

- [`ExtensionError`](@ref): If the coverage post-processing extension is not loaded.
"""
function postprocess_coverage(; kwargs...)
    postprocess_coverage(CoveragePostprocessingTag(); kwargs...)
end


"""
$(TYPEDEF)

Abstract supertype for tags used to select a particular implementation of
[`run_tests`](@ref).

Concrete subtypes identify a specific backend that provides the actual test
runner logic.
"""
abstract type AbstractTestRunnerTag end

"""
$(TYPEDEF)

Concrete tag type used to dispatch to the `TestRunner` extension.

Instances of this type are passed to [`run_tests`](@ref) to enable the
extension-based test runner when the extension is available.
"""
struct TestRunnerTag <: AbstractTestRunnerTag end

"""
$(TYPEDSIGNATURES)

Run the project test suite using an extension-provided test runner.

This is an **extension point**: the default implementation throws an
[`ExtensionError`](@ref) unless a backend extension is loaded.

# Keyword Arguments

Forwarded to the active backend implementation.

# Throws

- [`ExtensionError`](@ref): If the test runner extension is not loaded.
"""
function run_tests(::AbstractTestRunnerTag; kwargs...)
    throw(CTBase.ExtensionError(:Test))
end

"""
$(TYPEDSIGNATURES)

Convenience wrapper for [`run_tests`](@ref) using the default backend tag.

# Keyword Arguments

Forwarded to `run_tests(TestRunnerTag(); kwargs...)`.

# Throws

- [`ExtensionError`](@ref): If the test runner extension is not loaded.
"""
function run_tests(; kwargs...)
    run_tests(TestRunnerTag(); kwargs...)
end

#
include("exception.jl")
include("description.jl")
include("default.jl")
include("utils.jl")

end
