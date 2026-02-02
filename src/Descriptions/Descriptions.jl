"""
    Descriptions

Description management utilities for CTBase.

This module provides types and functions for working with symbolic descriptions,
including type aliases, manipulation functions, and completion utilities.
"""
module Descriptions

using DocStringExtensions
using ..Exceptions

"""
DescVarArg is a type alias representing a variable number of `Symbol`s.

```julia-repl
julia> using CTBase

julia> CTBase.DescVarArg
Vararg{Symbol}
```

See also: [`Description`](@ref).
"""
const DescVarArg = Vararg{Symbol}

"""
A description is a tuple of symbols. `Description` is a type alias for a tuple of symbols.

See also: [`DescVarArg`](@ref).

# Example

`Base.show` is overloaded for descriptions, so tuples of descriptions are
printed one per line:

```julia-repl
julia> using CTBase

julia> display(((:a, :b), (:b, :c)))
(:a, :b)
(:b, :c)
```
"""
const Description = Tuple{DescVarArg}

# Helper functions for intelligent error suggestions
"""
    compute_similarity(desc1::Description, desc2::Description)::Float64

Compute similarity between two descriptions based on common symbols.

Returns a value between 0.0 (no similarity) and 1.0 (identical).
"""
function compute_similarity(desc1::Description, desc2::Description)::Float64
    if isempty(desc1) || isempty(desc2)
        return 0.0
    end
    
    set1, set2 = Set(desc1), Set(desc2)
    intersection = length(set1 ∩ set2)
    union = length(set1 ∪ set2)
    
    return union == 0 ? 0.0 : intersection / union
end

"""
    find_similar_descriptions(target::Tuple{Vararg{Symbol}}, descriptions::Tuple{Vararg{Description}}; max_results::Int=5)::Vector{String}

Find descriptions most similar to the target description.

Returns formatted string representations of the most similar descriptions.
"""
function find_similar_descriptions(target::Tuple{Vararg{Symbol}}, descriptions::Tuple{Vararg{Description}}; max_results::Int=5)::Vector{String}
    if isempty(descriptions)
        return String[]
    end
    
    # Compute similarities
    similarities = [(compute_similarity(target, desc), string(desc)) for desc in descriptions]
    
    # Sort by similarity (descending) and take top results
    sort!(similarities, rev=true)
    
    # Filter out zero similarity
    filtered = filter(x -> x[1] > 0.0, similarities)
    
    # Limit results and extract descriptions
    if isempty(filtered)
        return String[]
    end
    
    limited = filtered[1:min(max_results, length(filtered))]
    return Vector{String}([desc for (_, desc) in limited])
end

"""
    format_description_candidates(descriptions::Tuple{Vararg{Description}}; max_show::Int=5)::Vector{String}

Format description candidates for error messages.

Returns a vector of formatted description strings, limited to max_show items.
"""
function format_description_candidates(descriptions::Tuple{Vararg{Description}}; max_show::Int=5)::Vector{String}
    if isempty(descriptions)
        return String[]
    end
    
    # Take up to max_show descriptions
    to_show = descriptions[1:min(max_show, length(descriptions))]
    
    return Vector{String}([string(desc) for desc in to_show])
end

"""
$(TYPEDSIGNATURES)

Print a tuple of descriptions, one per line.

# Example

```julia-repl
julia> using CTBase

julia> display(((:a, :b), (:b, :c)))
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
julia> using CTBase

julia> descriptions = ()
julia> descriptions = CTBase.add(descriptions, (:a,))
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

Throw an enriched `IncorrectArgument` exception if the description `y` is already contained in `x`.
The exception includes detailed information about what was provided, what was expected,
and suggestions for how to resolve the issue.

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

"""
$(TYPEDSIGNATURES)

Return one description from a list of Symbols `list` and a set of descriptions `D`. 
If multiple descriptions are possible, then the first one is selected.

