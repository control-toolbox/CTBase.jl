"""
$(TYPEDSIGNATURES)

Select the most matching description from a catalog based on a partial list of symbols.

If multiple descriptions contain all the symbols in `list`, the one with the largest 
intersection is selected. If multiple descriptions have the same intersection size, 
the first one in the catalog wins (priority is top-to-bottom).

# Arguments
- `list::Symbol...`: A variable number of symbols representing a partial description

# Keyword Arguments
- `descriptions::Tuple{Vararg{Description}}`: A catalog of candidate descriptions

# Returns
- [`Description`](@ref): The best-matching description from the catalog

# Throws
- [`AmbiguousDescription`](@ref): If the catalog is empty or if no description contains all symbols in `list`.

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
When no matching description is found, the function provides suggestions based on 
similarity and lists existing candidates.

See also: [`compute_similarity`](@ref), [`find_similar_descriptions`](@ref), [`format_description_candidates`](@ref)
"""
function complete(list::Symbol...; descriptions::Tuple{Vararg{Description}})::Description
    n = length(descriptions)
    if n == 0
        throw(Exceptions.AmbiguousDescription(
            list,
            candidates=String[],
            suggestion="No descriptions available - check your descriptions catalog or provide descriptions keyword argument",
            context="description completion",
            diagnostic="empty catalog"
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
            "Try one of the closest matches:"
        elseif !isempty(all_candidates)
            "Choose from the available descriptions listed above"
        else
            "Check your input symbols and available descriptions"
        end
        
        # Determine diagnostic: unknown symbols or no complete match
        has_any_match = any(table[:, 1] .> 0)
        diagnostic = if !has_any_match
            "unknown symbols"
        else
            "no complete match"
        end
        
        throw(Exceptions.AmbiguousDescription(
            list,
            candidates=all_candidates,
            suggestion=suggestion,
            context="description completion",
            diagnostic=diagnostic
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
