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

```@example
julia> const ctNumber = Real
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
function automatic_reference_documentation(::AbstractDocumenterReferenceTag; kwargs...)
    throw(CTBase.ExtensionError(:Documenter, :Markdown, :MarkdownAST))
end
function automatic_reference_documentation(; kwargs...)
    automatic_reference_documentation(DocumenterReferenceTag(); kwargs...)
end

#
include("exception.jl")
include("description.jl")
include("default.jl")
include("utils.jl")

end
