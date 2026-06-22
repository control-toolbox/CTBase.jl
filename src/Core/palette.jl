"""
$(TYPEDEF)

An ANSI display style described by a numeric escape code.

The `code` field holds the numeric part of the escape sequence (e.g. `"32"` for
green, `"1;34"` for bold blue). An empty string means *no styling* — used by
monochrome palettes and when colour is disabled.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.Core.Style("32")   # green
Style("32")

julia> CTBase.Core.Style("")     # no styling
Style("")
```

See also: [`CTBase.Core.Palette`](@ref), [`CTBase.Core.set_color!`](@ref)
"""
struct Style
    code::String
end

"""
$(TYPEDEF)

A complete set of display styles, one per semantic role.

Each field is a [`CTBase.Core.Style`](@ref) that governs how a particular category of
information is rendered. The active palette is read at every call to
[`CTBase.Core.get_format_codes`](@ref), so swapping it with
[`CTBase.Core.set_palette!`](@ref) takes effect immediately for subsequent `show` calls.

# Fields

- `name`: identifiers, type names, option keys (default: bold blue)
- `type`: type annotations, hierarchy entries (default: cyan)
- `value`: data values, option values (default: green)
- `keyword`: Julia symbols (`:euler`), aliases, IDs (default: yellow)
- `count`: numeric counts (default: magenta)
- `label`: secondary labels, metadata tags (default: gray)
- `emphasis`: message text, function names (default: bold)
- `muted`: structural chars (`│`, `└─`, `→`), time suffix (default: dim)
- `error`: failures, missing extensions (default: red)
- `warning`: notable values (`Got`, `Retcode`, skipped test) (default: yellow)
- `success`: positive hints, `Expected`, passing test (default: green)

See also: [`CTBase.Core.DEFAULT_PALETTE`](@ref), [`CTBase.Core.MONOCHROME_PALETTE`](@ref), [`CTBase.Core.HIGH_CONTRAST_PALETTE`](@ref), [`CTBase.Core.set_palette!`](@ref)
"""
struct Palette
    name::Style
    type::Style
    value::Style
    keyword::Style
    count::Style
    label::Style
    emphasis::Style
    muted::Style
    error::Style
    warning::Style
    success::Style
end

"""
The standard colour palette used out of the box.

Maps each semantic role to a colour that mirrors Julia's REPL conventions
(green for values, cyan for types, etc.).

See also: [`CTBase.Core.Palette`](@ref), [`CTBase.Core.MONOCHROME_PALETTE`](@ref), [`CTBase.Core.HIGH_CONTRAST_PALETTE`](@ref), [`CTBase.Core.set_palette!`](@ref)
"""
const DEFAULT_PALETTE = Palette(
    Style("1;34"),   # name     — bold blue
    Style("36"),     # type     — cyan
    Style("32"),     # value    — green
    Style("33"),     # keyword  — yellow
    Style("35"),     # count    — magenta
    Style("90"),     # label    — bright black / gray
    Style("1"),      # emphasis — bold
    Style("2"),      # muted    — dim
    Style("31"),     # error    — red
    Style("33"),     # warning  — yellow
    Style("32"),     # success  — green
)

"""
A palette with every style set to the empty code.

No colour or formatting is ever emitted, regardless of terminal capability.
Useful for CI logs, plain-text output, or accessibility contexts where styled
text is unwanted.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.Core.set_palette!(CTBase.Core.MONOCHROME_PALETTE)
```

See also: [`CTBase.Core.DEFAULT_PALETTE`](@ref), [`CTBase.Core.HIGH_CONTRAST_PALETTE`](@ref), [`CTBase.Core.reset_palette!`](@ref)
"""
const MONOCHROME_PALETTE = Palette(
    Style(""), Style(""), Style(""), Style(""), Style(""), Style(""),
    Style(""), Style(""), Style(""), Style(""), Style(""),
)

"""
A palette using bright, bold variants for improved readability.

Useful on terminals with poor contrast or for users who prefer stronger colour
cues.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.Core.set_palette!(CTBase.Core.HIGH_CONTRAST_PALETTE)
```

See also: [`CTBase.Core.DEFAULT_PALETTE`](@ref), [`CTBase.Core.MONOCHROME_PALETTE`](@ref), [`CTBase.Core.reset_palette!`](@ref)
"""
const HIGH_CONTRAST_PALETTE = Palette(
    Style("1;94"),   # name     — bright bold blue
    Style("1;96"),   # type     — bright bold cyan
    Style("1;92"),   # value    — bright bold green
    Style("1;93"),   # keyword  — bright bold yellow
    Style("1;95"),   # count    — bright bold magenta
    Style("37"),     # label    — white
    Style("1"),      # emphasis — bold
    Style("2"),      # muted    — dim
    Style("1;91"),   # error    — bright bold red
    Style("1;93"),   # warning  — bright bold yellow
    Style("1;92"),   # success  — bright bold green
)

