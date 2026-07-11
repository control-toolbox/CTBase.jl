# =============================================================================
# ir.jl — the intermediate representation (pure data, no backend dependency).
# =============================================================================

# --- series and decorations --------------------------------------------------

"""
$(TYPEDEF)

One plotted curve: a set of `(x, y)` points. Used both for time series (`x` a time
grid) and for phase plots (`x`, `y` two state components). An empty `label` draws
no legend entry.

`style` uses the neutral, backend-agnostic vocabulary — `color`, `linewidth`,
`linestyle`, `alpha`, `seriestype` (`:path`, `:steppost`, `:scatter`), `z_order`
(`:back`/`:front`) — plus `backend_kwargs::NamedTuple` as an escape hatch for
backend-specific attributes (decision D2).

# Fields
$(TYPEDFIELDS)
"""
struct Series
    x::Vector{Float64}
    y::Vector{Float64}
    label::String
    style::NamedTuple
end

function Series(
    x::AbstractVector,
    y::AbstractVector;
    label::AbstractString="",
    style::NamedTuple=NamedTuple(),
)
    length(x) == length(y) || throw(
        Exceptions.IncorrectArgument(
            "a Series needs x and y of equal length";
            got="length(x)=$(length(x)), length(y)=$(length(y))",
            expected="length(x) == length(y)",
        ),
    )
    return Series(collect(Float64, x), collect(Float64, y), String(label), style)
end

"""
$(TYPEDEF)

A horizontal reference line at height `value` (e.g. a box bound). `style` follows
the same neutral vocabulary as [`Series`](@ref).

# Fields
$(TYPEDFIELDS)
"""
struct HLine
    value::Float64
    style::NamedTuple
end
HLine(value::Real; style::NamedTuple=NamedTuple()) = HLine(Float64(value), style)

"""
$(TYPEDEF)

A vertical reference line at abscissa `value` (e.g. initial/final time). `style`
follows the same neutral vocabulary as [`Series`](@ref).

# Fields
$(TYPEDFIELDS)
"""
struct VLine
    value::Float64
    style::NamedTuple
end
VLine(value::Real; style::NamedTuple=NamedTuple()) = VLine(Float64(value), style)

"""
Either an [`HLine`](@ref) or a [`VLine`](@ref) — a reference line drawn on an
[`Axes`](@ref) on top of its series.
"""
const Decoration = Union{HLine,VLine}

# --- one cell = one axis system ----------------------------------------------

"""
$(TYPEDEF)

One drawable cell: a single axis system holding a list of [`Series`](@ref),
optional [`Decoration`](@ref)s drawn on top, and its labels/limits. Domain-free —
the case layer decides what a cell *means*.

`ylims` is one of:
- `nothing`       — leave the backend default,
- `(lo, hi)`      — fixed limits,
- `:auto`         — backend auto-scaling,
- `:auto_guarded` — auto, but widen a (near-)constant series so the axis does not
  collapse (resolved from the series data, either at lowering or by the backend).

# Fields
$(TYPEDFIELDS)
"""
struct Axes
    title::String
    xlabel::String
    ylabel::String
    series::Vector{Series}
    decorations::Vector{Decoration}
    legend::Bool
    ylims::Union{Nothing,Tuple{Float64,Float64},Symbol}
end

function Axes(
    series::AbstractVector{Series};
    title::AbstractString="",
    xlabel::AbstractString="",
    ylabel::AbstractString="",
    decorations::AbstractVector=Decoration[],
    legend::Bool=false,
    ylims::Union{Nothing,Tuple{Real,Real},Symbol}=:auto_guarded,
)
    yl = ylims isa Tuple ? (Float64(ylims[1]), Float64(ylims[2])) : ylims
    return Axes(
        String(title),
        String(xlabel),
        String(ylabel),
        collect(Series, series),
        collect(Decoration, decorations),
        legend,
        yl,
    )
end

# --- layout : weighted tree (IR level 3) -------------------------------------

"""
$(TYPEDEF)

Supertype of the weighted layout tree: [`Leaf`](@ref) (a cell), [`HBox`](@ref)
(columns side by side) and [`VBox`](@ref) (rows stacked). This is the
backend-agnostic geometry a renderer turns into subplots.
"""
abstract type AbstractLayoutNode end

