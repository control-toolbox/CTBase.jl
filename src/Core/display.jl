"""
$(TYPEDSIGNATURES)

Apply a [`CTBase.Core.Style`](@ref) to string `s`, respecting the IO colour capability.

Returns `s` wrapped in ANSI escape codes when `get(io, :color, false)` is `true`
and `st.code` is non-empty; returns the plain string otherwise.

See also: [`CTBase.Core._apply_ansi`](@ref), [`CTBase.Core.get_format_codes`](@ref)
"""
function _style(st::Style, s, io::IO)
    get(io, :color, false) && !isempty(st.code) || return string(s)
    return "\033[$(st.code)m$(s)\033[0m"
end

"""
$(TYPEDSIGNATURES)

Apply a raw ANSI numeric code string to `s`, respecting the IO colour capability.

Prefer [`CTBase.Core._style`](@ref) with a [`CTBase.Core.Style`](@ref) from the
active palette over calling this function directly.
"""
_apply_ansi(s, code, io::IO) = get(io, :color, false) ? "\033[$(code)m$(s)\033[0m" : string(s)

# ---------------------------------------------------------------------------
# Named helpers — backed by the active palette roles
# ---------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Apply the `muted` role style from the active palette.

See also: [`CTBase.Core.current_palette`](@ref), [`CTBase.Core._style`](@ref)
"""
_dim(s, io::IO) = _style(current_palette().muted, s, io)

"""
$(TYPEDSIGNATURES)

Apply the `emphasis` role style from the active palette.

See also: [`CTBase.Core.current_palette`](@ref), [`CTBase.Core._style`](@ref)
"""
_bold(s, io::IO) = _style(current_palette().emphasis, s, io)

"""
$(TYPEDSIGNATURES)

Apply the `error` role style from the active palette (defaults to red).

See also: [`CTBase.Core.current_palette`](@ref), [`CTBase.Core._style`](@ref)
"""
_red(s, io::IO) = _style(current_palette().error, s, io)

"""
$(TYPEDSIGNATURES)

Apply the `warning` role style from the active palette (defaults to yellow).

See also: [`CTBase.Core.current_palette`](@ref), [`CTBase.Core._style`](@ref)
"""
_yellow(s, io::IO) = _style(current_palette().warning, s, io)

"""
$(TYPEDSIGNATURES)

Apply the `success` role style from the active palette (defaults to green).

See also: [`CTBase.Core.current_palette`](@ref), [`CTBase.Core._style`](@ref)
"""
_green(s, io::IO) = _style(current_palette().success, s, io)

# ---------------------------------------------------------------------------
# Structured format codes NamedTuple
# ---------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return ANSI opening codes for every semantic role in the active
[`CTBase.Core.Palette`](@ref), respecting the colour capability of `io`.

Each field is an *opening* escape sequence; callers must close styling with
the `reset` field. Returns empty strings for all codes when `get(io, :color,
false)` is `false`, or when the active palette has an empty code for that role
(e.g. [`CTBase.Core.MONOCHROME_PALETTE`](@ref)).

# Returns

A `NamedTuple` with the following fields:

| Field | Default colour | Semantic role |
| --- | --- | --- |
| `name` | bold blue | identifiers, type names, option keys |
| `type` | cyan | type annotations, hierarchy entries |
| `value` | green | data values |
| `keyword` | yellow | Julia symbols, aliases |
| `count` | magenta | numeric counts |
| `label` | gray | secondary labels, metadata tags |
| `emphasis` / `bold` | bold | message text, function names |
| `muted` / `dim` | dim | structural chars, time suffix |
| `error` | red | failures, missing extensions |
| `warning` | yellow | notable attention values |
| `success` | green | positive hints, expected values |
| `reset` | — | resets all styling |

`bold` and `dim` are legacy aliases for `emphasis` and `muted`; prefer the
semantic names in new code.

# Example

```julia-repl
julia> using CTBase

julia> io = IOContext(stdout, :color => true);

julia> fmt = CTBase.Core.get_format_codes(io);

julia> print(io, fmt.name, "option_name", fmt.reset, "::", fmt.type, "Int", fmt.reset)
option_name::Int
```

See also: [`CTBase.Core.set_palette!`](@ref), [`CTBase.Core.Palette`](@ref)
"""
function get_format_codes(io::IO)
    p = current_palette()
    open(st) = get(io, :color, false) && !isempty(st.code) ? "\033[$(st.code)m" : ""
    rst = get(io, :color, false) ? "\033[0m" : ""
    return (
        # Semantic roles
        name     = open(p.name),
        type     = open(p.type),
        value    = open(p.value),
        keyword  = open(p.keyword),
        count    = open(p.count),
        label    = open(p.label),
        emphasis = open(p.emphasis),
        muted    = open(p.muted),
        error    = open(p.error),
        warning  = open(p.warning),
        success  = open(p.success),
        reset    = rst,
        # Legacy aliases
        bold     = open(p.emphasis),
        dim      = open(p.muted),
    )
end
