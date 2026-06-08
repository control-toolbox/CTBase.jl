"""
    _PROGRESS_BAR_THRESHOLD

Internal constant defining the maximum number of tests for full-resolution progress bars.

When the total number of tests is ≤ `_PROGRESS_BAR_THRESHOLD` (100), the progress bar displays
one character per test with cumulative coloring (each test gets its own colored block).
Beyond this threshold, the bar switches to compressed mode with uniform coloring.

This threshold balances visual clarity with terminal width constraints.
"""
const _PROGRESS_BAR_THRESHOLD = 100

"""
$(TYPEDSIGNATURES)

Compute the progress bar character width based on the number of tests.

- `total ≤ progress_bar_threshold`: width equals `total` (one block per test).
- `total > progress_bar_threshold`: fixed width of `progress_bar_threshold` (some tests skip a block advance).

# Arguments
- `total::Int`: Total number of tests
- `progress_bar_threshold::Int`: Maximum tests for full-resolution progress bar (default: `100`)

# Returns
- `Int`: Character width for the progress bar (0 if `total ≤ 0`)

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> TestRunner._bar_width(10)
10

julia> TestRunner._bar_width(25)
25

julia> TestRunner._bar_width(0)
0

julia> TestRunner._bar_width(100, progress_bar_threshold=30)
30
```
"""
function _bar_width(total::Int, progress_bar_threshold::Int=_PROGRESS_BAR_THRESHOLD)
    total <= 0 && return 0
    return min(total, progress_bar_threshold)
end

"""
$(TYPEDSIGNATURES)

Render a progress bar string like `[████████░░░░░░░░░░░░]`.

When `width` is `nothing` (default), the width is computed automatically
via `_bar_width(total)`. Returns an empty string when the bar is hidden.

# Arguments
- `index::Int`: current progress (1-based)
- `total::Int`: total number of items
- `width::Union{Int,Nothing}`: character width of the bar (default: auto)

# Returns
- `String`: Progress bar string, or empty string if hidden

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> TestRunner._progress_bar(5, 10)
"[█████░░░░░]"

julia> TestRunner._progress_bar(5, 10; width=20)
"[██████████░░░░░░░░░░]"

julia> TestRunner._progress_bar(0, 10; width=5)
"[░░░░░]"
```
"""
function _progress_bar(index::Int, total::Int; width::Union{Int,Nothing}=nothing)
    w = width === nothing ? _bar_width(total) : width
    w <= 0 && return ""
    total <= 0 && return "[" * repeat("░", w) * "]"
    filled = round(Int, index / total * w)
    filled = clamp(filled, 0, w)
    return "[" * repeat("█", filled) * repeat("░", w - filled) * "]"
end

"""
    _severity(status::Symbol) -> Int

Internal helper to map test status to severity level for display formatting.

# Arguments
- `status::Symbol`: Test status (`:error`, `:test_failed`, `:skipped`, or success)

# Returns
- `Int`: Severity level (3=failure, 2=skipped, 1=success)
"""
@inline _severity(status::Symbol) =
    (status == :error || status == :test_failed) ? 3 : (status == :skipped ? 2 : 1)

"""
    _color_for_severity(sev::Int) -> String

Internal helper to map severity level to ANSI color code.

# Arguments
- `sev::Int`: Severity level (3=failure, 2=skipped, 1=success)

# Returns
- `String`: ANSI color escape code (red for failure, yellow for skipped, green for success)
"""
@inline function _color_for_severity(sev::Int)
    sev >= 3 && return "\e[31m" # red
    sev == 2 && return "\e[33m" # yellow
    return "\e[32m"             # green
end

"""
    _block_char_for_severity(sev::Int) -> String

Internal helper to map severity level to block character for colorblind-friendly display.

Uses distinct glyphs to ensure progress bars are readable without color:
- Success: █ (solid block)
- Skipped: ┆ (thin vertical line)
- Failure: ▚ (diagonal pattern)

# Arguments
- `sev::Int`: Severity level (3=failure, 2=skipped, 1=success)

# Returns
- `String`: Unicode block character representing the severity
"""
@inline function _block_char_for_severity(sev::Int)
    sev >= 3 && return "▚"  # failure (diagonal)
    sev == 2 && return "┆"   # skipped (thin vertical)
    return "█"               # success
