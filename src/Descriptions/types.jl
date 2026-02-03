# Type definitions for Descriptions module

using DocStringExtensions

"""
$(TYPEDEF)

A type alias representing a variable number of `Symbol`s.

# Example
```julia-repl
julia> using CTBase

julia> CTBase.DescVarArg
Vararg{Symbol}
```

See also: [`Description`](@ref)
"""
const DescVarArg = Vararg{Symbol}

"""
$(TYPEDEF)

A description is a tuple of symbols, used to declarative encode algorithms or configurations.

# Example
`Base.show` is overloaded for descriptions, so tuples of descriptions are
printed one per line:

```julia-repl
julia> using CTBase

julia> display(((:a, :b), (:b, :c)))
(:a, :b)
(:b, :c)
```

See also: [`DescVarArg`](@ref)
"""
const Description = Tuple{DescVarArg}
