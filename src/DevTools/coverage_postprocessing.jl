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

See also: [`CTBase.DevTools.AbstractCoveragePostprocessingTag`](@ref)
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
    return throw(
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
