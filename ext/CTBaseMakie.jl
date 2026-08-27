module CTBaseMakie

# =============================================================================
# CTBaseMakie — the Makie.jl backend for CTBase.Plotting (proof of concept).
#
# It adds a method to `Plotting.render` on `MakieBackend`, turning the
# backend-agnostic IR (weighted tree of Axes) into a laid-out Makie.Figure: the
# weighted `HBox`/`VBox` tree maps directly onto nested `Makie.GridLayout`s with
# `rowsize!`/`colsize!` set to `Makie.Auto(weight)`.
#
# Scope (issue CTModels#366): `render` only, for the common `plot(sol)` shapes.
# NOT handled yet (tracked in the parity follow-up):
#   - `render!` (overlay) — throws `NotImplemented`;
#   - `Decoration`s (`HLine`/`VLine`);
#   - `:steppost` / `:scatter` series types — every series is drawn with `lines!`;
#   - `z_order`.
# This is the ONLY place that depends on Makie.
# =============================================================================

using Makie: Makie
using DocStringExtensions: TYPEDSIGNATURES

using CTBase: Plotting
using CTBase: Exceptions

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

Translate a neutral series `style` `NamedTuple` into Makie `lines!` attributes.

Keeps `color` (via [`_makie_color`](@ref)), `linewidth`, `linestyle` and `alpha`;
drops `seriestype` and `z_order` (not handled by this POC); merges
`backend_kwargs` as the escape hatch for raw Makie options.
"""
function _translate_style(style::NamedTuple)
    kept = NamedTuple()
    for k in keys(style)
        (k === :backend_kwargs || k === :z_order || k === :seriestype) && continue
        v = k === :color ? _makie_color(style[k]) : style[k]
        kept = merge(kept, NamedTuple{(k,)}((v,)))
    end
    return merge(kept, get(style, :backend_kwargs, NamedTuple()))
end

"""
    _SERIES_USER_KEYS

User keyword arguments forwarded to every `lines!` call by [`Plotting.render`](@extref);
all other user kwargs are ignored by this POC backend.
"""
const _SERIES_USER_KEYS = (:color, :linewidth, :linestyle, :alpha)

"""
$(TYPEDSIGNATURES)

Keep only the series-relevant user keyword arguments (`_SERIES_USER_KEYS`),
translating `color` the same way series styles are translated.
"""
function _series_user(kwargs)
    nt = NamedTuple()
    for (k, v) in kwargs
        k in _SERIES_USER_KEYS || continue
        v = k === :color ? _makie_color(v) : v
        nt = merge(nt, NamedTuple{(k,)}((v,)))
    end
    return nt
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

# --- drawing one Axes -------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Create a `Makie.Axis` at grid position `gp` and draw every [`CTBase.Plotting.Series`](@extref)
of `ax` into it with `Makie.lines!` (POC: all series types are drawn as lines).
`series_user` attributes are forwarded to every series. `ax.decorations` are
ignored by this POC backend.
"""
function _draw_axes!(gp, ax::Plotting.Axes; series_user=NamedTuple())
    axis = Makie.Axis(
        gp;
        title=ax.title,
        xlabel=ax.xlabel,
        ylabel=ax.ylabel,
        titlesize=Plotting._TITLE_FONT_SIZE,
        xlabelsize=Plotting._LABEL_FONT_SIZE,
        ylabelsize=Plotting._LABEL_FONT_SIZE,
    )
    for s in ax.series
        Makie.lines!(
            axis,
            s.x,
            s.y;
            label=(isempty(s.label) ? nothing : s.label),
            _translate_style(s.style)...,
            series_user...,
        )
    end
    yl = _resolve_ylims(ax)
    yl === nothing || Makie.ylims!(axis, yl[1], yl[2])
    if ax.legend && any(!isempty(s.label) for s in ax.series)
        Makie.axislegend(axis)
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
function _render_node!(gl, node::Plotting.Leaf; series_user=NamedTuple())
    _draw_axes!(gl[1, 1], node.axes; series_user=series_user)
    return gl
end
function _render_node!(gl, node::Plotting.VBox; series_user=NamedTuple())
    if length(node.children) == 1
        return _render_node!(gl, node.children[1]; series_user=series_user)
    end
    w = _normalized(node.weights)
    for (i, c) in enumerate(node.children)
        sub = gl[i, 1] = Makie.GridLayout()
        _render_node!(sub, c; series_user=series_user)
        Makie.rowsize!(gl, i, Makie.Auto(w[i]))
    end
    return gl
end
function _render_node!(gl, node::Plotting.HBox; series_user=NamedTuple())
    if length(node.children) == 1
        return _render_node!(gl, node.children[1]; series_user=series_user)
    end
    w = _normalized(node.weights)
    for (j, c) in enumerate(node.children)
        sub = gl[1, j] = Makie.GridLayout()
        _render_node!(sub, c; series_user=series_user)
        Makie.colsize!(gl, j, Makie.Auto(w[j]))
    end
    return gl
end

"""
$(TYPEDSIGNATURES)

Render `fig` into a new `Makie.Figure` (Makie backend, POC).

Series attributes among `kwargs` (`color`, `linewidth`, `linestyle`, `alpha`) are
forwarded to every series; other user kwargs are ignored. The figure size comes
from [`CTBase.Plotting.default_size`](@extref); a non-`nothing` `fig.title` is added as a
spanning `Makie.Label`.
"""
function Plotting.render(::Plotting.MakieBackend, fig::Plotting.Figure; kwargs...)
    su = _series_user(kwargs)
    f = Makie.Figure(; size=Plotting.default_size(fig))
    root = f[1, 1] = Makie.GridLayout()
    _render_node!(root, fig.root; series_user=su)
    if fig.title !== nothing
        Makie.Label(f[0, :], fig.title; fontsize=16, font=:bold)
    end
    return f
end

"""
$(TYPEDSIGNATURES)

Overlay is not implemented by the Makie POC backend.

# Throws
- `CTBase.Exceptions.NotImplemented`: always — Makie overlay is tracked in the
  parity follow-up of CTModels#366.
"""
function Plotting.render!(::Plotting.MakieBackend, target, ::Plotting.Figure; kwargs...)
    return throw(
        Exceptions.NotImplemented(
            "Makie overlay (render!) is not implemented";
            suggestion="use the Plots backend for overlays, or wait for the parity follow-up of CTModels#366",
            context="CTBaseMakie",
        ),
    )
end

end # module CTBaseMakie
