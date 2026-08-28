module CTBaseMakie

# =============================================================================
# CTBaseMakie — the Makie.jl backend for CTBase.Plotting.
#
# It adds methods to `Plotting.render`/`render!` on `MakieBackend`, turning the
# backend-agnostic IR (weighted tree of Axes) into a laid-out, styled
# `Makie.Figure`: the weighted `HBox`/`VBox` tree maps onto nested
# `Makie.GridLayout`s with `rowsize!`/`colsize!` set to `Makie.Auto(weight)`.
# This is the ONLY place that depends on Makie. It mirrors the `CTBasePlots`
# backend feature for feature: weighted layout, per-series style, `seriestype`
# dispatch, `z_order` draw ordering, `HLine`/`VLine` decorations, user-kwarg
# partition and `render!` overlay.
# =============================================================================

using Makie: Makie
using DocStringExtensions: TYPEDSIGNATURES

using CTBase: Plotting

# --- style translation : neutral vocabulary -> Makie attributes ---------------

"""
$(TYPEDSIGNATURES)

Translate a neutral colour into one Makie understands: an integer is read as a
palette index (`Makie.Cycled`), anything else (a `Symbol`, a `Colorant`, a string)
is passed through unchanged.
"""
_makie_color(c::Integer) = Makie.Cycled(c)
_makie_color(c) = c

"""
$(TYPEDSIGNATURES)

Return the neutral `seriestype` of a style `NamedTuple` (`:path` when absent).
"""
_seriestype(style::NamedTuple) = get(style, :seriestype, :path)

"""
$(TYPEDSIGNATURES)

Return the `z_order` of a style `NamedTuple`, defaulting to `:normal`.
"""
_z(style::NamedTuple) = get(style, :z_order, :normal)

"""
$(TYPEDSIGNATURES)

Map a `z_order` symbol to a numeric rank for draw-order sorting: `:back` → 0,
`:normal` → 1, `:front` → 2 (same ranking as the Plots backend).
"""
_z_rank(z::Symbol) = z === :back ? 0 : z === :front ? 2 : 1

"""
    _STYLE_DROP

Style keys consumed by the renderer itself (not forwarded as plot attributes):
`backend_kwargs` is the raw-Makie escape hatch, `z_order` drives draw order,
`seriestype` selects the plotting function, `label` is set explicitly per series.
"""
const _STYLE_DROP = (:backend_kwargs, :z_order, :seriestype, :label)

"""
$(TYPEDSIGNATURES)

Translate a neutral series/decoration `style` `NamedTuple` into Makie attributes:
keep `color` (via [`_makie_color`](@ref)), `linewidth`, `linestyle`, `alpha`, …;
drop the [`_STYLE_DROP`](@ref) keys; merge `backend_kwargs` last as the escape
hatch for raw Makie options.
"""
function _translate_style(style::NamedTuple)
    kept = NamedTuple()
    for k in keys(style)
        k in _STYLE_DROP && continue
        v = k === :color ? _makie_color(style[k]) : style[k]
        kept = merge(kept, NamedTuple{(k,)}((v,)))
    end
    return merge(kept, get(style, :backend_kwargs, NamedTuple()))
end

"""
$(TYPEDSIGNATURES)

Drop line-only attributes (`linewidth`, `linestyle`) that `Makie.scatter!` rejects.
"""
_drop_line_attrs(nt::NamedTuple) =
    NamedTuple(p for p in pairs(nt) if p[1] !== :linewidth && p[1] !== :linestyle)

# --- user keyword-argument partition -----------------------------------------

"""
    _SERIES_USER_KEYS

User keyword arguments forwarded to every series plot (`lines!` / `stairs!` /
`scatter!`).
"""
const _SERIES_USER_KEYS = (:color, :linewidth, :linestyle, :alpha, :marker, :markersize)

