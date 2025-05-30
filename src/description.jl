"""
DescVarArg is a Vararg of symbols. `DescVarArg` is a type alias for a Vararg of symbols.

```julia-repl
julia> const DescVarArg = Vararg{Symbol}
```

See also: [`Description`](@ref).
"""
const DescVarArg = Vararg{Symbol}

"""
A description is a tuple of symbols. `Description` is a type alias for a tuple of symbols.

```julia-repl
julia> const Description = Tuple{DescVarArg}
```

See also: [`DescVarArg`](@ref).

# Example

[`Base.show`](@ref) is overloaded for descriptions, that is tuple of descriptions are printed as follows:

```julia-repl
julia> display( ( (:a, :b), (:b, :c) ) )
(:a, :b)
(:b, :c)
```
"""
const Description = Tuple{DescVarArg}

"""
$(TYPEDSIGNATURES)

Print a tuple of descriptions.

# Example

```julia-repl
julia> display( ( (:a, :b), (:b, :c) ) )
(:a, :b)
(:b, :c)
```
"""
function Base.show(io::IO, ::MIME"text/plain", descriptions::Tuple{Vararg{Description}})
    N = length(descriptions)  # use length instead of size for 1D tuple
    for i in 1:N
        description = descriptions[i]
        # print with newline except for last
        if i < N
            print(io, "$description\n")
        else
            print(io, "$description")
        end
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Return a tuple containing only the description `y`.

# Example
```julia-repl
julia> descriptions = ()
julia> descriptions = add(descriptions, (:a,))
(:a,)
julia> print(descriptions)
((:a,),)
julia> descriptions[1]
(:a,)
```
"""
add(::Tuple{}, y::Description)::Tuple{Vararg{Description}} = (y,)

"""
$(TYPEDSIGNATURES)

Add the description `y` to the tuple of descriptions `x` if `x` does not contain `y`
and return the new tuple of descriptions. 

Throw an exception (IncorrectArgument) if the description `y` is already contained in `x`.

# Example

```julia-repl
julia> descriptions = ()
julia> descriptions = add(descriptions, (:a,))
(:a,)
julia> descriptions = add(descriptions, (:b,))
(:a,)
(:b,)
julia> descriptions = add(descriptions, (:b,))
ERROR: IncorrectArgument: the description (:b,) is already in ((:a,), (:b,))
```
"""
function add(x::Tuple{Vararg{Description}}, y::Description)::Tuple{Vararg{Description}}
    if y ∈ x
        throw(IncorrectArgument("the description $y is already in $x"))
    else
        return (x..., y)
    end
end

"""
$(TYPEDSIGNATURES)

Return one description from a list of Symbols `list` and a set of descriptions `D`. 
If multiple descriptions are possible, then the first one is selected.

If the list is not contained in any of the descriptions, then an exception is thrown.

# Example

```julia-repl
julia> D = ((:a, :b), (:a, :b, :c), (:b, :c), (:a, :c))
(:a, :b)
(:b, :c)
(:a, :c)
julia> complete(:a; descriptions=D)
(:a, :b)
julia> complete(:a, :c; descriptions=D)
(:a, :b, :c)
julia> complete((:a, :c); descriptions=D)
(:a, :b, :c)
julia> complete(:f; descriptions=D)
ERROR: AmbiguousDescription: the description (:f,) is ambiguous / incorrect
```
"""
function complete(list::Symbol...; descriptions::Tuple{Vararg{Description}})::Description
    n = length(descriptions)
    table = zeros(Int8, n, 2)
    for i in 1:n
        table[i, 1] = length(intersect(list, descriptions[i]))
        table[i, 2] = issubset(Set(list), Set(descriptions[i])) ? 1 : 0
    end
    if maximum(table[:, 2]) == 0
        throw(AmbiguousDescription(list))
    end
    # Return the index of the description with maximal intersection count
    return descriptions[argmax(table[:, 1])]
end

function complete(list::Tuple{DescVarArg}; descriptions::Tuple{Vararg{Description}})::Description
    return complete(list..., descriptions=descriptions)
end

"""
$(TYPEDSIGNATURES)

Return the difference between the description `x` and the description `y`.

# Example

```julia-repl
julia> remove((:a, :b), (:a,))
(:b,)
```
"""
function remove(x::Description, y::Description)::Description
    return Tuple(setdiff(x, y))
end
