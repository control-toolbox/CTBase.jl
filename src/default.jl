"""
$(TYPEDSIGNATURES)

Returns the default value for the display flag.

This function is used internally to determine whether output should be printed during execution.

# Returns

- `::Bool`: The default value `true`, indicating that output is displayed.

# Example

```julia-repl
julia> __display()
true
```
"""
__display()::Bool = true