"""
    _AXIS_USER_KEYS

User keyword arguments forwarded to every `Makie.Axis` constructor. `legend` and
`ylims` are handled explicitly and are not in this list; any other unknown key is
silently ignored (the Plots backend warns; `Makie.Axis` cannot accept it).
"""
const _AXIS_USER_KEYS = (
    :xscale,
    :yscale,
    :xgridvisible,
    :ygridvisible,
    :xticksvisible,
    :yticksvisible,
    :xticklabelsvisible,
    :yticklabelsvisible,
    :xreversed,
    :yreversed,
    :xautolimitmargin,
    :yautolimitmargin,
    :xticks,
    :yticks,
    :aspect,
)

"""
    _RESERVED_AXES_KEYS

Axis keys the renderer sets itself; a user override of these (except `legend` /
`ylims`, handled explicitly) is ignored to preserve the computed layout.
"""
const _RESERVED_AXES_KEYS = (:title, :xlabel, :ylabel, :legend, :ylims)

"""
$(TYPEDSIGNATURES)

Split user keyword arguments into `(series_user, axes_user)`: series attributes
([`_SERIES_USER_KEYS`](@ref)) forwarded to every series, and axis attributes
([`_AXIS_USER_KEYS`](@ref) plus `legend` / `ylims`) forwarded to every cell.
Unrecognised keys are dropped.
"""
function _partition_user(; kwargs...)
    series = NamedTuple()
    axs = NamedTuple()
    for (k, v) in kwargs
        if k in _SERIES_USER_KEYS
            vv = k === :color ? _makie_color(v) : v
            series = merge(series, NamedTuple{(k,)}((vv,)))
        elseif k === :legend || k === :ylims || k in _AXIS_USER_KEYS
            axs = merge(axs, NamedTuple{(k,)}((v,)))
        end
    end
    return series, axs
end

# --- ylims resolution (ported from CTBasePlots._resolve_ylims) ----------------

"""
$(TYPEDSIGNATURES)

Resolve the y-axis limits for `ax`: `nothing`/`:auto` leave the Makie default;
a tuple is used as-is; `:auto_guarded` widens a (near-)constant series so the
axis does not collapse to a line.

# Returns
- `nothing` when Makie should auto-scale, or a `(lo, hi)` tuple to pin.
"""
function _resolve_ylims(ax::Plotting.Axes)
    yl = ax.ylims
    yl === nothing && return nothing
    yl isa Tuple && return yl
    yl === :auto && return nothing
    # :auto_guarded
    isempty(ax.series) && return nothing
    ys = reduce(vcat, (s.y for s in ax.series); init=Float64[])
    isempty(ys) && return nothing
    lo, hi = extrema(ys)
    return (hi - lo) ≤ 1e-8 ? (lo - 1.0, hi + 1.0) : nothing
end

"""
$(TYPEDSIGNATURES)

Map a Plots-style legend position symbol (`:bottomright`, `:topleft`, …) to the
closest `Makie.axislegend` position; unknown symbols fall back to `:rt`.
"""
function _legend_position(s::Symbol)
    m = (
        topright=:rt,
        topleft=:lt,
        bottomright=:rb,
        bottomleft=:lb,
        top=:ct,
        bottom=:cb,
        left=:lc,
        right=:rc,
        best=:rt,
    )
    return get(m, s, :rt)
end

# --- drawing one series / one decoration -------------------------------------

"""
$(TYPEDSIGNATURES)

Draw one [`CTBase.Plotting.Series`](@extref) into `axis`, dispatching on its neutral
`seriestype`: `:path` → `Makie.lines!`, `:steppost` → `Makie.stairs!(…; step=:post)`,
`:scatter` → `Makie.scatter!`. `user` keyword arguments and the translated style
are forwarded.
"""
function _draw_one!(axis, s::Plotting.Series; user...)
    attrs = _translate_style(s.style)
    lbl = isempty(s.label) ? nothing : s.label
    st = _seriestype(s.style)
    if st === :steppost
        Makie.stairs!(axis, s.x, s.y; step=:post, label=lbl, attrs..., user...)
    elseif st === :scatter
        Makie.scatter!(axis, s.x, s.y; label=lbl, _drop_line_attrs(attrs)..., user...)
    else
        Makie.lines!(axis, s.x, s.y; label=lbl, attrs..., user...)
    end
    return axis
