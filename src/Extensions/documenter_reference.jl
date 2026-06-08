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
