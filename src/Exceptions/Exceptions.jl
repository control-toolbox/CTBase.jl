"""
    Exceptions

Enhanced exception system for CTBase with user-friendly error messages.

This module provides enriched exceptions compatible with CTBase but with additional
fields for better error reporting, suggestions, and context.

# Main Features

1. **Enriched Exceptions**: `IncorrectArgument`, `PreconditionError`, etc. with optional fields
2. **User-Friendly Display**: Clear, formatted error messages with emojis and sections
3. **Rich Context**: Detailed information for debugging and problem resolution

# Usage

```julia
using CTBase

# Throw an enriched exception
throw(CTBase.Exceptions.IncorrectArgument(
    "Invalid input value";
    got="-5",
    expected="positive number",
    suggestion="use abs(x) or check input range",
    context="square root calculation"
))
```

# Organization

The Exceptions module is organized into thematic files:

- **types.jl**: Exception type definitions
- **display.jl**: Custom display functions for user-friendly error messages

See also: [`CTBase`](@ref)
"""
module Exceptions

using CTBase

# Type definitions
include("types.jl")

# Display functions
include("display.jl")

# Export public API
export CTException
export IncorrectArgument, PreconditionError, NotImplemented, ParsingError
export AmbiguousDescription, ExtensionError

end # module
