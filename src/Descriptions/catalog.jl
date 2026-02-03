"""
$(TYPEDSIGNATURES)

Initialize a new description catalog with a single description `y`.

# Arguments
- `y::Description`: The initial description to add

# Returns
- `Tuple{Vararg{Description}}`: A tuple containing only the description `y`

# Example
```julia-repl
julia> using CTBase

julia> descriptions = ()
julia> descriptions = CTBase.add(descriptions, (:a,))
(:a,)
julia> print(descriptions)
((:a,),)
julia> descriptions[1]
(:a,)
```

See also: [`Description`](@ref)
"""
add(::Tuple{}, y::Description)::Tuple{Vararg{Description}} = (y,)

"""
$(TYPEDSIGNATURES)

Add the description `y` to the catalog `x` if it is not already present.

# Arguments
- `x::Tuple{Vararg{Description}}`: Existing description catalog
- `y::Description`: Specific description to add

# Returns
- `Tuple{Vararg{Description}}`: The updated catalog with `y` appended

# Throws
- [`IncorrectArgument`](@ref): If the description `y` is already contained in `x`

# Example
```julia-repl
julia> using CTBase

julia> descriptions = ()
julia> descriptions = CTBase.add(descriptions, (:a,))
(:a,)
julia> descriptions = CTBase.add(descriptions, (:b,))
(:a,)
(:b,)
julia> descriptions = CTBase.add(descriptions, (:b,))
ERROR: IncorrectArgument: the description (:b,) is already in ((:a,), (:b,))
       Got: (:b,)
       Expected: a unique description not in the catalog
       Suggestion: Check existing descriptions before adding, or use a different description
       Context: description catalog management
```

See also: [`complete`](@ref), [`remove`](@ref)
"""
function add(x::Tuple{Vararg{Description}}, y::Description)::Tuple{Vararg{Description}}
    if y ∈ x
        throw(Exceptions.IncorrectArgument(
            "the description $y is already in $x",
            got=string(y),
            expected="a unique description not in the catalog",
            suggestion="Check existing descriptions before adding, or use a different description",
            context="description catalog management"
        ))
    else
        return (x..., y)
    end
end
