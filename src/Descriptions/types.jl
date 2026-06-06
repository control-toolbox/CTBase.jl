# Type definitions for Descriptions module

"""
$(TYPEDEF)

A type alias representing a variable number of `Symbol`s.

# Example
```julia-repl
julia> using CTBase

julia> CTBase.DescVarArg
Vararg{Symbol}
```

See also: [`CTBase.Descriptions.Description`](@ref)
"""
const DescVarArg = Vararg{Symbol}

"""
$(TYPEDEF)

A description is a tuple of symbols, used to declaratively encode algorithms or configurations.

# Example
`Base.show` is overloaded for descriptions, so tuples of descriptions are
printed one per line:

```julia-repl
julia> using CTBase

julia> display(((:a, :b), (:b, :c)))
(:a, :b)
(:b, :c)
```

See also: [`CTBase.Descriptions.DescVarArg`](@ref)
"""
const Description = Tuple{DescVarArg}
