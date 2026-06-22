"""
High-level orchestration utilities.

This module provides the glue between **actions** (problem-level options) and
**strategies** (algorithmic components) by handling option routing,
disambiguation, and helper builders.

# Public API
- `route_all_options`: Strategy-aware option router with disambiguation support
- `extract_strategy_ids`, `build_strategy_to_family_map`, `build_option_ownership_map`: Helpers used by the router
- `build_strategy_from_resolved`, `option_names_from_resolved`: Builders based on resolved method information
- `ResolvedMethod`: Struct containing resolved method information from disambiguation
- `resolve_method`: Function that resolves method tokens to strategy families and IDs

See also: `Options`, `Strategies`
"""
module Orchestration

# Imports
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
import CTBase.Exceptions

# CTBase modules
using ..Options
using ..Strategies

# Submodules
include(joinpath(@__DIR__, "disambiguation.jl"))
include(joinpath(@__DIR__, "builders.jl"))
include(joinpath(@__DIR__, "routing.jl"))

# Public API
export route_all_options
export extract_strategy_ids, build_strategy_to_family_map, build_option_ownership_map
export build_strategy_from_resolved, option_names_from_resolved
export ResolvedMethod, resolve_method

end # module Orchestration
