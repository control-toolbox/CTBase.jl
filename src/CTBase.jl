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
docstrings(path::AbstractString; kwargs...) = throw(CTBase.ExtensionError(:JSON, :HTTP))

abstract type AbstractDocstringsAppTag end
struct DocstringsAppTag <: AbstractDocstringsAppTag end
docstrings_app(::AbstractDocstringsAppTag) = throw(CTBase.ExtensionError(:JSON, :HTTP))
docstrings_app() = docstrings_app(DocstringsAppTag())

#
include("exception.jl")
include("description.jl")
include("default.jl")
include("utils.jl")

end
