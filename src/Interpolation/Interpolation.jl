"""
    Interpolation

Interpolation utilities for the Control Toolbox (CT) ecosystem.

# Public API
- `ctinterpolate`: linear interpolation with flat extrapolation
- `ctinterpolate_constant`: piecewise-constant (steppost) interpolation
"""
module Interpolation

import DocStringExtensions: TYPEDSIGNATURES

include(joinpath(@__DIR__, "ctinterpolate.jl"))

export ctinterpolate, ctinterpolate_constant

end # module Interpolation
