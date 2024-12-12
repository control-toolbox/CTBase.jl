"""
[`CTBase`](@ref) module.

Lists all the imported modules and packages:

$(IMPORTS)

List of all the exported names:

$(EXPORTS)
"""
module CTBase

import Base
using DocStringExtensions
using DifferentiationInterface:
    AutoForwardDiff,
    derivative,
    gradient,
    jacobian,
    prepare_derivative,
    prepare_gradient,
    prepare_jacobian
import ForwardDiff
using Interpolations: linear_interpolation, Line, Interpolations # For default interpolation

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
