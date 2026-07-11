# =============================================================================
# panel.jl — Panel: the case layer's convenient input unit, plus engine defaults.
#
# A Panel is a titled group of components sharing one time grid (e.g. all state
# components). It is *not* part of the rendered IR: the lowering turns Panels into
# Axes/Leaf nodes. Compared to the original CTFlows engine a Panel now carries:
#   - its OWN x grid          (multi-grid support: distinct grids per group),
#   - an optional per-component style vector (finer styling than one shared style).
# =============================================================================

"""
$(TYPEDEF)

A titled group of components sharing one time grid — the case layer's convenient
input unit (e.g. all state components). It is not part of the rendered IR: the
[`lower`](@ref) step turns a `Panel` into [`Leaf`](@ref)/[`Axes`](@ref) nodes.

Each panel carries **its own** time grid `x` (so different groups may live on
different grids) and, optionally, a per-component `styles` vector (finer than the
single shared `style`). `data` is `(n_times, n_components)`.

# Fields
$(TYPEDFIELDS)
"""
struct Panel
    x::Vector{Float64}          # this panel's own time grid
    title::String
    labels::Vector{String}      # one name per component
    data::Matrix{Float64}       # (n_times, n_components)
    style::NamedTuple           # shared default style
    styles::Vector{NamedTuple}  # [] -> use `style`; else one style per component
end

function Panel(
    x::AbstractVector,
    data::AbstractMatrix;
    title::AbstractString="",
    labels::AbstractVector=String[],
    style::NamedTuple=NamedTuple(),
    styles::AbstractVector=NamedTuple[],
)
    n, k = size(data)
    length(x) == n || throw(
        Exceptions.IncorrectArgument(
            "a Panel needs x and data with matching time length";
            got="length(x)=$(length(x)), size(data,1)=$n",
            expected="length(x) == size(data, 1)",
        ),
    )
    lbls = isempty(labels) ? fill("", k) : collect(String, labels)
    length(lbls) == k || throw(
        Exceptions.IncorrectArgument(
            "a Panel needs one label per component";
            got="$(length(lbls)) labels, $k components",
            expected="length(labels) == size(data, 2)",
        ),
    )
    sty = collect(NamedTuple, styles)
    (isempty(sty) || length(sty) == k) || throw(
        Exceptions.IncorrectArgument(
            "per-component styles must match the number of components";
            got="$(length(sty)) styles, $k components",
            expected="length(styles) == 0 or == size(data, 2)",
        ),
    )
    return Panel(
        collect(Float64, x), String(title), lbls, collect(Float64, data), style, sty
    )
end

"""
$(TYPEDSIGNATURES)

Return the number of components (columns) of a [`Panel`](@ref).
"""
n_components(p::Panel) = size(p.data, 2)

"""
$(TYPEDSIGNATURES)

Return the style to apply to component `i` of a [`Panel`](@ref): its own per-component
style if a `styles` vector is set, otherwise the shared `style`.
"""
component_style(p::Panel, i::Integer) = isempty(p.styles) ? p.style : p.styles[i]

# =============================================================================
# Replaceable defaults (double-underscore = semantic default a caller may override)
# =============================================================================

"""
$(TYPEDSIGNATURES)

Default overall layout for [`lower`](@ref): `:split` (one subplot per component).
Alternative: `:group`.
"""
__layout() = :split

"""
$(TYPEDSIGNATURES)

Default time-axis handling for [`lower`](@ref): `:default` (real time).
Alternatives: `:normalize` / `:normalise`.
"""
__time() = :default

"""
$(TYPEDSIGNATURES)

Default series style: an empty `NamedTuple` (no override).
"""
__style() = NamedTuple()

# Semantic font sizes (points). Kept backend-free here; the Plots renderer turns
# them into `Plots.font`. Consistent across the engine.
"""
Default title font size in points, used by the Plots renderer.
"""
const _TITLE_FONT_SIZE = 10

"""
Default axis-label font size in points, used by the Plots renderer.
"""
const _LABEL_FONT_SIZE = 10

# --- display -----------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Compact one-line display of a [`Panel`](@ref).

See also: `Base.show`
"""
function Base.show(io::IO, p::Panel)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "Panel", fmt.reset, "(")
    print(io, fmt.label, repr(p.title), fmt.reset, ", ")
    print(io, fmt.value, n_components(p), fmt.reset, " components, ")
    print(io, fmt.value, length(p.x), fmt.reset, " pts)")
end

"""
$(TYPEDSIGNATURES)

Pretty display of a [`Panel`](@ref), showing its title, labels,
and data dimensions.

See also: `Base.show`
"""
function Base.show(io::IO, ::MIME"text/plain", p::Panel)
    fmt = Core.get_format_codes(io)
    n = n_components(p)
    np = length(p.x)
    print(io, fmt.name, "Panel", fmt.reset, " ")
    print(io, fmt.label, repr(p.title), fmt.reset)
    print(io, " (", fmt.value, n, fmt.reset, n == 1 ? " component, " : " components, ")
    print(io, fmt.value, np, fmt.reset, np == 1 ? " point)" : " points)")
    named = findall(!isempty, p.labels)
    for (j, i) in enumerate(named)
        is_last = j == length(named)
        prefix = is_last ? "└─ " : "├─ "
        print(io, "\n", prefix, fmt.label, p.labels[i], fmt.reset)
    end
end
