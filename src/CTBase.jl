"""
Core building blocks for the Control Toolbox (CT) ecosystem.

This package defines shared types and utilities that are reused by other
packages such as OptimalControl.jl.
"""
module CTBase

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES

# ============================================================================ #
# MODULAR ORGANIZATION
# ============================================================================ #

# Core module - fundamental types and utilities (must load first)
include(joinpath(@__DIR__, "Core", "Core.jl"))
using .Core

# Exceptions module - enhanced error handling system
include(joinpath(@__DIR__, "Exceptions", "Exceptions.jl"))
using .Exceptions

# Unicode module - Unicode character utilities
include(joinpath(@__DIR__, "Unicode", "Unicode.jl"))
using .Unicode

# Descriptions module - description management
include(joinpath(@__DIR__, "Descriptions", "Descriptions.jl"))
using .Descriptions

# Extensions module - extension system with tag-based dispatch
include(joinpath(@__DIR__, "Extensions", "Extensions.jl"))
using .Extensions

# Interpolation module - interpolation utilities
include(joinpath(@__DIR__, "Interpolation", "Interpolation.jl"))
using .Interpolation

end
