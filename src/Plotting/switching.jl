# =============================================================================
# switching.jl — case-layer building blocks for trajectories made of phases.
#
# A trajectory computed phase by phase (an indirect method with a fixed structure) has
# switching times, at which the state, costate or control may jump, and a label per
# phase. These helpers turn that structure into plot data, for any case layer: the
# samples of a panel with both limits at every switching time (a jump is drawn as a
# vertical segment), the vertical lines at the switching times, and the phase labels as
# texts. They know nothing of solutions or flows: the case layer reads the switching
# times, the limits and the labels, and passes them as plain data.
# =============================================================================

"""
Default style of the phase labels written by [`CTBase.Plotting.phase_annotations`](@extref):
grey text, of the default size of an [`CTBase.Plotting.Annotation`](@extref).
"""
const _PHASE_LABEL_STYLE = (color=:gray30,)

"""
$(TYPEDSIGNATURES)

Return the plotted abscissa of time `t` for a trajectory sampled on `x`: `t` itself with
`time = :default`, `t` rescaled to `[0, 1]` over `[first(x), last(x)]` with
`time = :normalize` / `:normalise` — the transform [`CTBase.Plotting.lower`](@extref)
applies to the abscissae of a panel.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): if `time` is not one of these symbols.
"""
function _plotted_time(t::Real, x::AbstractVector{<:Real}, time::Symbol)::Float64
    return _time_axis([first(x), t, last(x)], time)[2]
end

"""
$(TYPEDSIGNATURES)

Insert the left and right limits at the switching times into the samples of a panel, so
that a jump is drawn as a vertical segment.

At every switching time `τ = times[i]`, the rows `left[i, :]` then `right[i, :]` are
inserted at `τ`, in time order; a sample already at `τ` is replaced by these two rows.
The samples are returned unchanged when there is no switching time, or when the limits
are not known (matrices with no column).

With `connect = true` (default), the curve goes from the left to the right limit: a jump
is drawn as a vertical segment. This makes jumps easy to see, and to compare with a
solution whose jump is smoothed (e.g. from a direct method). With `connect = false`, a row
of `NaN` is inserted between the two limits: both backends break the curve there, so the
curve ends at the left limit and starts again at the right limit, with no segment that
could be read as values taken by the trajectory.

# Arguments
- `x::AbstractVector{<:Real}`: the sample times, increasing.
- `data::AbstractMatrix{<:Real}`: the samples, one row per time, one column per component.
- `times::AbstractVector{<:Real}`: the switching times, increasing.
- `left`, `right::AbstractMatrix{<:Real}`: the limits before and after each switching time,
  one row per switching time, one column per component (or no column: not known).
- `connect::Bool = true`: draw a jump as a vertical segment (`true`) or break the curve
  (`false`).

# Returns
- `(x, data)`: the sample times (each switching time twice, three times with
  `connect = false`) and the samples, as `Vector{Float64}` and `Matrix{Float64}`.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): if `left` or `right` does not have one
  row per switching time, or its number of columns differs from that of `data`.

# Example
```julia-repl
julia> using CTBase: Plotting

julia> x, data = Plotting.splice_jumps([0.0, 1.0, 2.0], [0.0; 1.0; 2.0;;], [1.0], [1.0;;], [3.0;;]);

julia> x
4-element Vector{Float64}:
 0.0
 1.0
 1.0
 2.0

julia> vec(data)
4-element Vector{Float64}:
 0.0
 1.0
 3.0
 2.0
```

See also: [`CTBase.Plotting.switching_vlines`](@extref), [`CTBase.Plotting.phase_annotations`](@extref).
"""
function splice_jumps(
    x::AbstractVector{<:Real},
    data::AbstractMatrix{<:Real},
    times::AbstractVector{<:Real},
    left::AbstractMatrix{<:Real},
    right::AbstractMatrix{<:Real};
    connect::Bool=true,
)
    isempty(times) && return (collect(Float64, x), Matrix{Float64}(data))
    size(left, 2) == 0 && size(right, 2) == 0 &&
        return (collect(Float64, x), Matrix{Float64}(data))
    for (name, L) in (("left", left), ("right", right))
        size(L) == (length(times), size(data, 2)) || throw(
            Exceptions.IncorrectArgument(
                "the $name limits do not match the samples";
                got="a $(size(L, 1)) × $(size(L, 2)) matrix",
                expected="$(length(times)) × $(size(data, 2)) (one row per switching " *
                         "time, one column per component)",
                suggestion="give one row of limits per switching time, with the " *
                           "components of the samples",
                context="Plotting.splice_jumps",
            ),
        )
    end
    xs = Float64[]
    rows = Vector{Vector{Float64}}()
    i = 1
    for k in eachindex(x)
        while i <= length(times) && times[i] <= x[k]
            _push_limits!(xs, rows, times[i], left[i, :], right[i, :], connect)
            i += 1
        end
        # a sample exactly at a switching time is replaced by its two limits
        (i > 1 && x[k] == times[i - 1]) && continue
        push!(xs, x[k])
        push!(rows, data[k, :])
    end
    while i <= length(times)   # switching times after the last sample
        _push_limits!(xs, rows, times[i], left[i, :], right[i, :], connect)
        i += 1
    end
    return (xs, Matrix{Float64}(permutedims(reduce(hcat, rows))))
