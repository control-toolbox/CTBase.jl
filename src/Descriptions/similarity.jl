"""
$(TYPEDSIGNATURES)

Compute similarity between two descriptions based on the Jaccard index of their symbols.

# Arguments
- `desc1::Description`: First description to compare
- `desc2::Description`: Second description to compare

# Returns
- `Float64`: A value between 0.0 (no similarity) and 1.0 (identical)

# Example

```julia-repl
julia> using CTBase

julia> CTBase.Descriptions.compute_similarity((:a, :b), (:a, :c))
0.5
julia> CTBase.Descriptions.compute_similarity((:a, :b), (:a, :b))
1.0
julia> CTBase.Descriptions.compute_similarity((:x, :y), (:a, :b))
0.0
```
"""
function _compute_similarity(desc1::Description, desc2::Description)::Float64
    if isempty(desc1) || isempty(desc2)
        return 0.0
    end

    set1, set2 = Set(desc1), Set(desc2)
    intersection = length(set1 ∩ set2)
    union = length(set1 ∪ set2)

    return union == 0 ? 0.0 : intersection / union
end

"""
$(TYPEDSIGNATURES)

Find descriptions most similar to the target description based on symbol overlap.

# Arguments
- `target::Tuple{Vararg{Symbol}}`: The partial or incorrect description to match
- `descriptions::Tuple{Vararg{Description}}`: A catalog of valid descriptions

# Keyword Arguments
- `max_results::Int=5`: Maximum number of similar descriptions to return

# Returns
- `Vector{String}`: Formatted string representations of the most similar descriptions

# Example

```julia-repl
julia> using CTBase

julia> descriptions = ((:a, :b), (:a, :c), (:x, :y))
julia> CTBase.Descriptions.find_similar_descriptions((:a,), descriptions)
2-element Vector{String}:
 "(:a, :b)"
 "(:a, :c)"
```
"""
function _find_similar_descriptions(
    target::Tuple{Vararg{Symbol}},
    descriptions::Tuple{Vararg{Description}};
    max_results::Int=5,
)::Vector{String}
    if isempty(descriptions)
        return String[]
    end

    # Compute similarities
    similarities = [
        (_compute_similarity(target, desc), string(desc)) for desc in descriptions
    ]

    # Sort by similarity (descending) and take top results
    sort!(similarities; rev=true)

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
$(TYPEDSIGNATURES)

Format description candidates from a catalog for display in error messages.

# Arguments
- `descriptions::Tuple{Vararg{Description}}`: A catalog of descriptions

# Keyword Arguments
- `max_show::Int=5`: Maximum number of descriptions to include in the output

# Returns
- `Vector{String}`: A vector of formatted description strings. If the catalog has more
  than `max_show` descriptions, an extra `"… and N more"` marker line is appended so the
  list is not mistaken for exhaustive.

# Example

```julia-repl
julia> using CTBase

julia> descriptions = ((:a, :b), (:a, :c), (:x, :y), (:p, :q))
julia> CTBase.Descriptions.format_description_candidates(descriptions; max_show=3)
3-element Vector{String}:
 "(:a, :b)"
 "(:a, :c)"
 "(:x, :y)"

julia> descriptions = ((:a, :b), (:a, :c), (:x, :y), (:p, :q), (:r, :s), (:t, :u))
julia> CTBase.Descriptions.format_description_candidates(descriptions; max_show=2)
3-element Vector{String}:
 "(:a, :b)"
 "(:a, :c)"
 "… and 4 more"
```
"""
function _format_description_candidates(
    descriptions::Tuple{Vararg{Description}}; max_show::Int=5
)::Vector{String}
    isempty(descriptions) && return String[]

    n = length(descriptions)
    formatted = Vector{String}([string(desc) for desc in descriptions[1:min(max_show, n)]])

    if n > max_show
        push!(formatted, "… and $(n - max_show) more")
    end

    return formatted
end
