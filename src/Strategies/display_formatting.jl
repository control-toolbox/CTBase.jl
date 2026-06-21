# Display formatting utilities
#
# Unified color and formatting constants for consistent display across all show() methods
"""
$(TYPEDSIGNATURES)

Print a labeled field with multi-line text support, aligning continuation lines under the text.

The first line is printed as `prefix + colored_label + text_line_1`. Each subsequent
line (split on `'\\n'`) is indented to align with the start of the text, using
`cont` followed by spaces equal to the visible length of `label`.

# Arguments
- `io::IO`: Output stream
- `prefix::String`: Prefix for the first line (e.g., `"├─ "` or `"   │  "`)
- `cont::String`: Continuation prefix for subsequent lines (e.g., `"│  "` or `"      "`)
- `fmt`: Format codes from `Core.get_format_codes`
- `label::String`: The field label text (e.g., `"description: "`)
- `text::String`: The field value, may contain `'\\n'` for multi-line content

# Example
```julia
fmt = Core.get_format_codes(stdout)
_print_labeled_multiline(stdout, "├─ ", "│  ", fmt, "description: ", "Line one.\\nLine two.")
# Output:
# ├─ description: Line one.
# │               Line two.
```
"""
function _print_labeled_multiline(
    io::IO, prefix::String, cont::String, fmt, label::String, text::String
)
    lines = split(text, '\n')
    println(io, prefix, fmt.label, label, fmt.reset, lines[1])
    if length(lines) > 1
        padding = cont * " " ^ length(label)
        for line in lines[2:end]
            println(io, padding, line)
        end
    end
end
