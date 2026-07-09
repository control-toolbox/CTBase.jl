# =============================================================================
# ir.jl — the intermediate representation (pure data, no backend dependency)
#
# Docstrings are intentionally deferred (Handbook convention: docstrings last).
# Brief comments here document structure and invariants only.
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

# Number of drawable cells in a node/figure.
n_leaves(node::AbstractLayoutNode) = length(leaves(node))
n_leaves(fig::Figure) = n_leaves(fig.root)