end

"""
$(TYPEDSIGNATURES)

Draw a decoration (`HLine` or `VLine`) into `axis` via `Makie.hlines!` / `vlines!`,
with style translation. Decorations carry no legend entry.
"""
function _draw_decoration!(axis, d::Plotting.HLine)
    Makie.hlines!(axis, d.value; _translate_style(d.style)...)
    return axis
end
function _draw_decoration!(axis, d::Plotting.VLine)
    Makie.vlines!(axis, d.value; _translate_style(d.style)...)
    return axis
end

# --- drawing one Axes -------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Create a `Makie.Axis` at grid position `gp` for `ax`: title / labels / semantic
font sizes, the resolved y-limits (`ylims` in `axes_user` overrides the IR
default), and any forwarded [`_AXIS_USER_KEYS`](@ref) attribute.
"""
function _new_axis!(gp, ax::Plotting.Axes; axes_user=NamedTuple())
    extra = NamedTuple(p for p in pairs(axes_user) if !(p[1] in _RESERVED_AXES_KEYS))
    axis = Makie.Axis(
        gp;
        title=ax.title,
        xlabel=ax.xlabel,
        ylabel=ax.ylabel,
        titlesize=Plotting._TITLE_FONT_SIZE,
        xlabelsize=Plotting._LABEL_FONT_SIZE,
        ylabelsize=Plotting._LABEL_FONT_SIZE,
        extra...,
    )
    yl = haskey(axes_user, :ylims) ? axes_user[:ylims] : _resolve_ylims(ax)
    yl === nothing || Makie.ylims!(axis, yl[1], yl[2])
    return axis
end

"""
$(TYPEDSIGNATURES)

Draw every series of `ax` into `axis` in `z_order`, then its decorations.
`series_user` is forwarded to every series. When `overlay` is `false`, a legend is
added if the IR asks for one (or `legend` forces it) and any series is labelled;
`overlay=true` skips the legend (the target axis keeps its own).
"""
function _draw_into_axis!(
    axis,
    ax::Plotting.Axes;
    series_user=NamedTuple(),
    legend::Union{Bool,Symbol,Nothing}=nothing,
    overlay::Bool=false,
)
    order = sortperm(collect(1:length(ax.series)); by=i -> _z_rank(_z(ax.series[i].style)))
    for i in order
        _draw_one!(axis, ax.series[i]; series_user...)
    end
    for d in ax.decorations
        _draw_decoration!(axis, d)
    end
    overlay && return axis
    want_legend = legend === nothing ? ax.legend : (legend !== false)
    if want_legend && any(!isempty(s.label) for s in ax.series)
        if legend isa Symbol
            Makie.axislegend(axis; position=_legend_position(legend))
        else
            Makie.axislegend(axis)
        end
    end
    return axis
end

# --- recursive composition of the weighted tree ------------------------------

"""
$(TYPEDSIGNATURES)

Normalise weights `w` to a `Vector{Float64}` summing to 1.
"""
_normalized(w) = collect(Float64, w) ./ sum(w)

"""
$(TYPEDSIGNATURES)

Recursively render a layout `node` into the `Makie.GridLayout` `gl`.

- `Leaf` → one `Makie.Axis` at `gl[1, 1]`;
- `VBox` → children stacked in rows, `rowsize!(gl, i, Makie.Auto(wᵢ))` from the
  normalised weights;
- `HBox` → children side by side in columns, `colsize!(gl, j, Makie.Auto(wⱼ))`.

