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
include("exception.jl")
include("description.jl")
include("default.jl")
include("utils.jl")

end
