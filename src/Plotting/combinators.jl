# =============================================================================
# combinators.jl — level-2 declarative layout: Stacked / Paired / Grid.
#
# These are pure, typed tree builders over already-lowered layout NODES (see
# lowering.jl for Panel -> node). They add no geometry beyond weights.
#
# Weight policy `:auto` (decision D4): a child's weight is its number of drawable
# cells (`n_leaves`). Stacking N panels of k components each thus gives every cell
# the same height (proportional to the number of lines); explicit weights override.
#
# Docstrings deferred (Handbook convention).
# =============================================================================

# Resolve `:auto` weights to a concrete Float64 vector; otherwise pass through
# (the HBox/VBox constructor validates length and positivity).
function _resolve_weights(children::AbstractVector{<:AbstractLayoutNode}, weights)
    weights === :auto && return Float64[n_leaves(c) for c in children]
    return collect(Float64, weights)
end

"""
$(TYPEDSIGNATURES)

Stack `children` vertically into a [`VBox`](@ref). With `weights=:auto` (default,
decision D4) each child's weight is its number of cells, so stacking panels of
different heights keeps every cell the same height; pass an explicit weight vector
to override.
"""
function Stacked(children::AbstractVector{<:AbstractLayoutNode}; weights=:auto)
    return VBox(children, _resolve_weights(children, weights))
end

"""
$(TYPEDSIGNATURES)

Place `children` side by side into an [`HBox`](@ref) (e.g. state | costate). Same
`:auto` weight policy as [`Stacked`](@ref). A two-argument form
`Paired(left, right)` is provided for the common pair.
"""
function Paired(children::AbstractVector{<:AbstractLayoutNode}; weights=:auto)
    return HBox(children, _resolve_weights(children, weights))
end
function Paired(left::AbstractLayoutNode, right::AbstractLayoutNode; weights=:auto)
    return Paired(AbstractLayoutNode[left, right]; weights=weights)
end

"""
$(TYPEDSIGNATURES)

Arrange a rectangular matrix of nodes into a grid: `cells[i, j]` is row `i`,
column `j` (e.g. the `:group` n×m layout). Each row becomes an [`HBox`](@ref) and
the rows are stacked in a [`VBox`](@ref). Row and column weights default to equal;
pass `row_weights` / `col_weights` to override.
"""
function Grid(
    cells::AbstractMatrix{<:AbstractLayoutNode};
    row_weights=ones(size(cells, 1)),
    col_weights=ones(size(cells, 2)),
)
    nr, nc = size(cells)
    length(col_weights) == nc || throw(
        Exceptions.IncorrectArgument(
            "Grid needs one column weight per column";
            got="$(length(col_weights)) col_weights, $nc columns",
            expected="length(col_weights) == size(cells, 2)",
        ),
    )
    rows = AbstractLayoutNode[
        HBox(AbstractLayoutNode[cells[i, j] for j in 1:nc], collect(Float64, col_weights))
        for i in 1:nr
    ]
    return VBox(rows, collect(Float64, row_weights))
end
