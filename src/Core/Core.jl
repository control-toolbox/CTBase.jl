"""
    Core

Fundamental types, constants, and utilities for CTBase.

This module contains the core building blocks used throughout the CTBase
ecosystem, including type aliases and internal utilities.
"""
module Core

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES

include("types.jl")
include("utils.jl")

# Export public API
export ctNumber

end # module
