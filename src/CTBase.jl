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

# Options module - generic option handling
include(joinpath(@__DIR__, "Options", "Options.jl"))
using .Options

# Strategies module - generic strategy contract and registry
include(joinpath(@__DIR__, "Strategies", "Strategies.jl"))
using .Strategies

# Orchestration module - option routing and disambiguation
include(joinpath(@__DIR__, "Orchestration", "Orchestration.jl"))
using .Orchestration

# Traits module - trait types and trait-based dispatch (moved from CTFlows)
include(joinpath(@__DIR__, "Traits", "Traits.jl"))
using .Traits

# Data module - vector fields and Hamiltonians with traits (moved from CTFlows)
include(joinpath(@__DIR__, "Data", "Data.jl"))
using .Data

# Differentiation module - AD backend strategies (moved from CTFlows)
include(joinpath(@__DIR__, "Differentiation", "Differentiation.jl"))
using .Differentiation

# Unicode module - Unicode character utilities
include(joinpath(@__DIR__, "Unicode", "Unicode.jl"))
using .Unicode

# Descriptions module - description management
include(joinpath(@__DIR__, "Descriptions", "Descriptions.jl"))
using .Descriptions

# DevTools module - developer tools with tag-based dispatch
include(joinpath(@__DIR__, "DevTools", "DevTools.jl"))
using .DevTools

# Interpolation module - interpolation utilities
include(joinpath(@__DIR__, "Interpolation", "Interpolation.jl"))
using .Interpolation

end