If the list is not contained in any of the descriptions, then an enriched `AmbiguousDescription`
exception is thrown. The exception provides helpful suggestions including:
- Similar descriptions based on symbol overlap
- Complete list of available descriptions (if not too long)
- Contextual suggestions for resolving the ambiguity

# Example

```julia-repl
julia> using CTBase

julia> D = ((:a, :b), (:a, :b, :c), (:b, :c), (:a, :c))
(:a, :b)
(:b, :c)
(:a, :c)
julia> CTBase.complete(:a; descriptions=D)
(:a, :b)
julia> CTBase.complete(:a, :c; descriptions=D)
(:a, :b, :c)
julia> CTBase.complete((:a, :c); descriptions=D)
(:a, :b, :c)
julia> CTBase.complete(:f; descriptions=D)
ERROR: AmbiguousDescription: the description (:f,) is ambiguous / incorrect
       Description: (:f,)
       Valid candidates:
       - (:a, :b)
       - (:a, :b, :c)
       - (:b, :c)
       - (:a, :c)
       Suggestion: Available descriptions: (:a, :b), (:a, :b, :c), (:b, :c), (:a, :c)
       Context: description completion
```

# Enhanced Error Features

When no matching description is found, the function provides:

1. **Similar descriptions**: Shows descriptions that share symbols with the input
2. **Complete candidate list**: Lists all available descriptions for reference
3. **Contextual suggestions**: Provides specific guidance based on the input
4. **Structured error information**: All exception fields are populated for programmatic handling

# See Also

- [`compute_similarity`](@ref): For understanding how similarity is calculated
- [`find_similar_descriptions`](@ref): Helper function for finding similar descriptions
- [`format_description_candidates`](@ref): Helper for formatting candidate lists
"""
function complete(list::Symbol...; descriptions::Tuple{Vararg{Description}})::Description
    n = length(descriptions)
    if n == 0
        throw(Exceptions.AmbiguousDescription(
            list,
            candidates=String[],
            suggestion="No descriptions available - check your descriptions catalog or provide descriptions keyword argument",
            context="description completion"
        ))
    end
    
    table = zeros(Int8, n, 2)
    for i in 1:n
        description = descriptions[i]
        table[i, 1] = length(intersect(Set(list), Set(description)))
        table[i, 2] = issubset(Set(list), Set(descriptions[i])) ? 1 : 0
    end
    
    if maximum(table[:, 2]) == 0
        # Find similar descriptions for helpful suggestions
        similar_descs = find_similar_descriptions(list, descriptions; max_results=5)
        all_candidates = format_description_candidates(descriptions; max_show=10)
        
        # Build contextual suggestion
        suggestion = if !isempty(similar_descs)
            "Try one of the similar descriptions: $(join(similar_descs, ", "))"
        elseif !isempty(all_candidates)
            "Available descriptions: $(join(all_candidates, ", "))"
        else
            "Check your input symbols and available descriptions"
        end
        
        throw(Exceptions.AmbiguousDescription(
            list,
            candidates=all_candidates,
            suggestion=suggestion,
            context="description completion"
        ))
    end
    
    # Return the index of the description with maximal intersection count
    return descriptions[argmax(table[:, 1])]
end

"""
$(TYPEDSIGNATURES)

Convenience overload of [`complete`](@ref) for tuple inputs.

This method is equivalent to `complete(list...; descriptions=descriptions)`.

# Arguments

- `list::Tuple{Vararg{Symbol}}`: A tuple of symbols representing a partial description.

# Keyword Arguments

- `descriptions::Tuple{Vararg{Description}}`: Candidate descriptions used for completion.

# Returns

- `Description`: A description from `descriptions` that contains all symbols in `list`.

# Throws

- ``AmbiguousDescription``: If `descriptions` is empty, or if `list` is not contained
  in any candidate description.
"""
function complete(
    list::Tuple{DescVarArg}; descriptions::Tuple{Vararg{Description}}
)::Description
    return complete(list...; descriptions=descriptions)
end

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

# Export public API
export DescVarArg, Description, add, complete, remove

end # module
