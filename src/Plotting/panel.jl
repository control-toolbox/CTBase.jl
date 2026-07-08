# =============================================================================
# panel.jl — Panel: the case layer's convenient input unit, plus engine defaults.
#
# A Panel is a titled group of components sharing one time grid (e.g. all state
# components). It is *not* part of the rendered IR: the lowering turns Panels into
# Axes/Leaf nodes. Compared to the original CTFlows engine a Panel now carries:
#   - its OWN x grid          (multi-grid support: distinct grids per group),
#   - an optional per-component style vector (finer styling than one shared style).
#
# Docstrings deferred (Handbook convention). Comments document structure only.
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

# Number of components (columns) of a panel.
n_components(p::Panel) = size(p.data, 2)

# The style to apply to component `i`: its own if a per-component vector is set,
# otherwise the shared style.
component_style(p::Panel, i::Integer) = isempty(p.styles) ? p.style : p.styles[i]

# =============================================================================
# Replaceable defaults (double-underscore = semantic default a caller may override)
# =============================================================================

# Default overall layout: :split (one subplot per component). Alt: :group.
__layout() = :split

# Default time-axis handling: :default (real time). Alt: :normalize / :normalise.
__time() = :default

# Default series style: no override.
__style() = NamedTuple()

# Semantic font sizes (points). Kept backend-free here; the Plots renderer turns
# them into `Plots.font`. Consistent across the engine.
const _TITLE_FONT_SIZE = 10
const _LABEL_FONT_SIZE = 10