"""
$(TYPEDEF)

A leaf of the layout tree: a single drawable cell wrapping one [`Axes`](@ref).
"""
struct Leaf <: AbstractLayoutNode
    axes::Axes
end

"""
$(TYPEDEF)

Horizontal juxtaposition of child nodes (columns placed side by side). `weights`
are relative column widths, one per child (strictly positive). See also
[`VBox`](@ref).

# Fields
$(TYPEDFIELDS)
"""
struct HBox <: AbstractLayoutNode
    children::Vector{AbstractLayoutNode}
    weights::Vector{Float64}
    function HBox(
        children::AbstractVector{<:AbstractLayoutNode}, weights::AbstractVector{<:Real}
    )
        _check_box(children, weights, "HBox")
        return new(collect(AbstractLayoutNode, children), collect(Float64, weights))
    end
end

"""
$(TYPEDEF)

Vertical stacking of child nodes (rows one under another). `weights` are relative
row heights, one per child (strictly positive). See also [`HBox`](@ref).

# Fields
$(TYPEDFIELDS)
"""
struct VBox <: AbstractLayoutNode
    children::Vector{AbstractLayoutNode}
    weights::Vector{Float64}
    function VBox(
        children::AbstractVector{<:AbstractLayoutNode}, weights::AbstractVector{<:Real}
    )
        _check_box(children, weights, "VBox")
        return new(collect(AbstractLayoutNode, children), collect(Float64, weights))
    end
end

# Equal-weight convenience constructors.
function HBox(children::AbstractVector{<:AbstractLayoutNode})
    return HBox(children, ones(length(children)))
end
function VBox(children::AbstractVector{<:AbstractLayoutNode})
    return VBox(children, ones(length(children)))
end

"""
$(TYPEDSIGNATURES)

Validate that a `HBox`/`VBox` has at least one child, one weight per child, and
strictly positive weights.

# Throws
- `CTBase.Exceptions.IncorrectArgument`: if `children` is empty, if the lengths
  mismatch, or if any weight is non-positive.
"""
function _check_box(children, weights, who::String)
    isempty(children) && throw(
        Exceptions.IncorrectArgument(
            "a $who needs at least one child"; got="0 children", expected="≥ 1 child"
        ),
    )
    length(children) == length(weights) || throw(
        Exceptions.IncorrectArgument(
            "a $who needs one weight per child";
            got="$(length(children)) children, $(length(weights)) weights",
            expected="length(weights) == length(children)",
        ),
    )
    all(>(0), weights) || throw(
        Exceptions.IncorrectArgument(
            "$who weights must be strictly positive";
            got="weights=$(collect(weights))",
            expected="all weights > 0",
        ),
    )
    return nothing
end

# --- figure ------------------------------------------------------------------

"""
$(TYPEDEF)

A complete figure: a layout `root` plus optional overall `size` and `title`.
`size === nothing` defers to the engine size heuristic ([`default_size`](@ref));
`title === nothing` draws no overall title.

# Fields
$(TYPEDFIELDS)
"""
struct Figure
    root::AbstractLayoutNode
    size::Union{Nothing,Tuple{Int,Int}}
    title::Union{Nothing,String}
end

function Figure(root::AbstractLayoutNode; size=nothing, title=nothing)
    sz = size === nothing ? nothing : (Int(size[1]), Int(size[2]))
    ti = title === nothing ? nothing : String(title)
    return Figure(root, sz, ti)
end

# --- deterministic leaf traversal --------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the [`Leaf`](@ref)s of a node in **deterministic** order: depth-first,
children visited in stored order. This order is the contract used to target
existing cells by index when overlaying with [`render!`](@ref).
"""
leaves(leaf::Leaf) = Leaf[leaf]
function leaves(node::Union{HBox,VBox})
    return reduce(vcat, (leaves(c) for c in node.children); init=Leaf[])
end

"""
$(TYPEDSIGNATURES)

Return the number of drawable cells (leaves) in a layout node.
"""
n_leaves(node::AbstractLayoutNode) = length(leaves(node))

"""
$(TYPEDSIGNATURES)

