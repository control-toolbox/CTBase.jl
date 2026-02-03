"""
Core building blocks for the Control Toolbox (CT) ecosystem.

This package defines shared types and utilities that are reused by other
packages such as OptimalControl.jl.
"""
module CTBase

using Base: Base
using DocStringExtensions

# ============================================================================ #
# MODULAR ORGANIZATION
# ============================================================================ #

# Exceptions module - enhanced error handling system (must load first)
include(joinpath(@__DIR__, "Exceptions", "Exceptions.jl"))
using .Exceptions

# Core module - fundamental types and utilities
include(joinpath(@__DIR__, "Core", "Core.jl"))
using .Core

# Unicode module - Unicode character utilities
include(joinpath(@__DIR__, "Unicode", "Unicode.jl"))
using .Unicode

# Descriptions module - description management
include(joinpath(@__DIR__, "Descriptions", "Descriptions.jl"))
using .Descriptions

# Extensions module - extension system with tag-based dispatch
include(joinpath(@__DIR__, "Extensions", "Extensions.jl"))
using .Extensions

end
