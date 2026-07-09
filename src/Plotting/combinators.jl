# =============================================================================
# combinators.jl — level-2 declarative layout: Stacked / Paired / Grid.
#
# These are pure, typed tree builders over already-lowered layout NODES (see
# lowering.jl for Panel -> node). They add no geometry beyond weights.
#
# Weight policy `:auto` (decision D4) is geometry-aware: a child's weight is its
# extent along the combinator's axis — its number of rows for `Stacked` (vertical),
# its number of columns for `Paired` (horizontal). Stacking panels of different
# heights thus keeps every cell the same height; pairing columns keeps every column
# the same width. This is `grid_shape(child)[dim]`, which equals `n_leaves` for flat
# columns but stays correct when a paired block is nested inside a stack (e.g. the
# CTModels `Stacked(Paired(state, costate), control, …)` gets row weights `n : l : …`
# rather than leaf-count `2n : l : …`). Explicit weights always override.
#
# Docstrings deferred (Handbook convention).
# =============================================================================

# Resolve `:auto` weights to a concrete Float64 vector along axis `dim` (1 = rows,
# 2 = columns); otherwise pass through (the HBox/VBox constructor validates length
# and positivity).
function _resolve_weights(
    children::AbstractVector{<:AbstractLayoutNode}, weights, dim::Integer
)
    weights === :auto && return Float64[grid_shape(c)[dim] for c in children]
    return collect(Float64, weights)
end

"""
$(TYPEDSIGNATURES)

Stack `children` vertically into a [`VBox`](@ref). With `weights=:auto` (default,
decision D4) each child's weight is its number of **rows** (`grid_shape(child)[1]`),
so stacking blocks of different heights keeps every cell the same height — including
when a child is itself a paired block; pass an explicit weight vector to override.
"""
function Stacked(children::AbstractVector{<:AbstractLayoutNode}; weights=:auto)
    return VBox(children, _resolve_weights(children, weights, 1))
end

"""
$(TYPEDSIGNATURES)

Place `children` side by side into an [`HBox`](@ref) (e.g. state | costate). With
`weights=:auto` each child's weight is its number of **columns**
(`grid_shape(child)[2]`), so equal-width columns stay equal; pass an explicit weight
vector to override. A two-argument form `Paired(left, right)` is provided for the
common pair.
"""
function Paired(children::AbstractVector{<:AbstractLayoutNode}; weights=:auto)
    return HBox(children, _resolve_weights(children, weights, 2))
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
