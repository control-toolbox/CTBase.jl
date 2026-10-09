# =============================================================================
# labels.jl — user label keywords (`title`, `xlabel`, `ylabel`) applied on the IR.
#
# The backends compute the labels of every cell from the IR, so a user override
# cannot be forwarded as a plain subplot/axis attribute (it would hit every cell).
# It is resolved here, once, on the backend-agnostic IR, so Plots and Makie agree:
#   - `xlabel` replaces the x label of the cells that already carry one (the cells
#     that show the abscissa name);
#   - `title` becomes the overall figure title;
#   - `ylabel` is ambiguous (one name per component) and is not applied: a warning
#     is emitted instead.
# =============================================================================

"""
    _LABEL_KEYS

User keyword arguments resolved on the IR by [`_resolve_labels`](@ref) instead of
being forwarded to the backend.
"""
const _LABEL_KEYS = (:title, :xlabel, :ylabel)

"""
$(TYPEDSIGNATURES)

Return a copy of `node` where the x label of every cell that already has a non-empty
one is replaced by `xlabel`.
"""
function _with_xlabel(node::Leaf, xlabel::String)
    ax = node.axes
    isempty(ax.xlabel) && return node
    return Leaf(
        Axes(
            ax.title,
            xlabel,
            ax.ylabel,
            ax.series,
            ax.decorations,
            ax.legend,
            ax.ylims,
        ),
    )
end
function _with_xlabel(node::HBox, xlabel::String)
    return HBox(AbstractLayoutNode[_with_xlabel(c, xlabel) for c in node.children], node.weights)
end
function _with_xlabel(node::VBox, xlabel::String)
    return VBox(AbstractLayoutNode[_with_xlabel(c, xlabel) for c in node.children], node.weights)
end

"""
$(TYPEDSIGNATURES)

Resolve the label keywords `title`, `xlabel` and `ylabel` of `kwargs` against `fig`.

- `xlabel` replaces the x label of the cells that carry one (e.g. the bottom cell of a
  split panel, or the time label of a group cell);
- `title` replaces the overall title of the figure (an empty string removes it);
- `ylabel` is not applied — cells carry one name per component — and triggers a
  warning, as the label can be changed after rendering with the backend's own API.

Values are converted with `string`, so a rich-text string (e.g. a `LaTeXString`)
is kept as its raw text.

# Returns
- `(fig′, rest)`: the relabelled figure and the remaining keyword arguments (as a
  `NamedTuple`) to forward to the backend.
"""
function _resolve_labels(fig::Figure; kwargs...)
    rest = NamedTuple(p for p in kwargs if !(p[1] in _LABEL_KEYS))
    xlabel = get(kwargs, :xlabel, nothing)
    title = get(kwargs, :title, nothing)
    haskey(kwargs, :ylabel) && @warn(
        "`ylabel` is ignored: each cell carries its own y label (one per component). " *
        "Change it after rendering with the backend API (e.g. `ylabel!(p[i], \"…\")` in Plots).",
        ylabel = kwargs[:ylabel],
    )
    root = xlabel === nothing ? fig.root : _with_xlabel(fig.root, string(xlabel))
    ti = if title === nothing
        fig.title
    else
        s = string(title)
        isempty(s) ? nothing : s
    end
    return Figure(root, fig.size, ti), rest
end
