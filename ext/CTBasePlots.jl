module CTBasePlots

# =============================================================================
# CTBasePlots — the Plots.jl backend for CTBase.Plotting.
#
# It adds methods to `Plotting.render`/`render!` on `PlotsBackend`, turning the
# backend-agnostic IR (weighted tree of Axes) into a laid-out, styled Plots.Plot.
# This is the ONLY place that depends on Plots. It is a generalised port of the
# CTFlows PlotEngine: weighted layout, per-series style, decorations, x per cell.
# =============================================================================

using Plots: Plots
import DocStringExtensions: TYPEDSIGNATURES

import CTBase.Plotting:
    Plotting,
    PlotsBackend,
    Figure,
    Axes,
    Series,
    HLine,
    VLine,
    Decoration,
    Leaf,
    HBox,
    VBox,
    AbstractLayoutNode,
    leaves,
    default_size,
    render,
    render!

# --- fonts / margins (semantic sizes come from src; Plots objects made here) --
"""
    _TITLE_FONT

Title font object built from the semantic size [`Plotting._TITLE_FONT_SIZE`](@ref).
"""
const _TITLE_FONT = Plots.font(Plotting._TITLE_FONT_SIZE, Plots.default(:fontfamily))

"""
    _LABEL_FONT_SIZE

Label font size, forwarded from [`Plotting._LABEL_FONT_SIZE`](@ref).
"""
const _LABEL_FONT_SIZE = Plotting._LABEL_FONT_SIZE

"""
    _LEFT_MARGIN

Left margin (5 mm) applied to every rendered figure.
"""
const _LEFT_MARGIN = 5 * Plots.Measures.mm

"""
    _BOTTOM_MARGIN

Bottom margin (5 mm) applied to every rendered figure.
"""
const _BOTTOM_MARGIN = 5 * Plots.Measures.mm

# --- style translation : neutral vocabulary -> Plots attributes ---------------
"""
$(TYPEDSIGNATURES)

Translate a neutral style `NamedTuple` into Plots-compatible attributes.

`z_order` is dropped (Plots has no z attribute; it drives draw order instead) and
`backend_kwargs` is merged in as the escape hatch for raw Plots options.
"""
function _translate_style(style::NamedTuple)
    bk = get(style, :backend_kwargs, NamedTuple())
    kept = NamedTuple()
    for k in keys(style)
        (k === :backend_kwargs || k === :z_order) && continue
        kept = merge(kept, NamedTuple{(k,)}((style[k],)))
    end
    return merge(kept, bk)
end

"""
$(TYPEDSIGNATURES)

Extract the `z_order` from a style `NamedTuple`, defaulting to `:normal`.
"""
_z(style::NamedTuple) = get(style, :z_order, :normal)

"""
$(TYPEDSIGNATURES)

Map a `z_order` symbol to a numeric rank for draw-order sorting: `:back` → 0,
`:normal` → 1, `:front` → 2.
"""
_z_rank(z::Symbol) =
    if z === :back
        0
    elseif z === :front
        2
    else
        1
    end

"""
$(TYPEDSIGNATURES)

Split user keyword arguments into series attributes (accepted by `Plots.attributes(:Series)`)
and the remaining subplot/plot attributes.

# Returns
- `(series, other)`: two `NamedTuple`s — series attributes and everything else.
"""
function _partition_user(; kwargs...)
    ok = Plots.attributes(:Series)
    series = NamedTuple(kw for kw in kwargs if kw[1] in ok)
    other = NamedTuple(kw for kw in kwargs if !(kw[1] in ok))
    return series, other
end

"""
    _RESERVED_AXES_KEYS

Subplot metadata keys that the renderer sets itself; user overrides of these
(except `legend` and `ylims`, handled explicitly) are ignored to preserve the
computed layout.
"""
const _RESERVED_AXES_KEYS = (
    :subplot, :title, :xlabel, :ylabel, :legend, :ylims, :titlefont, :guidefontsize
)

# --- ylims resolution ---------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Resolve the y-axis limits for `ax`.

`nothing` is passed through; a tuple is used as-is; `:auto` delegates to Plots;
`:auto_guarded` widens a (near-)constant series so the axis does not collapse.
"""
function _resolve_ylims(ax::Axes)
    yl = ax.ylims
    yl === :auto_guarded || return yl
    isempty(ax.series) && return :auto
    ys = reduce(vcat, (s.y for s in ax.series))
    isempty(ys) && return :auto
    lo, hi = extrema(ys)
    return (hi - lo) ≤ 1e-8 ? (lo - 1.0, hi + 1.0) : :auto
end

# --- drawing one Axes into subplot `sp` of plot `p` ---------------------------

"""
$(TYPEDSIGNATURES)

Draw a single [`Series`](@ref) `s` into subplot `sp` of plot `p`, forwarding
`user` keyword arguments and the translated series style.
"""
function _draw_series!(p, s::Series, sp::Int; user...)
    Plots.plot!(
        p,
        s.x,
        s.y;
        subplot=sp,
        label=(isempty(s.label) ? "" : s.label),
        user...,
        _translate_style(s.style)...,
    )
    return p
end

"""
$(TYPEDSIGNATURES)

