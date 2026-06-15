"""
    Core

Fundamental types, constants, and utilities for CTBase.

This module contains the core building blocks used throughout the CTBase
ecosystem, including type aliases and internal utilities.
"""
module Core

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES

include("types.jl")
include("tags.jl")
include("default.jl")

# Private utilities
include("function_utils.jl")
include("macros.jl")

# Public utilities
include("matrix_utils.jl")
include("display.jl")

# Export public API
export ctNumber, matrix2vec, to_out_of_place, @ensure

end # module