A single-child box is rendered directly into `gl` (it carries no geometry).
"""
function _render_node!(gl, node::Plotting.Leaf; series_user=NamedTuple(), axes_user=NamedTuple())
    axis = _new_axis!(gl[1, 1], node.axes; axes_user=axes_user)
    _draw_into_axis!(
        axis, node.axes; series_user=series_user, legend=get(axes_user, :legend, nothing)
    )
    return gl
end
function _render_node!(gl, node::Plotting.VBox; series_user=NamedTuple(), axes_user=NamedTuple())
    if length(node.children) == 1
        return _render_node!(
            gl, node.children[1]; series_user=series_user, axes_user=axes_user
        )
    end
    w = _normalized(node.weights)
    for (i, c) in enumerate(node.children)
        sub = gl[i, 1] = Makie.GridLayout()
        _render_node!(sub, c; series_user=series_user, axes_user=axes_user)
        Makie.rowsize!(gl, i, Makie.Auto(w[i]))
    end
    return gl
end
function _render_node!(gl, node::Plotting.HBox; series_user=NamedTuple(), axes_user=NamedTuple())
    if length(node.children) == 1
        return _render_node!(
            gl, node.children[1]; series_user=series_user, axes_user=axes_user
        )
    end
    w = _normalized(node.weights)
    for (j, c) in enumerate(node.children)
        sub = gl[1, j] = Makie.GridLayout()
        _render_node!(sub, c; series_user=series_user, axes_user=axes_user)
        Makie.colsize!(gl, j, Makie.Auto(w[j]))
    end
    return gl
end

# --- render / render! -------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Populate the `Makie.Figure` `f` with `fig`: the weighted tree becomes nested
`GridLayout`s, `kwargs` are partitioned by [`_partition_user`](@ref), and a
non-`nothing` `fig.title` is added as a spanning `Makie.Label`. Returns `f`.
"""
function _render_into!(f::Makie.Figure, fig::Plotting.Figure; kwargs...)
    series_user, axes_user = _partition_user(; kwargs...)
    root = f[1, 1] = Makie.GridLayout()
    _render_node!(root, fig.root; series_user=series_user, axes_user=axes_user)
    fig.title === nothing ||
        Makie.Label(f[0, :], fig.title; fontsize=16, font=:bold)
    return f
end

"""
$(TYPEDSIGNATURES)

Render `fig` into a new `Makie.Figure` (Makie backend). Series attributes among
`kwargs` (`color`, `linewidth`, `linestyle`, `alpha`, …) are forwarded to every
series; axis attributes (`legend`, `ylims`, grid/scale/ticks) to every cell. The
figure size comes from [`CTBase.Plotting.default_size`](@extref).
"""
function Plotting.render(::Plotting.MakieBackend, fig::Plotting.Figure; kwargs...)
    return _render_into!(Makie.Figure(; size=Plotting.default_size(fig)), fig; kwargs...)
end

"""
$(TYPEDSIGNATURES)

Overlay `fig` onto an existing `Makie.Figure` `target`, pairing each leaf of the
layout tree with the target's `Makie.Axis` blocks in deterministic
[`CTBase.Plotting.leaves`](@extref) order; only series and decorations are added, the
axes are left untouched. An empty `target` (no axes yet) is filled as if by
[`CTBase.Plotting.render`](@extref).
"""
function Plotting.render!(
    ::Plotting.MakieBackend, target::Makie.Figure, fig::Plotting.Figure; kwargs...
)
    axs = [c for c in target.content if c isa Makie.Axis]
    isempty(axs) && return _render_into!(target, fig; kwargs...)
    series_user, _ = _partition_user(; kwargs...)
    for (i, leaf) in enumerate(Plotting.leaves(fig.root))
        i <= length(axs) || break
        _draw_into_axis!(axs[i], leaf.axes; series_user=series_user, overlay=true)
    end
    return target
end

end # module CTBaseMakie