Draw a decoration (`HLine` or `VLine`) into subplot `sp` of plot `p`.
"""
function _draw_decoration!(p, d::HLine, sp::Int)
    Plots.hline!(p, [d.value]; subplot=sp, label="", _translate_style(d.style)...)
    return p
end
function _draw_decoration!(p, d::VLine, sp::Int)
    Plots.vline!(p, [d.value]; subplot=sp, label="", _translate_style(d.style)...)
    return p
end

"""
$(TYPEDSIGNATURES)

Draw all series (in z-order) and decorations of `ax` into subplot `sp` of plot `p`.

`series_user` are forwarded to every series; `axes_user` are subplot attributes
applied to the cell, with `legend`/`ylims` overriding the IR defaults. When
`overlay` is true, only series and decorations are added (axis metadata untouched).
"""
function _draw_axes!(
    p,
    ax::Axes,
    sp::Int;
    overlay::Bool=false,
    series_user=NamedTuple(),
    axes_user=NamedTuple(),
)
    order = sortperm(collect(1:length(ax.series)); by=i -> _z_rank(_z(ax.series[i].style)))
    for i in order
        _draw_series!(p, ax.series[i], sp; series_user...)
    end
    for d in ax.decorations
        _draw_decoration!(p, d, sp)
    end
    overlay && return p
    # user `legend` / `ylims` override the IR defaults; other user subplot attributes
    # (grid, framestyle, …) are applied as-is; reserved metadata keys are protected.
    legend_val = get(axes_user, :legend, ax.legend ? :best : false)
    yl = haskey(axes_user, :ylims) ? axes_user[:ylims] : _resolve_ylims(ax)
    extra = NamedTuple(kw for kw in pairs(axes_user) if !(kw[1] in _RESERVED_AXES_KEYS))
    attrs = (;
        subplot=sp,
        title=ax.title,
        xlabel=ax.xlabel,
        ylabel=ax.ylabel,
        legend=legend_val,
        titlefont=_TITLE_FONT,
        guidefontsize=_LABEL_FONT_SIZE,
    )
    if yl === nothing
        Plots.plot!(p; attrs..., extra...)
    else
        Plots.plot!(p; attrs..., ylims=yl, extra...)
    end
    return p
end

# --- new render : recursive composition of the weighted tree ------------------

"""
$(TYPEDSIGNATURES)

Normalise weights `w` to a `Vector{Float64}` that sums to 1.
"""
_normalized(w) = collect(Float64, w) ./ sum(w)

"""
$(TYPEDSIGNATURES)

Recursively render a layout node into a `Plots.Plot`.

`Leaf` produces a single-axes plot; `VBox`/`HBox` compose child plots with a
weighted grid layout. A single-child box is unwrapped (Plots rejects a lone
height/width of 1.0).
"""
function _render_node(node::Leaf; series_user=NamedTuple(), axes_user=NamedTuple())
    p = Plots.plot()
    _draw_axes!(p, node.axes, 1; series_user=series_user, axes_user=axes_user)
    return p
end
# A single-child box carries no geometry of its own: render the child directly
# (Plots.grid rejects a lone height/width of 1.0, and a 1×1 wrapper is useless).
function _render_node(node::VBox; series_user=NamedTuple(), axes_user=NamedTuple())
    if length(node.children) == 1
        return _render_node(node.children[1]; series_user=series_user, axes_user=axes_user)
    end
    subs = [
        _render_node(c; series_user=series_user, axes_user=axes_user) for c in node.children
    ]
    return Plots.plot(
        subs...; layout=Plots.grid(length(subs), 1; heights=_normalized(node.weights))
    )
end
function _render_node(node::HBox; series_user=NamedTuple(), axes_user=NamedTuple())
    if length(node.children) == 1
        return _render_node(node.children[1]; series_user=series_user, axes_user=axes_user)
    end
    subs = [
        _render_node(c; series_user=series_user, axes_user=axes_user) for c in node.children
    ]
    return Plots.plot(
        subs...; layout=Plots.grid(1, length(subs); widths=_normalized(node.weights))
    )
end

"""
$(TYPEDSIGNATURES)

Render `fig` into a new `Plots.Plot` (Plots backend). Series attributes among
`kwargs` (`color`, `linewidth`, `label`, …) are forwarded to every series; the rest
(`legend`, `grid`, …) are applied to every cell.
"""
function render(::PlotsBackend, fig::Figure; kwargs...)
    series_user, axes_user = _partition_user(; kwargs...)
    p = _render_node(fig.root; series_user=series_user, axes_user=axes_user)
    sz = default_size(fig)
    root_attrs = (; size=sz, left_margin=_LEFT_MARGIN, bottom_margin=_BOTTOM_MARGIN)
    if fig.title === nothing
        Plots.plot!(p; root_attrs...)
    else
        Plots.plot!(p; root_attrs..., plot_title=fig.title)
    end
    return p
end

"""
$(TYPEDSIGNATURES)

Overlay `fig` onto an existing Plots plot `target`, targeting existing subplots
by the deterministic leaf order. Series/decorations are added; axes untouched.
"""
function render!(::PlotsBackend, target, fig::Figure; kwargs...)
    series_user, axes_user = _partition_user(; kwargs...)
    for (i, leaf) in enumerate(leaves(fig.root))
        _draw_axes!(
            target, leaf.axes, i; overlay=true, series_user=series_user, axes_user=axes_user
        )
    end
    return target
end

end # module CTBasePlots
