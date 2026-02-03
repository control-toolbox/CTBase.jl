"""
    Descriptions

Description management utilities for CTBase.

This module provides types and functions for working with symbolic descriptions,
including type aliases, manipulation functions, and completion utilities.

# Organization

The Descriptions module is organized into thematic submodules:

- **types.jl**: Core type definitions (DescVarArg, Description)
- **similarity.jl**: Similarity computation and intelligent suggestions
- **display.jl**: Display utilities for descriptions
- **catalog.jl**: Catalog management functions (add, remove)
- **complete.jl**: Description completion utilities

# Public API

## Exported Types
- `DescVarArg`: Variable number of symbols type alias
- `Description`: Tuple of symbols type alias

## Exported Functions
- `add`: Add descriptions to a catalog
- `complete`: Find matching descriptions with intelligent suggestions
- `remove`: Remove symbols from descriptions

See also: [`CTBase`](@ref)
"""
module Descriptions

using DocStringExtensions
using ..Exceptions

# Include submodules
include("types.jl")
include("similarity.jl")
include("display.jl")
include("catalog.jl")
include("complete.jl")
include("remove.jl")

# public API
export DescVarArg, Description
export add, complete, remove

end # module
