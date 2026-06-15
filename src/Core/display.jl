"""
    _apply_ansi(s, code, io::IO)

Apply ANSI escape codes to a string if color is enabled in the IO context.

# Arguments
- `s::AbstractString`: The string to style.
- `code::String`: The ANSI code (e.g., `"2"` for dim, `"1"` for bold, `"1;31"` for red).
- `io::IO`: Output stream to check for color support.

# Returns
- `String`: The string wrapped in ANSI escape codes if `get(io, :color, false)` is true,
  otherwise the plain string.
"""
_apply_ansi(s, code, io::IO) = get(io, :color, false) ? "\033[$(code)m$(s)\033[0m" : s

"""
$(TYPEDSIGNATURES)

Apply dimmed (faint) ANSI styling to a string.

# Arguments
- `s::AbstractString`: The string to style.
- `io::IO`: Output stream to check for color support.

# Returns
- `String`: The string wrapped in dim ANSI escape codes if color is enabled.
"""
_dim(s, io::IO) = _apply_ansi(s, "2", io)

"""
$(TYPEDSIGNATURES)

Apply bold ANSI styling to a string.

# Arguments
- `s::AbstractString`: The string to style.
- `io::IO`: Output stream to check for color support.

# Returns
- `String`: The string wrapped in bold ANSI escape codes if color is enabled.
"""
_bold(s, io::IO) = _apply_ansi(s, "1", io)

"""
$(TYPEDSIGNATURES)

Apply red ANSI styling to a string.

# Arguments
- `s::AbstractString`: The string to style.
- `io::IO`: Output stream to check for color support.

# Returns
- `String`: The string wrapped in red ANSI escape codes if color is enabled.
"""
_red(s, io::IO) = _apply_ansi(s, "1;31", io)

"""
$(TYPEDSIGNATURES)

Apply yellow ANSI styling to a string.

# Arguments
- `s::AbstractString`: The string to style.
- `io::IO`: Output stream to check for color support.

# Returns
- `String`: The string wrapped in yellow ANSI escape codes if color is enabled.
"""
_yellow(s, io::IO) = _apply_ansi(s, "33", io)

"""
$(TYPEDSIGNATURES)

Apply green ANSI styling to a string.

# Arguments
- `s::AbstractString`: The string to style.
- `io::IO`: Output stream to check for color support.

# Returns
- `String`: The string wrapped in green ANSI escape codes if color is enabled.
"""
_green(s, io::IO) = _apply_ansi(s, "32", io)

"""
    get_format_codes(io::IO) -> NamedTuple

Get ANSI formatting codes based on terminal color support.

Returns a NamedTuple with formatting codes for consistent display across all show() methods.

# Fields
- `bold`: Bold text
- `reset`: Reset all formatting
- `name`: Bold blue for names (options, types, etc.)
- `type`: Cyan for types
- `value`: Green for values
- `keyword`: Yellow for keywords/aliases
- `count`: Magenta for counts
- `label`: Gray for labels/descriptions

# Example
```julia
fmt = get_format_codes(io)
print(io, fmt.name, "option_name", fmt.reset, "::", fmt.type, "Int", fmt.reset)
```

# Notes
- Automatically detects color support via `get(io, :color, false)`
- Returns empty strings for all codes if colors are not supported
- Ensures consistent color scheme across the entire package
"""
function get_format_codes(io::IO)
    supports_color = get(io, :color, false)

    return (
        # Text formatting
        bold=supports_color ? "\033[1m" : "",
        reset=supports_color ? "\033[0m" : "",

        # Colors for different semantic elements
        name=supports_color ? "\033[1m\033[34m" : "",      # Bold blue for names
        type=supports_color ? "\033[36m" : "",             # Cyan for types
        value=supports_color ? "\033[32m" : "",            # Green for values
        keyword=supports_color ? "\033[33m" : "",          # Yellow for keywords/aliases
        count=supports_color ? "\033[35m" : "",            # Magenta for counts
        label=supports_color ? "\033[90m" : "",            # Gray for labels
    )
end