end

"""
$(TYPEDSIGNATURES)

Write a styled progress line for a completed test to `io`.

Uses ANSI colors: green for success, red for errors, yellow for skipped.

# Arguments
- `io::IO`: Output stream to write to
- `info::TestRunInfo`: Test execution information
- `history::Union{Vector{Int},Nothing}`: Optional history array for per-test coloring (default: `nothing`)
- `cumulative_severity::Union{Int,Nothing}`: Optional cumulative severity for coloring (default: `nothing`)
- `progress_bar_threshold::Int`: Maximum tests for full-resolution progress bar (default: `100`)
- `show_progress_bar::Bool`: Show graphical progress bar `[█░░░...]` (default: `true`)

# Notes
- Format: `[progress_bar] symbol [index/total] spec (time) status`
- Colors: green for success, red for errors, yellow for skipped
- Time is displayed with one decimal place when available
- **Cursor-style display**: In full-resolution mode (total ≤ threshold), only the current test position is filled for successes, while failures and skips persist at their positions. This creates a lighter, cursor-like visual where past successes are ephemeral.

# Example
```julia-repl
julia> using CTBase.TestRunner, IOBuffer

julia> info = TestRunner.TestRunInfo(
           :test_example, 
           "/path/to/test.jl", 
           :test_example, 
           5, 10, 
           :post_eval, 
           nothing, 
           1.23
       );

julia> buf = IOBuffer();
julia> TestRunner._format_progress_line(buf, info);
julia> String(take!(buf))
"[█████░░░░░░░░░░░] ✓ [05/10] test_example (1.2s)"
```
"""
function _format_progress_line(
    io::IO,
    info::TestRunInfo;
    history::Union{Vector{Int},Nothing}=nothing,
    cumulative_severity::Union{Int,Nothing}=nothing,
    progress_bar_threshold::Int=_PROGRESS_BAR_THRESHOLD,
    show_progress_bar::Bool=true,
)
    # ANSI codes
    reset = "\e[0m"
    bold = "\e[1m"
    dim = "\e[2m"
    green = "\e[32m"
    red = "\e[31m"
    yellow = "\e[33m"
    cyan = "\e[36m"

    bar_width = _bar_width(info.total, progress_bar_threshold)
    bar = _progress_bar(info.index, info.total; width=bar_width)

    severity = _severity(info.status)
    if severity == 3
        color = red
        symbol = "✗"
    elseif severity == 2
        color = yellow
        symbol = "○"
    else
        color = green
        symbol = "✓"
    end

    w = ndigits(info.total)
    idx_str = "[$(lpad(info.index, w, '0'))/$(info.total)]"
    time_str = if info.elapsed !== nothing
        " $(dim)($(round(info.elapsed; digits=1))s)$(reset)"
    else
        ""
    end
    status_str = if (info.status == :error || info.status == :test_failed)
        " $(bold)$(red)FAILED$(reset)$(dim),"
    else
        ""
    end

    function bracket_color_from(sev::Union{Int,Nothing})
        sev === nothing && return green
        sev <= 1 && return green
        sev == 2 && return yellow
        return red
    end

    has_history =
        history !== nothing && length(history) == info.total && bar_width == info.total
    if show_progress_bar && has_history
        # Build colored bar per block using history; brackets colored by max severity seen
        max_sev = maximum(history)
        bracket_color = bracket_color_from(max_sev)
        blocks = String[]
        for i in 1:info.total
            sev = history[i]
            if sev <= 0
                push!(blocks, "$(dim)░$(reset)")
            elseif sev >= 2
                # Failures and skips persist at their positions
                glyph = _block_char_for_severity(sev)
                push!(blocks, "$( _color_for_severity(sev) )$(glyph)$(reset)")
            elseif i == info.index
                # Current test (success) is shown
                glyph = _block_char_for_severity(sev)
                push!(blocks, "$( _color_for_severity(sev) )$(glyph)$(reset)")
            else
                # Past successes are cleared (ephemeral cursor style)
                push!(blocks, "$(dim)░$(reset)")
            end
        end
        # Reapply bracket_color for closing bracket so block-local resets do not strip it
        bar = "$(bracket_color)[" * join(blocks) * "$(bracket_color)]$(reset)"
        print(io, "$(bar) ")
    elseif show_progress_bar && !isempty(bar)
        bracket_sev = cumulative_severity === nothing ? severity : cumulative_severity
        bracket_color = bracket_color_from(bracket_sev)
        # Use single cursor style instead of repeating filled blocks
        filled_char = _block_char_for_severity(severity)
        w = bar_width
        cursor_pos = clamp(round(Int, info.index / info.total * w), 1, w)
        # Build bar with ░ everywhere except at cursor position
        inner_chars = fill("░", w)
        inner_chars[cursor_pos] = filled_char
        inner = join(inner_chars)
        print(
            io,
            "$(bracket_color)[$(reset)$(color)$(inner)$(reset)$(bracket_color)]$(reset) ",
        )
    end
    print(io, "$(bold)$(color)$(symbol)$(reset) ")
    print(io, "$(cyan)$(idx_str)$(reset) ")
    print(io, "$(bold)$(info.spec)$(reset)")
    println(io, "$(status_str)$(time_str)")
    return nothing
