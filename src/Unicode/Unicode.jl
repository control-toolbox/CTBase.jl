"""
    Unicode

Unicode character utilities for CTBase.

This module provides functions for converting integers to Unicode subscript
and superscript characters, useful for mathematical notation and display.
"""
module Unicode

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using ..Exceptions

include("subscripts.jl")
include("superscripts.jl")

# Export public API
export ctindice, ctindices, ctupperscript, ctupperscripts

end # module
