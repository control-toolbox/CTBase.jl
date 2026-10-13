"""
Type alias for a real number.

This constant is primarily meant as a short, semantic alias when writing APIs
that accept real-valued quantities.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.Core.ctNumber === Real
true
```
"""
const ctNumber = Real