Return the number of drawable cells (leaves) in a [`Figure`](@ref).
"""
n_leaves(fig::Figure) = n_leaves(fig.root)

# --- display -----------------------------------------------------------------

# Maximum number of children / series to show before truncating.
const _SHOW_LIMIT = 5

"""
$(TYPEDSIGNATURES)

Compact one-line display of a [`Series`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, s::Series)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "Series", fmt.reset, "(")
    print(io, fmt.label, repr(s.label), fmt.reset, ", ")
    print(io, fmt.value, length(s.x), fmt.reset, " pts)")
end

"""
$(TYPEDSIGNATURES)

Pretty tree-style display of a [`Series`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, ::MIME"text/plain", s::Series)
    fmt = Core.get_format_codes(io)
    np = length(s.x)
    print(io, fmt.name, "Series", fmt.reset, " ")
    print(io, fmt.label, repr(s.label), fmt.reset)
    print(io, " (", fmt.value, np, fmt.reset, np == 1 ? " point)" : " points)")
    if !isempty(s.style)
        print(io, "\n  style: ", fmt.value, s.style, fmt.reset)
    end
end

"""
$(TYPEDSIGNATURES)

Compact one-line display of an [`HLine`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, h::HLine)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "HLine", fmt.reset, "(", fmt.value, h.value, fmt.reset, ")")
end

"""
$(TYPEDSIGNATURES)

Pretty display of an [`HLine`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, ::MIME"text/plain", h::HLine)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "HLine", fmt.reset, " at y=", fmt.value, h.value, fmt.reset)
    if !isempty(h.style)
        print(io, "  style: ", fmt.label, h.style, fmt.reset)
    end
end

"""
$(TYPEDSIGNATURES)

Compact one-line display of a [`VLine`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, v::VLine)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "VLine", fmt.reset, "(", fmt.value, v.value, fmt.reset, ")")
end

"""
$(TYPEDSIGNATURES)

Pretty display of a [`VLine`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, ::MIME"text/plain", v::VLine)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "VLine", fmt.reset, " at x=", fmt.value, v.value, fmt.reset)
    if !isempty(v.style)
        print(io, "  style: ", fmt.label, v.style, fmt.reset)
    end
end

"""
$(TYPEDSIGNATURES)

Compact one-line display of an [`Axes`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, ax::Axes)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "Axes", fmt.reset, "(")
    print(io, fmt.label, repr(ax.title), fmt.reset, ", ")
    print(io, fmt.value, length(ax.series), fmt.reset, " series)")
end

"""
$(TYPEDSIGNATURES)

Pretty tree-style display of an [`Axes`](@ref), recursively
showing its series and decorations.

See also: `Base.show`
"""
function Base.show(io::IO, ::MIME"text/plain", ax::Axes)
    _show_axes(io, ax, "")
end

function _show_axes(io::IO, ax::Axes, prefix::String)
    fmt = Core.get_format_codes(io)
    n = length(ax.series)
    print(io, fmt.name, "Axes", fmt.reset, " ")
    print(io, fmt.label, repr(ax.title), fmt.reset)
    print(io, " (", fmt.value, n, fmt.reset, " series)")
    items = AbstractVector[]
    for s in ax.series
        push!(items, [s])
    end
    for d in ax.decorations
        push!(items, [d])
    end
    if !isempty(ax.xlabel) || !isempty(ax.ylabel)
        push!(items, [:labels, ax.xlabel, ax.ylabel])
    end
    n_items = length(items)
    for (i, item) in enumerate(items)
        is_last = i == n_items
        branch = is_last ? "└─ " : "├─ "
        cont = is_last ? "   " : "│  "
        if length(item) == 1 && item[1] isa Series
            s = item[1]
            np = length(s.x)
            print(io, "\n", prefix, branch)
            print(io, fmt.name, "Series", fmt.reset, " ")
            print(io, fmt.label, repr(s.label), fmt.reset)
            print(io, " (", fmt.value, np, fmt.reset, np == 1 ? " point)" : " points)")
            if !isempty(s.style)
                print(io, "\n", prefix, cont, "  style: ")
                print(io, fmt.value, s.style, fmt.reset)
            end
        elseif length(item) == 1
            d = item[1]
            print(io, "\n", prefix, branch, d)
        elseif item[1] === :labels
            print(io, "\n", prefix, branch)
            if !isempty(ax.xlabel)
                print(io, "xlabel: ", fmt.label, ax.xlabel, fmt.reset)
            end
            if !isempty(ax.xlabel) && !isempty(ax.ylabel)
                print(io, ", ")
            end
            if !isempty(ax.ylabel)
                print(io, "ylabel: ", fmt.label, ax.ylabel, fmt.reset)
            end
        end
    end