end

"""
$(TYPEDSIGNATURES)

Create a stateful progress callback for `on_test_done`. Prints to `io`.

# Arguments
- `io::IO`: Output stream for progress display
- `total::Int`: Total number of tests
- `progress_bar_threshold::Int`: Maximum tests for full-resolution progress bar (default: `100`)
- `show_progress_bar::Bool`: Show graphical progress bar `[█░░░...]` (default: `true`)

# Returns
- `Function`: Callback function that accepts `TestRunInfo` and updates progress display

# Notes
- This is the default callback used when `show_progress_line=true` and no custom `on_test_done` is provided
- The returned callback maintains state (history, max_severity) across invocations
- Outputs a formatted progress line to `io` with colors and timing information
- When `show_progress_bar=false`, displays minimal output without the graphical bar

# Example
```julia-repl
julia> using CTBase.TestRunner

julia> cb = TestRunner._make_default_on_test_done(stdout, 10)

julia> info = TestRunner.TestRunInfo(
           :test_example, 
           "/path/to/test.jl", 
           :test_example, 
           5, 10, 
           :post_eval, 
           nothing, 
           1.23
       );

julia> cb(info)
[█████░░░░░░░░░░░] ✓ [05/10] test_example (1.2s)
```
"""
function _make_default_on_test_done(
    io::IO,
    total::Int,
    progress_bar_threshold::Int=_PROGRESS_BAR_THRESHOLD,
    show_progress_bar::Bool=true,
)
    history = total <= progress_bar_threshold ? fill(0, total) : Int[]
    max_severity = Ref{Int}(0)

    function update(info::TestRunInfo)
        sev = _severity(info.status)
        max_severity[] = max(max_severity[], sev)
        if !isempty(history) && info.index <= length(history)
            history[info.index] = sev
        end
        _format_progress_line(
            io,
            info;
            history=(!isempty(history) ? history : nothing),
            cumulative_severity=max_severity[],
            progress_bar_threshold=progress_bar_threshold,
            show_progress_bar=show_progress_bar,
        )
        return nothing
    end

    return update
end

"""
    _default_on_test_done(info::TestRunInfo)

Backward compatibility shim for the default test completion callback.

Creates a fresh stateful callback via `_make_default_on_test_done` and invokes it
with the given `info`. This function exists for compatibility with existing code/tests that
expect a stateless callback signature.

For new code, prefer using `_make_default_on_test_done` directly to create a
persistent callback that maintains test history across multiple invocations.

# Arguments
- `info::TestRunInfo`: Test execution information

See also: `_make_default_on_test_done`
"""
function _default_on_test_done(info::TestRunInfo)
    cb = _make_default_on_test_done(stdout, info.total)
    return cb(info)
end