# ---------------------------------------------------------------------------
# Runtime global
# ---------------------------------------------------------------------------

"""
Runtime reference to the currently active palette.

Initialised to [`CTBase.Core.DEFAULT_PALETTE`](@ref). All display paths read
from this reference; mutate it via [`CTBase.Core.set_palette!`](@ref) and
[`CTBase.Core.reset_palette!`](@ref).
"""
const _ACTIVE_PALETTE = Ref{Palette}(DEFAULT_PALETTE)

"""
$(TYPEDSIGNATURES)

Return the currently active [`CTBase.Core.Palette`](@ref).

The active palette is used by every `show` and `describe` call in CTBase to
derive ANSI codes. Change it with [`CTBase.Core.set_palette!`](@ref).

# Example

```julia-repl
julia> using CTBase

julia> CTBase.Core.current_palette() === CTBase.Core.DEFAULT_PALETTE
true
```

See also: [`CTBase.Core.set_palette!`](@ref), [`CTBase.Core.reset_palette!`](@ref)
"""
current_palette() = _ACTIVE_PALETTE[]

"""
$(TYPEDSIGNATURES)

Replace the active [`CTBase.Core.Palette`](@ref) with `p` and return `p`.

The change is global and immediate: the next `show` or `describe` call uses
the new palette. Use [`CTBase.Core.reset_palette!`](@ref) to restore the default.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.Core.set_palette!(CTBase.Core.HIGH_CONTRAST_PALETTE)

julia> CTBase.Core.current_palette() === CTBase.Core.HIGH_CONTRAST_PALETTE
true

julia> CTBase.Core.reset_palette!()
```

See also: [`CTBase.Core.current_palette`](@ref), [`CTBase.Core.reset_palette!`](@ref)
"""
function set_palette!(p::Palette)
    _ACTIVE_PALETTE[] = p
    return p
end

"""
$(TYPEDSIGNATURES)

Override a single semantic role in the active palette and return the updated
[`CTBase.Core.Palette`](@ref).

`role` must be one of `:name`, `:type`, `:value`, `:keyword`, `:count`,
`:label`, `:emphasis`, `:muted`, `:error`, `:warning`, `:success`.
`code` is the ANSI numeric code string (e.g. `"32"` for green, `"1;34"` for
bold blue, `""` to suppress styling for that role).

# Example

```julia-repl
julia> using CTBase

julia> CTBase.Core.set_color!(:error, "35")   # make errors magenta

julia> CTBase.Core.reset_palette!()
```

See also: [`CTBase.Core.set_palette!`](@ref), [`CTBase.Core.reset_palette!`](@ref)
"""
function set_color!(role::Symbol, code::AbstractString)
    p = _ACTIVE_PALETTE[]
    new_style = Style(code)
    new_palette = Palette(
        role == :name      ? new_style : p.name,
        role == :type      ? new_style : p.type,
        role == :value     ? new_style : p.value,
        role == :keyword   ? new_style : p.keyword,
        role == :count     ? new_style : p.count,
        role == :label     ? new_style : p.label,
        role == :emphasis  ? new_style : p.emphasis,
        role == :muted     ? new_style : p.muted,
        role == :error     ? new_style : p.error,
        role == :warning   ? new_style : p.warning,
        role == :success   ? new_style : p.success,
    )
    _ACTIVE_PALETTE[] = new_palette
    return new_palette
end

"""
$(TYPEDSIGNATURES)

Restore the active palette to [`CTBase.Core.DEFAULT_PALETTE`](@ref) and return it.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.Core.set_palette!(CTBase.Core.MONOCHROME_PALETTE)

julia> CTBase.Core.reset_palette!()

julia> CTBase.Core.current_palette() === CTBase.Core.DEFAULT_PALETTE
true
```

See also: [`CTBase.Core.set_palette!`](@ref), [`CTBase.Core.current_palette`](@ref)
"""
reset_palette!() = set_palette!(DEFAULT_PALETTE)

# ---------------------------------------------------------------------------
# Palette preview
# ---------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Print a visual preview of the active [`CTBase.Core.Palette`](@ref) to `io`.

The preview has three sections:
- **Role swatches**: every semantic role with a colored swatch block (`████`), a
  representative sample string, and a description of when the role is used.
- **Mock describe**: a simulated `describe`/`show` block exercising `name`, `type`,
  `value`, `keyword`, `count`, `label`, and `muted`.
- **Mock error**: a simulated exception block exercising `error`, `emphasis`,
  `muted`, `warning`, and `success`.

By default `io` wraps `stdout` with `:color => true` so the preview is always
colored in an interactive session. Pass a custom `IOContext` to override.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.Core.show_palette()

