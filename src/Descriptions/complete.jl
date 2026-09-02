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
- `Description`: The best-matching description from the catalog

# Throws
- `AmbiguousDescription`: If the catalog is empty or if no description contains all symbols in `list`.

# Example
```julia-repl
julia> using CTBase

julia> D = ((:a, :b), (:a, :b, :c), (:b, :c), (:a, :c));

julia> CTBase.complete(:a; descriptions=D)
(:a, :b)

julia> CTBase.complete(:a, :c; descriptions=D)
(:a, :b, :c)

julia> CTBase.complete((:a, :c); descriptions=D)
(:a, :b, :c)

julia> CTBase.complete(:a, :z; descriptions=D)
ERROR: AmbiguousDescription → #complete#15, complete.jl:97
│
│  cannot find matching description
│
│  Diagnostic  No complete match — no description contains all symbols
│  Requested   (:a, :z)
│  Available   (:a, :b)
│              (:a, :b, :c)
│              (:b, :c)
│              (:a, :c)
│
│  Context     description completion
│  Hint        Try one of the closest matches:
│              (:a, :c)
│              (:a, :b)
│              (:a, :b, :c)
└─
```

`Available` always describes the catalog — every entry, or the first `max_show`
followed by a `… and N more` marker. The closest matches, when any description
shares a symbol with the request, are listed by the `Hint` itself.

See also: [`CTBase.Descriptions._compute_similarity`](@extref), [`CTBase.Descriptions._find_similar_descriptions`](@extref), [`CTBase.Descriptions._format_description_candidates`](@extref), [`CTBase.Exceptions.AmbiguousDescription`](@extref)
"""
function complete(list::Symbol...; descriptions::Tuple{Vararg{Description}})::Description
    n = length(descriptions)
    if n == 0
        throw(
            Exceptions.AmbiguousDescription(
                list;
                candidates=String[],
                suggestion="No descriptions available - check your descriptions catalog or provide descriptions keyword argument",
                context="description completion",
                diagnostic="empty catalog",
            ),
        )
    end

    table = zeros(Int8, n, 2)
    for i in 1:n
        description = descriptions[i]
        table[i, 1] = length(intersect(Set(list), Set(description)))
        table[i, 2] = issubset(Set(list), Set(descriptions[i])) ? 1 : 0
    end

    if maximum(table[:, 2]) == 0
        # Find similar descriptions for helpful suggestions
        similar_descs = _find_similar_descriptions(list, descriptions; max_results=5)
        all_candidates = _format_description_candidates(descriptions; max_show=20)

        # Build contextual suggestion. The closest matches are carried *by the
        # hint itself*, not by `candidates`: the display layer labels
        # `candidates` "Available", so putting a similarity-filtered subset
        # there would claim the catalog is smaller than it is, and leave the
        # hint announcing a list it never prints (issue #557).
        suggestion = if !isempty(similar_descs)
            string("Try one of the closest matches:\n", join(similar_descs, "\n"))
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

        throw(
            Exceptions.AmbiguousDescription(
                list;
                candidates=all_candidates,
                suggestion=suggestion,
                context="description completion",
                diagnostic=diagnostic,
            ),
        )
    end

    # Return the index of the description with maximal intersection count
    return descriptions[argmax(table[:, 1])]
end

"""
$(TYPEDSIGNATURES)

Convenience overload of `complete` for tuple inputs.

This method is equivalent to `complete(list...; descriptions=descriptions)`.

# Arguments

- `list::Tuple{Vararg{Symbol}}`: A tuple of symbols representing a partial description.

# Keyword Arguments

- `descriptions::Tuple{Vararg{Description}}`: Candidate descriptions used for completion.

# Returns

- `Description`: A description from `descriptions` that contains all symbols in `list`.

# Throws

- [`CTBase.Exceptions.AmbiguousDescription`](@extref): If `descriptions` is empty, or if `list` is not contained
  in any candidate description.

See also: [`CTBase.Descriptions.complete`](@extref), [`CTBase.Exceptions.AmbiguousDescription`](@extref)
"""
function complete(
    list::Tuple{DescVarArg}; descriptions::Tuple{Vararg{Description}}
)::Description
    return complete(list...; descriptions=descriptions)
end
