# =============================================================================
# heuristics.jl — figure-size heuristics, driven by the weighted tree.
#
# Generalises the CTFlows engine sizes (`__size_plot`, `__size_group`): width
# grows with the number of columns, height with the number of stacked rows. Same
# per-row height and width formula so :split and :group stay visually consistent.
# =============================================================================

"""
Default per-row height in pixels for the figure-size heuristic.
"""
const _ROW_HEIGHT = 180

"""
Vertical padding in pixels added to the total figure height.
"""
const _HEIGHT_PAD = 60

"""
$(TYPEDSIGNATURES)

Return the figure width in pixels for `cols` columns (minimum 600).
"""
_width(cols::Integer) = max(600, 340 * cols)

"""
$(TYPEDSIGNATURES)

Return the `(rows, cols)` cell shape of a layout node: a [`Leaf`](@ref) is
`(1, 1)`; a [`VBox`](@ref) sums child rows and takes the max of child columns; an
[`HBox`](@ref) does the transpose. Drives [`default_size`](@ref).
"""
grid_shape(::Leaf) = (1, 1)
function grid_shape(node::VBox)
    shapes = grid_shape.(node.children)
    return (sum(first, shapes), maximum(last, shapes))
end
function grid_shape(node::HBox)
    shapes = grid_shape.(node.children)
    return (maximum(first, shapes), sum(last, shapes))
end

"""
$(TYPEDSIGNATURES)

Default figure size for a layout `node`: width from the number of columns, height
from the number of stacked rows.
"""
function default_size(node::AbstractLayoutNode)
    rows, cols = grid_shape(node)
    return (_width(cols), _ROW_HEIGHT * rows + _HEIGHT_PAD)
end

default_size(fig::Figure) = fig.size === nothing ? default_size(fig.root) : fig.size