end

"""
$(TYPEDSIGNATURES)

Append the left and right limits at the switching time `τ` to the sample times `xs` and
rows `rows`; with `connect = false`, a row of `NaN` between them breaks the curve.
"""
function _push_limits!(xs, rows, τ, left, right, connect::Bool)
    if connect
        push!(xs, τ, τ)
        push!(rows, left, right)
    else
        push!(xs, τ, τ, τ)
        push!(rows, left, fill(NaN, length(left)), right)
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Return the vertical lines at the switching times `times` of a trajectory sampled on `x`,
in plotted time (see `time`), to be passed to [`CTBase.Plotting.lower`](@extref) as
`vlines`. Empty when there is no switching time.

# Arguments
- `x::AbstractVector{<:Real}`: the time grid of the trajectory (its first and last times
  give the normalisation).
- `times::AbstractVector{<:Real}`: the switching times.
- `time::Symbol = :default`: `:default`, `:normalize` or `:normalise`, as for
  [`CTBase.Plotting.lower`](@extref).
- `style::NamedTuple = NamedTuple()`: the style of the lines.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): if `time` is not one of the accepted
  symbols.

See also: [`CTBase.Plotting.phase_annotations`](@extref).
"""
function switching_vlines(
    x::AbstractVector{<:Real},
    times::AbstractVector{<:Real};
    time::Symbol=:default,
    style::NamedTuple=NamedTuple(),
)::Vector{VLine}
    return VLine[VLine(_plotted_time(τ, x, time); style=style) for τ in times]
end

"""
$(TYPEDSIGNATURES)

Return the labels of the phases of a trajectory as texts, centred on each phase near the
top of the cell, to be passed to [`CTBase.Plotting.lower`](@extref) as `annotations`.

The phases are the intervals between the first time of `x`, the switching times and the
last time of `x`. A phase with an empty label gets no text, so a trajectory with no label
gets none.

# Arguments
- `x::AbstractVector{<:Real}`: the time grid of the trajectory.
- `times::AbstractVector{<:Real}`: the switching times.
- `labels::AbstractVector{<:AbstractString}`: one label per phase (`""` for no label), or
  none at all.
- `time::Symbol = :default`: `:default`, `:normalize` or `:normalise`, as for
  [`CTBase.Plotting.lower`](@extref).
- `style::NamedTuple = NamedTuple()`: merged on top of the default style (grey text).

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): if there is neither no label nor one
  label per phase, or if `time` is not one of the accepted symbols.

# Example
```julia-repl
julia> using CTBase: Plotting

julia> a = Plotting.phase_annotations([0.0, 1.0, 2.0], [1.0], ["bang", "singular"]);

julia> [(t.x, t.text) for t in a]
2-element Vector{Tuple{Float64, String}}:
 (0.5, "bang")
 (1.5, "singular")
```

See also: [`CTBase.Plotting.switching_vlines`](@extref), [`CTBase.Plotting.Annotation`](@extref).
"""
function phase_annotations(
    x::AbstractVector{<:Real},
    times::AbstractVector{<:Real},
    labels::AbstractVector{<:AbstractString};
    time::Symbol=:default,
    style::NamedTuple=NamedTuple(),
)::Vector{Annotation}
    any(!isempty, labels) || return Annotation[]
    length(labels) == length(times) + 1 || throw(
        Exceptions.IncorrectArgument(
            "one label per phase";
            got="$(length(labels)) label(s) for $(length(times) + 1) phase(s)",
            expected="$(length(times) + 1) labels (one more than the switching times)",
            suggestion="give \"\" for a phase with no label",
            context="Plotting.phase_annotations",
        ),
    )
    bounds = vcat(first(x), times, last(x))
    s = merge(_PHASE_LABEL_STYLE, style)
    return Annotation[
        Annotation(_plotted_time((bounds[k] + bounds[k + 1]) / 2, x, time), labels[k]; style=s)
        for k in eachindex(labels) if !isempty(labels[k])
    ]
end