end

"""
$(TYPEDSIGNATURES)

Compact one-line display of a [`Leaf`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, leaf::Leaf)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "Leaf", fmt.reset, "(")
    show(io, leaf.axes)
    print(io, ")")
end

"""
$(TYPEDSIGNATURES)

Pretty tree-style display of a [`Leaf`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, ::MIME"text/plain", leaf::Leaf)
    _show_node(io, leaf, "")
end

"""
$(TYPEDSIGNATURES)

Compact one-line display of an [`HBox`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, box::HBox)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "HBox", fmt.reset, "(")
    print(io, fmt.value, length(box.children), fmt.reset, " children)")
end

"""
$(TYPEDSIGNATURES)

Pretty tree-style display of an [`HBox`](@ref), recursively
showing its children.

See also: `Base.show`
"""
function Base.show(io::IO, ::MIME"text/plain", box::HBox)
    _show_node(io, box, "")
end

"""
$(TYPEDSIGNATURES)

Compact one-line display of a [`VBox`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, box::VBox)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "VBox", fmt.reset, "(")
    print(io, fmt.value, length(box.children), fmt.reset, " children)")
end

"""
$(TYPEDSIGNATURES)

Pretty tree-style display of a [`VBox`](@ref), recursively
showing its children.

See also: `Base.show`
"""
function Base.show(io::IO, ::MIME"text/plain", box::VBox)
    _show_node(io, box, "")
end

# Recursively print a layout node. The node header is printed at the current
# cursor position; `prefix` is the indentation carried to the node's children.
function _show_node(io::IO, leaf::Leaf, prefix::String)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "Leaf", fmt.reset)
    print(io, "\n", prefix, "└─ ")
    _show_axes(io, leaf.axes, prefix * "   ")
end

function _show_node(io::IO, node::Union{HBox,VBox}, prefix::String)
    fmt = Core.get_format_codes(io)
    type_name = node isa HBox ? "HBox" : "VBox"
    n = length(node.children)
    print(io, fmt.name, type_name, fmt.reset)
    print(io, " (", fmt.value, n, fmt.reset, " children)")
    shown = min(n, _SHOW_LIMIT)
    for i in 1:shown
        child = node.children[i]
        is_last = i == n
        branch = is_last ? "└─ " : "├─ "
        childcont = is_last ? "   " : "│  "
        print(io, "\n", prefix, branch)
        _show_node(io, child, prefix * childcont)
    end
    if n > _SHOW_LIMIT
        print(io, "\n", prefix, fmt.muted, "… (", n - _SHOW_LIMIT, " more)", fmt.reset)
    end
end

"""
$(TYPEDSIGNATURES)

Compact one-line display of a [`Figure`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, fig::Figure)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "Figure", fmt.reset, "(")
    if fig.title !== nothing
        print(io, fmt.label, repr(fig.title), fmt.reset, ", ")
    end
    show(io, fig.root)
    print(io, ")")
end

"""
$(TYPEDSIGNATURES)

Pretty tree-style display of a [`Figure`](@ref), recursively
showing its layout tree.

See also: `Base.show`
"""
function Base.show(io::IO, ::MIME"text/plain", fig::Figure)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "Figure", fmt.reset)
    if fig.title !== nothing
        print(io, " ", fmt.label, repr(fig.title), fmt.reset)
    end
    if fig.size !== nothing
        print(io, "  size: ", fmt.value, fig.size, fmt.reset)
    end
    print(io, "\n└─ ")
    _show_node(io, fig.root, "   ")
end
