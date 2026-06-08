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
