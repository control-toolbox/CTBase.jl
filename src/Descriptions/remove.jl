"""
$(TYPEDSIGNATURES)

Remove symbols from a description tuple.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.remove((:a, :b, :c), (:a,))
(:b, :c)
```
"""
function remove(x::Description, y::Description)::Tuple{Vararg{Symbol}}
    return tuple(setdiff(x, y)...)
end
