"""
    Exceptions

Enhanced exception system for CTBase with user-friendly error messages.

This module provides enriched exceptions compatible with CTBase but with additional
fields for better error reporting, suggestions, and context.

# Main Features

1. **Enriched Exceptions**: `IncorrectArgument`, `UnauthorizedCall`, etc. with optional fields
2. **User-Friendly Display**: Clear, formatted error messages with emojis and sections
3. **Stacktrace Control**: Toggle between full Julia stacktraces and clean user display

# Usage

```julia
using CTBase

# Throw enriched exceptions
throw(CTBase.Exceptions.IncorrectArgument(
    "Invalid criterion",
    got=":invalid",
    expected=":min or :max",
    suggestion="Use objective!(ocp, :min, ...) or objective!(ocp, :max, ...)"
))

# Control stacktrace display
CTBase.set_show_full_stacktrace!(true)   # Show full Julia stacktraces
CTBase.set_show_full_stacktrace!(false)  # User-friendly display (default)
```

# Organization

The Exceptions module is organized into thematic files:

- **config.jl**: Global configuration for stacktrace display
- **types.jl**: Exception type definitions
- **display.jl**: Custom display functions for user-friendly error messages

# Public API

## Exported Types
- `CTException`: Abstract base type
- `IncorrectArgument`: Invalid argument exception
- `UnauthorizedCall`: Unauthorized call exception
- `NotImplemented`: Unimplemented interface exception
- `ParsingError`: Parsing error exception
- `AmbiguousDescription`: Ambiguous description exception
- `ExtensionError`: Missing extension dependency exception

## Exported Functions
- `set_show_full_stacktrace!`: Control stacktrace display
- `get_show_full_stacktrace`: Get current stacktrace setting

See also: [`CTBase`](@ref)
"""
module Exceptions

using CTBase

# Configuration
include("config.jl")

# Type definitions
include("types.jl")

# Display functions
include("display.jl")

# Export public API
export CTException
export IncorrectArgument, UnauthorizedCall, NotImplemented, ParsingError
export AmbiguousDescription, ExtensionError
export set_show_full_stacktrace!, get_show_full_stacktrace

end # module
