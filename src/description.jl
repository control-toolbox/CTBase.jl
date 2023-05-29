"""
    A description is a tuple of symbols, that is a Tuple{Vararg{Symbol}}.
"""
const DescVarArg = Vararg{Symbol}

"""
    A description is a tuple of symbols, that is a Tuple{Vararg{Symbol}}.
"""
const Description = Tuple{DescVarArg}

"""
$(TYPEDSIGNATURES)

Print a tuple of descriptions.
"""
function Base.show(io::IO, ::MIME"text/plain", descriptions::Tuple{Vararg{Description}})
    for description ∈ descriptions
        println(io, description)
    end
end

"""
$(TYPEDSIGNATURES)

Return a tuple containing only the description `y`.

# Example
```jldoctest
julia> descriptions = ()
julia> descriptions = add(descriptions, (:a,))
((:a,),)
julia> descriptions[1]
(:a,)
```
"""
add(x::Tuple{}, y::Description)::Tuple{Vararg{Description}} = (y,)

"""
$(TYPEDSIGNATURES)

Concatenate the description `y` at the tuple of descriptions `x` if it is not already in the tuple `x`.

# Example
```jldoctest
julia> descriptions = ()
julia> descriptions = add(descriptions, (:a,))
((:a,),)
julia> descriptions = add(descriptions, (:b,))
((:a,), (:b,))
```
"""
function add(x::Tuple{Vararg{Description}}, y::Description)::Tuple{Vararg{Description}}
    y ∈ x ? throw(IncorrectArgument("the description $y is already in the list")) : return (x..., y)
end

"""
$(TYPEDSIGNATURES)

Return a complete description from an incomplete description `desc` and 
a list of complete descriptions `desc_list`. If several complete descriptions are possible, 
then the first one is returned.

# Example
```jldoctest
julia> desc_list = ((:a, :b), (:b, :c), (:a, :c))
((:a, :b), (:b, :c), (:a, :c))
julia> getFullDescription((:a,), desc_list)
(:a, :b)
```
"""
function getFullDescription(desc::Description, desc_list::Tuple{Vararg{Description}})::Description
    n = size(desc_list, 1)
    table = zeros(Int8, n, 2)
    for i in range(1, n)
        table[i, 1] = size(desc ∩ desc_list[i], 1)
        table[i, 2] = desc ⊆ desc_list[i] ? 1 : 0
    end
    if maximum(table[:, 2]) == 0
        throw(AmbiguousDescription(desc))
    end
    # argmax : Return the index or key of the maximal element in a collection.
    return desc_list[argmax(table[:, 1])]
end

"""
$(TYPEDSIGNATURES)

Return the difference between the description `x` and the description `y`.

# Example
```jldoctest
julia> (:a, :b) \\ (:a,)
(:b,)
```
"""
Base.:(\)(x::Description, y::Description)::Description = Tuple(setdiff(x, y))
