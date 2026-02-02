# Configuration for exception display behavior

"""
    SHOW_FULL_STACKTRACE

Module-level configuration to control stacktrace display.
Set to `true` to show full Julia stacktraces, `false` for user-friendly display only.

Default: `false` (user-friendly display)

# Example
```julia
CTBase.set_show_full_stacktrace!(true)  # Show full stacktraces
CTBase.set_show_full_stacktrace!(false) # User-friendly display only
```
"""
const SHOW_FULL_STACKTRACE = Ref{Bool}(true)

"""
    set_show_full_stacktrace!(value::Bool)

Configure whether to display full Julia stacktraces in error messages.

# Arguments
- `value::Bool`: `true` to show full stacktraces, `false` for user-friendly display

# Example
```julia
# Enable full stacktraces for debugging
CTBase.set_show_full_stacktrace!(true)

# Disable for cleaner user experience (default)
CTBase.set_show_full_stacktrace!(false)
```
"""
function set_show_full_stacktrace!(value::Bool)
    SHOW_FULL_STACKTRACE[] = value
    return nothing
end

"""
    get_show_full_stacktrace()

Get current stacktrace display configuration.

# Returns
- `Bool`: Current setting for full stacktrace display
"""
function get_show_full_stacktrace()
    return SHOW_FULL_STACKTRACE[]
end
