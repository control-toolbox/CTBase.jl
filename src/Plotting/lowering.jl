# =============================================================================
# lowering.jl — Panel -> layout node (Leaf / VBox of Leaves).
#
# Pure, backend-free. Turns a Panel into IR cells:
#   - :split -> one cell per component (ylabel = component name, xlabel on the
#     bottom cell only, title on the top cell only, no legend);
#   - :group -> one cell, components overlaid, a legend to tell them apart.
# Applies the time transform, the ylims guard, per-component style, and attaches
# decorations (shared vertical lines to every cell; per-component horizontal
# lines to their cell in :split, all merged into the single cell in :group).
# =============================================================================

"""
$(TYPEDSIGNATURES)

Compute the plotted time axis from the `time` option.

# Arguments
- `times`: the original time grid.
- `time::Symbol`: `:default` (real time), `:normalize` or `:normalise` (rescale to `[0, 1]`).

# Returns
- `Vector{Float64}`: the transformed time axis.

# Throws
- `CTBase.Exceptions.IncorrectArgument`: if `time` is not one of the accepted symbols.
"""
function _time_axis(times, time::Symbol)
    if time === :default
        return collect(float.(times))
    elseif time === :normalize || time === :normalise
        t0, tf = first(times), last(times)
        return tf > t0 ? collect((times .- t0) ./ (tf - t0)) : collect(float.(times .- t0))
    else
        throw(
            Exceptions.IncorrectArgument(
                "Invalid time normalization";
                got="time=$time",
                expected=":default, :normalize or :normalise",
                context="Plotting._time_axis",
            ),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Y-range guard for a (near-)constant series: widen the limits so the axis does not
collapse to a line.

# Returns
- `(lo, hi)::Tuple{Float64,Float64}` when the series is (near-)constant, `:auto` otherwise.
"""
function _ylims_guard(y::AbstractArray)
    isempty(y) && return :auto
    lo, hi = extrema(y)
    return (hi - lo) ≤ 1e-8 ? (lo - 1.0, hi + 1.0) : :auto
end

"""
$(TYPEDSIGNATURES)

Collect decorations for component `i` in `:split` layout: its own horizontal lines
(`hlines[i]` if present), the shared vertical lines, then the annotations when `i` is
the top cell.

# Returns
- `Vector{Decoration}`: the merged decoration list for the cell.
"""
function _cell_decorations(hlines, vlines, i::Integer, annotations=Annotation[])
    own = (i ≤ length(hlines)) ? hlines[i] : HLine[]
    texts = i == 1 ? annotations : Annotation[]
    return Decoration[own..., vlines..., texts...]
end

"""
$(TYPEDSIGNATURES)

Lower a [`CTBase.Plotting.Panel`](@extref) into a layout node.

# Keyword arguments
- `layout`: `:split` (one cell per component) or `:group` (one cell, components
  overlaid with a legend).
- `time`: `:default` (real time) or `:normalize`/`:normalise` (rescale to `[0, 1]`).
- `time_name`: x-axis label carried by the bottom cell (`:split`) or the cell
  (`:group`).
- `vlines`: vertical reference lines attached to **every** produced cell (e.g.
  initial/final time markers).
- `hlines`: per-component horizontal reference lines; `hlines[i]` is attached to
  component `i` in `:split`, and all are merged into the single cell in `:group`.
- `annotations`: texts (e.g. phase labels) attached to the **top** cell in `:split`
  (the one that carries the title) and to the single cell in `:group`. Like `vlines`,
  their abscissae are given in the plotted time (already normalised under
  `time=:normalize`).
"""
function lower(
    p::Panel;
    layout::Symbol=__layout(),
    time::Symbol=__time(),
    time_name::String="t",
    vlines::AbstractVector{VLine}=VLine[],
    hlines::AbstractVector=Vector{HLine}[],
    annotations::AbstractVector{Annotation}=Annotation[],
)
    x = _time_axis(p.x, time)
    if layout === :split
        return _lower_split(p, x, time_name, vlines, hlines, annotations)
    elseif layout === :group
        return _lower_group(p, x, time_name, vlines, hlines, annotations)
    else
        throw(
            Exceptions.IncorrectArgument(
                "Invalid layout";
                got="layout=$layout",
                expected=":split or :group",
                context="Plotting.lower",
            ),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Lower a [`CTBase.Plotting.Panel`](@extref) into a `:split` layout node: one [`CTBase.Plotting.Leaf`](@extref) per component,
with ylabel = component name, xlabel on the bottom cell only, title on the top cell
only, and no legend. The annotations go to the top cell.
"""
function _lower_split(p::Panel, x, time_name, vlines, hlines, annotations=Annotation[])
    k = n_components(p)
    cells = AbstractLayoutNode[]
    for i in 1:k
        y = p.data[:, i]
        ax = Axes(
            [Series(x, y; label="", style=component_style(p, i))];
            title=(i == 1 ? p.title : ""),
            ylabel=p.labels[i],
            xlabel=(i == k ? time_name : ""),
            decorations=_cell_decorations(hlines, vlines, i, annotations),
            legend=false,
            ylims=_ylims_guard(y),
        )
        push!(cells, Leaf(ax))
    end
    return length(cells) == 1 ? cells[1] : VBox(cells, ones(k))
end

"""
$(TYPEDSIGNATURES)

Lower a [`CTBase.Plotting.Panel`](@extref) into a `:group` layout node: a single [`CTBase.Plotting.Leaf`](@extref) with all
components overlaid and a legend to distinguish them, carrying every decoration.
"""
function _lower_group(p::Panel, x, time_name, vlines, hlines, annotations=Annotation[])
    k = n_components(p)
    series = [
        Series(x, p.data[:, i]; label=p.labels[i], style=component_style(p, i)) for i in 1:k
    ]
    merged = Decoration[]
    for hl in hlines
        append!(merged, hl)
    end
    append!(merged, vlines)
    append!(merged, annotations)
    ax = Axes(
        series;
        title=p.title,
        xlabel=time_name,
        decorations=merged,
        legend=true,
        ylims=_ylims_guard(p.data),
    )
    return Leaf(ax)
end