julia> CTBase.Core.set_palette!(CTBase.Core.HIGH_CONTRAST_PALETTE)
julia> CTBase.Core.show_palette()
julia> CTBase.Core.reset_palette!()
```

See also: [`CTBase.Core.set_palette!`](@ref), [`CTBase.Core.current_palette`](@ref), [`CTBase.Core.DEFAULT_PALETTE`](@ref)
"""
function show_palette(io::IO=IOContext(stdout, :color => true))
    p  = current_palette()
    fmt = (
        bold=get(io, :color, false) ? "\033[1m" : "",
        reset=get(io, :color, false) ? "\033[0m" : "",
    )
    open(st) = get(io, :color, false) && !isempty(st.code) ? "\033[$(st.code)m" : ""
    swatch(st) = isempty(open(st)) ? "    " : "$(open(st))████$(fmt.reset)"
    rst = fmt.reset

    # Palette name
    palette_name = if p === DEFAULT_PALETTE
        "DEFAULT_PALETTE"
    elseif p === MONOCHROME_PALETTE
        "MONOCHROME_PALETTE"
    elseif p === HIGH_CONTRAST_PALETTE
        "HIGH_CONTRAST_PALETTE"
    else
        "custom"
    end
    println(io, fmt.bold, "Active palette: ", palette_name, rst)
    println(io)

    # ── Role swatches ──────────────────────────────────────────────────────
    println(io, fmt.bold, "Semantic roles", rst)
    println(io)
    role_rows = [
        (:name,     "MyStrategy",          "identifiers, type names, option keys"),
        (:type,     "AbstractStrategy",    "type annotations, hierarchy entries"),
        (:value,    "0.01",                "data / option values"),
        (:keyword,  ":gradient",           "Julia symbols, aliases, IDs"),
        (:count,    "3",                   "numeric counts, lengths"),
        (:label,    "[default]",           "secondary labels, metadata tags"),
        (:emphasis, "important text",      "message text, function names"),
        (:muted,    "│ └─ → (0.5s)",       "structural chars, time suffix"),
        (:error,    "IncorrectArgument",   "failures, missing extensions"),
        (:warning,  "got: -0.5",           "notable values, skipped tests"),
        (:success,  "hint: use set_color!", "positive info, passing tests"),
    ]
    for (role, sample, desc) in role_rows
        st   = getfield(p, role)
        name = rpad(string(role), 10)
        print(io, "  $(open(p.muted))$(name)$(rst)  $(swatch(st))  ")
        println(io, "$(open(st))$(sample)$(rst)  $(open(p.muted))$(desc)$(rst)")
    end

    # ── Mock describe ──────────────────────────────────────────────────────
    println(io)
    println(io, fmt.bold, "Mock describe / show", rst)
    println(io)
    n  = open(p.name);    t  = open(p.type)
    v  = open(p.value);   kw = open(p.keyword)
    c  = open(p.count);   lb = open(p.label)
    mu = open(p.muted)
    println(io, "  $(n)MyStrategy$(rst) (instance, id=$(kw):gradient$(rst))")
    println(io, "  $(mu)│$(rst)")
    println(io, "  $(mu)│$(rst)  $(lb)hierarchy: $(rst)$(t)MyStrategy$(rst) $(mu)→$(rst) $(t)AbstractStrategy$(rst)")
    println(io, "  $(mu)│$(rst)  $(lb)options ($(rst)$(c)3$(rst)$(lb)):$(rst)")
    println(io, "  $(mu)│$(rst)")
    println(io, "  $(mu)│  ├─$(rst)  $(n)step$(rst)::$(t)Float64$(rst)  = $(v)0.01$(rst)  $(lb)[default]$(rst)")
    println(io, "  $(mu)│  ├─$(rst)  $(n)tol$(rst) ::$(t)Float64$(rst)  = $(v)1e-6$(rst)  $(lb)[user]$(rst)")
    println(io, "  $(mu)│  └─$(rst)  $(n)verbose$(rst)::$(t)Bool$(rst)    = $(v)false$(rst) $(lb)[computed]$(rst)")

    # ── Mock error ─────────────────────────────────────────────────────────
    println(io)
    println(io, fmt.bold, "Mock exception", rst)
    println(io)
    er = open(p.error);   em = open(p.emphasis)
    wa = open(p.warning); su = open(p.success)
    println(io, "  $(er)IncorrectArgument$(rst) $(mu)→$(rst) $(em)my_solver$(rst), $(kw)script.jl:42$(rst)")
    println(io, "  $(mu)│$(rst)")
    println(io, "  $(mu)│$(rst)  $(em)Invalid value for option :step$(rst)")
    println(io, "  $(mu)│$(rst)")
    println(io, "  $(mu)│$(rst)  $(em)Got     $(rst)  $(wa)-0.5$(rst)")
    println(io, "  $(mu)│$(rst)  $(em)Expected$(rst)  $(su)> 0.0$(rst)")
    println(io, "  $(mu)│$(rst)")
    println(io, "  $(mu)│$(rst)  $(em)Hint    $(rst)  $(su)Use a positive step size for :step$(rst)")
    println(io, "  $(mu)└─$(rst)")
    return nothing
end
