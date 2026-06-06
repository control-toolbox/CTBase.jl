"""
$(TYPEDSIGNATURES)

Remove symbols from a description tuple.

# Arguments
- `x::Description`: The source description.
- `y::Description`: The symbols to remove from `x`.

# Returns
- `Tuple{Vararg{Symbol}}`: The set difference of `x` and `y` as a tuple (symbols in `x` not in `y`).

# Example

```julia-repl
julia> using CTBase

julia> CTBase.remove((:a, :b, :c), (:a,))
(:b, :c)
```

See also: [`CTBase.Descriptions.add`](@ref), [`CTBase.Descriptions.complete`](@ref)
"""
function remove(x::Description, y::Description)::Tuple{Vararg{Symbol}}
    return tuple(setdiff(x, y)...)
end
