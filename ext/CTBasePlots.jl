module CTBasePlots

# =============================================================================
# CTBasePlots — the Plots.jl backend for CTBase.Plotting.
#
# It adds methods to `Plotting.render`/`render!` on `PlotsBackend`, turning the
# backend-agnostic IR (weighted tree of Axes) into a laid-out, styled Plots.Plot.
# This is the ONLY place that depends on Plots. It is a generalised port of the
# CTFlows PlotEngine: weighted layout, per-series style, decorations, x per cell.
#
# Docstrings deferred (Handbook convention).
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
const _TITLE_FONT = Plots.font(Plotting._TITLE_FONT_SIZE, Plots.default(:fontfamily))
const _LABEL_FONT_SIZE = Plotting._LABEL_FONT_SIZE
const _LEFT_MARGIN = 5 * Plots.Measures.mm
const _BOTTOM_MARGIN = 5 * Plots.Measures.mm

# --- style translation : neutral vocabulary -> Plots attributes ---------------
# Neutral keys pass straight through (Plots understands them). `z_order` drives
# draw order (Plots has no z attribute), `backend_kwargs` is the escape hatch.
function _translate_style(style::NamedTuple)
    bk = get(style, :backend_kwargs, NamedTuple())
    kept = NamedTuple()
    for k in keys(style)
        (k === :backend_kwargs || k === :z_order) && continue
        kept = merge(kept, NamedTuple{(k,)}((style[k],)))
    end
    return merge(kept, bk)
end

_z(style::NamedTuple) = get(style, :z_order, :normal)
_z_rank(z::Symbol) =
    if z === :back
        0
    elseif z === :front
        2
    else
        1
    end

# Keep only user kwargs that Plots accepts as series attributes (R2).
function _keep_series_attributes(; kwargs...)
    ok = Plots.attributes(:Series)
    return NamedTuple(kw for kw in kwargs if kw[1] in ok)
end

# --- ylims resolution ---------------------------------------------------------
# `nothing` -> don't touch; tuple -> set; :auto -> auto; :auto_guarded -> widen a
# (near-)constant series so the axis does not collapse.
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

function _draw_decoration!(p, d::HLine, sp::Int)
    Plots.hline!(p, [d.value]; subplot=sp, label="", _translate_style(d.style)...)
    return p
end
function _draw_decoration!(p, d::VLine, sp::Int)
    Plots.vline!(p, [d.value]; subplot=sp, label="", _translate_style(d.style)...)
    return p
end

# Draw series (in z-order) + decorations of `ax` into subplot `sp`. When
# `overlay` is true, only series/decorations are added (axis metadata untouched).
function _draw_axes!(p, ax::Axes, sp::Int; overlay::Bool=false, user...)
    order = sortperm(collect(1:length(ax.series)); by=i -> _z_rank(_z(ax.series[i].style)))
    for i in order
        _draw_series!(p, ax.series[i], sp; user...)
    end
    for d in ax.decorations
        _draw_decoration!(p, d, sp)
    end
    overlay && return p
    yl = _resolve_ylims(ax)
    attrs = (;
        subplot=sp,
        title=ax.title,
        xlabel=ax.xlabel,
        ylabel=ax.ylabel,
        legend=(ax.legend ? :best : false),
        titlefont=_TITLE_FONT,
        guidefontsize=_LABEL_FONT_SIZE,
    )
    yl === nothing ? Plots.plot!(p; attrs...) : Plots.plot!(p; attrs..., ylims=yl)
    return p
end

# --- new render : recursive composition of the weighted tree ------------------

_normalized(w) = collect(Float64, w) ./ sum(w)

function _render_node(node::Leaf; user...)
    p = Plots.plot()
    _draw_axes!(p, node.axes, 1; user...)
    return p
end
# A single-child box carries no geometry of its own: render the child directly
# (Plots.grid rejects a lone height/width of 1.0, and a 1×1 wrapper is useless).
function _render_node(node::VBox; user...)
    length(node.children) == 1 && return _render_node(node.children[1]; user...)
    subs = [_render_node(c; user...) for c in node.children]
    return Plots.plot(
        subs...; layout=Plots.grid(length(subs), 1; heights=_normalized(node.weights))
    )
end
function _render_node(node::HBox; user...)
    length(node.children) == 1 && return _render_node(node.children[1]; user...)
    subs = [_render_node(c; user...) for c in node.children]
    return Plots.plot(
        subs...; layout=Plots.grid(1, length(subs); widths=_normalized(node.weights))
    )
end

"""
$(TYPEDSIGNATURES)

Render `fig` into a new `Plots.Plot` (Plots backend). User `kwargs` are filtered
to Plots series attributes and forwarded to every series.
"""
function render(::PlotsBackend, fig::Figure; kwargs...)
    user = _keep_series_attributes(; kwargs...)
    p = _render_node(fig.root; user...)
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
    user = _keep_series_attributes(; kwargs...)
    for (i, leaf) in enumerate(leaves(fig.root))
        _draw_axes!(target, leaf.axes, i; overlay=true, user...)
    end
    return target
end

end # module CTBasePlots
