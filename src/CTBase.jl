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
docstrings(::AbstractString; kwargs...) = throw(CTBase.ExtensionError(:JSON, :HTTP))
function generate_prompt(
    ::AbstractString, ::AbstractString, ::AbstractString, ::AbstractString
)
    throw(CTBase.ExtensionError(:JSON, :HTTP))
end

"""
$(TYPEDEF)

Abstract supertype for identifying different kinds of docstring application tags.

Used as a dispatch mechanism to select the appropriate implementation for a docstrings-related application.

# Example

```julia-repl
julia> CTBase.AbstractDocstringsAppTag <: AbstractDocstringsAppTag
true
```
"""
abstract type AbstractDocstringsAppTag end

"""
$(TYPEDEF)

Concrete tag type used to identify the Julia Docstrings Generator application.

# Fields

This struct has no fields.

# Example

```julia-repl
julia> tag = DocstringsAppTag()
DocstringsAppTag()
```
"""
struct DocstringsAppTag <: AbstractDocstringsAppTag end

doc_app(::AbstractDocstringsAppTag) = throw(CTBase.ExtensionError(:JSON, :HTTP))
doc_app() = doc_app(DocstringsAppTag())

#
include("exception.jl")
include("description.jl")
include("default.jl")
include("utils.jl")

end
