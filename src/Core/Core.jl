"""
    Core

Fundamental types, constants, and utilities for CTBase.

This module contains the core building blocks used throughout the CTBase
ecosystem, including type aliases and internal utilities.
"""
module Core

using DocStringExtensions

# --------------------------------------------------------------------------------------------------
# Type aliases and constants
"""
Type alias for a real number.

This constant is primarily meant as a short, semantic alias when writing APIs
that accept real-valued quantities.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.ctNumber === Real
true
```
"""
const ctNumber = Real

# --------------------------------------------------------------------------------------------------
# Internal utilities
"""
$(TYPEDSIGNATURES)

Return the default value of the display flag.

This internal utility is used to decide whether output should be shown during
execution.

# Returns

- `Bool`: The default value `true`, indicating that output is displayed.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.__display()
true
```
"""
__display()::Bool = true

# Export public API
export ctNumber

end # module
