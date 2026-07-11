"""
    Interpolation

Interpolation utilities for the Control Toolbox (CT) ecosystem.

# Public API
- `ctinterpolate`: linear interpolation with flat extrapolation
- `ctinterpolate_constant`: piecewise-constant (steppost) interpolation
"""
module Interpolation

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES

include(joinpath(@__DIR__, "types.jl"))
include(joinpath(@__DIR__, "ctinterpolate.jl"))
include(joinpath(@__DIR__, "display.jl"))

export ctinterpolate, ctinterpolate_constant, Interpolant

end # module Interpolation
