"""
    extract_user_frames(st::Vector)

Extract stacktrace frames that are relevant to user code.
Filters out Julia stdlib.

# Arguments
- `st::Vector`: Stacktrace from `stacktrace(catch_backtrace())`

# Returns
- `Vector`: Filtered stacktrace frames
"""
function _extract_user_frames(st::Vector)
    user_frames = filter(st) do frame
        file_str = string(frame.file)
        # Keep frames that are NOT from Julia stdlib or exception display internals
        return !contains(file_str, ".julia/") &&
               !contains(file_str, "juliaup/") &&
               !contains(file_str, "/macros.jl") &&
               !contains(file_str, "/exception") &&
               !contains(file_str, "display.jl") &&
               !contains(file_str, "Base.jl") &&
               !contains(file_str, "boot.jl")
    end
    return user_frames
end

"""
$(TYPEDSIGNATURES)

Format a diagnostic tag for `AmbiguousDescription` display, expanding shorthand tags into human-readable messages.

# Arguments
- `diagnostic::String`: The diagnostic tag (e.g., "empty catalog", "unknown symbols", "no complete match").

# Returns
- `String`: The expanded human-readable message.

# Notes
- Unknown tags are returned unchanged.
"""
function _format_diagnostic(diagnostic::String)
    if diagnostic == "empty catalog"
        return "Empty catalog — no descriptions available"
    elseif diagnostic == "unknown symbols"
        return "Unknown symbols — none of the requested symbols appear in any available description"
    elseif diagnostic == "no complete match"
        return "No complete match — no description contains all symbols"
    else
        return diagnostic
    end
end

"""
$(TYPEDSIGNATURES)

Build primary field `(label, value, color)` tuples for `IncorrectArgument` display.

# Arguments
- `e::IncorrectArgument`: The exception instance.

# Returns
- `Vector{Tuple{String, Any, Symbol}}`: Vector of `(label, value, color)` tuples.
  Colors are `:yellow` for warnings, `:green` for expected values, `:default` otherwise.

# Notes
- Only includes fields that are not `nothing`.
"""
function _build_primary_pairs(e::IncorrectArgument)
    pairs = []
    !isnothing(e.got) && push!(pairs, ("Got", string(e.got), :yellow))
    !isnothing(e.expected) && push!(pairs, ("Expected", string(e.expected), :green))
    return pairs
end

"""
$(TYPEDSIGNATURES)

Build primary field `(label, value, color)` tuples for `PreconditionError` display.

# Arguments
- `e::PreconditionError`: The exception instance.

# Returns
- `Vector{Tuple{String, Any, Symbol}}`: Vector of `(label, value, color)` tuples.

# Notes
- Only includes fields that are not `nothing`.
"""
function _build_primary_pairs(e::PreconditionError)
    pairs = []
    !isnothing(e.reason) && push!(pairs, ("Reason", string(e.reason), :default))
    return pairs
end

"""
$(TYPEDSIGNATURES)

Build primary field `(label, value, color)` tuples for `NotImplemented` display.

# Arguments
- `e::NotImplemented`: The exception instance.

# Returns
- `Vector{Tuple{String, Any, Symbol}}`: Vector of `(label, value, color)` tuples.

# Notes
- Only includes fields that are not `nothing`.
"""
function _build_primary_pairs(e::NotImplemented)
    pairs = []
    !isnothing(e.required_method) &&
        push!(pairs, ("Method", string(e.required_method), :default))
    return pairs
end

"""
$(TYPEDSIGNATURES)

Build primary field `(label, value, color)` tuples for `ParsingError` display.

# Arguments
- `e::ParsingError`: The exception instance.

# Returns
- `Vector{Tuple{String, Any, Symbol}}`: Vector of `(label, value, color)` tuples.

# Notes
- Only includes fields that are not `nothing`.
"""
function _build_primary_pairs(e::ParsingError)
    pairs = []
    !isnothing(e.location) && push!(pairs, ("Location", string(e.location), :default))
    return pairs
end

"""
$(TYPEDSIGNATURES)

Build primary field `(label, value, color)` tuples for `AmbiguousDescription` display.

# Arguments
- `e::AmbiguousDescription`: The exception instance.

# Returns
- `Vector{Tuple{String, Any, Symbol}}`: Vector of `(label, value, color)` tuples.

# Notes
- The `candidates` field is passed as a `Vector{String}` for multi-line rendering.
- Only includes fields that are not `nothing` or empty.
"""
function _build_primary_pairs(e::AmbiguousDescription)
    pairs = []
    !isnothing(e.diagnostic) &&
        push!(pairs, ("Diagnostic", _format_diagnostic(e.diagnostic), :yellow))
    push!(pairs, ("Requested", string(e.description), :default))
    if !isnothing(e.candidates) && !isempty(e.candidates)
        push!(pairs, ("Available", e.candidates, :default))
    end
    return pairs
end

"""
$(TYPEDSIGNATURES)

Build primary field `(label, value, color)` tuples for `ExtensionError` display.

# Arguments
- `e::ExtensionError`: The exception instance.

# Returns
- `Vector{Tuple{String, Any, Symbol}}`: Single tuple with the missing dependencies.

# Notes
- Always includes the `Missing` field with joined `weakdeps`.
"""
function _build_primary_pairs(e::ExtensionError)
    dep_str = join(string.(e.weakdeps), ", ")
    return [("Missing", dep_str, :yellow)]
end

"""
$(TYPEDSIGNATURES)

Build primary field `(label, value, color)` tuples for `SolverFailure` display.

# Arguments
- `e::SolverFailure`: The exception instance.

# Returns
- `Vector{Tuple{String, Any, Symbol}}`: Vector of `(label, value, color)` tuples.

# Notes
- Only includes fields that are not `nothing`.
"""
function _build_primary_pairs(e::SolverFailure)
    pairs = []
    !isnothing(e.retcode) && push!(pairs, ("Retcode", string(e.retcode), :yellow))
    return pairs
end

"""
$(TYPEDSIGNATURES)

Build secondary field `(label, value, color)` tuples for generic `CTException` display.

# Arguments
- `e::CTException`: The exception instance.

# Returns
- `Vector{Tuple{String, Any, Symbol}}`: Vector of `(label, value, color)` tuples for
  `Context` and `Hint` (from `suggestion`) fields.

# Notes
- Only includes fields that exist and are not `nothing`.
- `Hint` is colored green for visibility.
"""
function _build_secondary_pairs(e::CTException)
    pairs = []
    hasfield(typeof(e), :context) &&
        !isnothing(e.context) &&
        push!(pairs, ("Context", e.context, :default))
    hasfield(typeof(e), :suggestion) &&
        !isnothing(e.suggestion) &&
        push!(pairs, ("Hint", e.suggestion, :green))
    return pairs
end

"""
$(TYPEDSIGNATURES)

Build secondary field `(label, value, color)` tuples for `ExtensionError` display.

# Arguments
- `e::ExtensionError`: The exception instance.

# Returns
- `Vector{Tuple{String, Any, Symbol}}`: Vector of `(label, value, color)` tuples.
  The `Hint` is dynamically generated from `weakdeps`.

# Notes
- The `Hint` field is generated as "Run: using " followed by the joined dependency names.
- This override is necessary because `ExtensionError` does not have a `suggestion` field.
"""
function _build_secondary_pairs(e::ExtensionError)
    pairs = []
    !isnothing(e.context) && push!(pairs, ("Context", e.context, :default))
    hint = "Run: using " * join(string.(e.weakdeps), ", ")
    push!(pairs, ("Hint", hint, :green))
    return pairs
end

"""
$(TYPEDSIGNATURES)

Print a pipe-formatted field with dynamic label alignment.

# Arguments
- `io::IO`: Output stream.
- `label::String`: The field label.
- `value`: The field value (can be a `Vector` for multi-line rendering).
- `max_len::Int`: The maximum label length for alignment.
- `color::Symbol`: The color symbol (`:yellow`, `:green`, or `:default`).

# Notes
- For `Vector` values, the first line includes the label, subsequent lines are indented.
- The pipe character `│` is dimmed for visual hierarchy.
"""
function _print_pipe_field(io, label::String, value, max_len::Int, color::Symbol)
    if value isa Vector
        # Multi-line case: AmbiguousDescription.candidates
        for (i, v) in enumerate(value)
            if i == 1
                print(io, Core._dim("│", io), "  ", Core._bold(rpad(label, max_len), io), "  ")
                _print_colored(io, string(v), color)
                println(io)
            else
                println(io, Core._dim("│", io), "  ", " "^max_len, "  ", string(v))
            end
        end
    else
        # Single value
        print(io, Core._dim("│", io), "  ", Core._bold(rpad(label, max_len), io), "  ")
        _print_colored(io, string(value), color)
        println(io)
    end
end

"""
$(TYPEDSIGNATURES)

Print colored text based on a color symbol.

# Arguments
- `io::IO`: Output stream.
- `text::AbstractString`: The text to print.
- `color::Symbol`: The color symbol (`:yellow`, `:green`, or any other for default).

# Notes
- `:yellow` and `:green` apply ANSI styling; all other colors print as plain text.
"""
function _print_colored(io, text, color::Symbol)
    if color == :yellow
        print(io, Core._yellow(text, io))
    elseif color == :green
        print(io, Core._green(text, io))
    else
        print(io, text)
    end
end

"""
    format_user_friendly_error(io::IO, e::CTException)

Display an error in a user-friendly format with clear sections and user code location.

# Arguments
- `io::IO`: Output stream
- `e::CTException`: The exception to display
"""
function _format_user_friendly_error(io::IO, e::CTException)
    # Line 1: TypeName → func  file:line
    user_frames = _extract_user_frames(stacktrace(catch_backtrace()))
    frame = isempty(user_frames) ? nothing : user_frames[1]

    type_name = string(nameof(typeof(e)))
    print(io, Core._red(type_name, io))

    if !isnothing(frame)
        func_name = string(frame.func)
        file_name = basename(string(frame.file))
        line_num = frame.line
        print(io, " ", Core._dim("→", io), " ", Core._bold(func_name, io), "  ")
        print(io, Core._yellow("$(file_name):$(line_num)", io))
    end
    println(io)

    # Blank pipe separator
    println(io, Core._dim("│", io))

    # Message
    println(io, Core._dim("│", io), "  ", Core._bold(e.msg, io))

    # Build field pairs
    primary_pairs = _build_primary_pairs(e)
    secondary_pairs = _build_secondary_pairs(e)
    all_pairs = vcat(primary_pairs, secondary_pairs)

    if !isempty(all_pairs)
        # Global max_len for alignment
        max_len = maximum(length(p[1]) for p in all_pairs)

        # Blank pipe separator
        println(io, Core._dim("│", io))

        # Primary fields
        for p in primary_pairs
            _print_pipe_field(io, p[1], p[2], max_len, p[3])
        end

        # Separator between primary and secondary
        if !isempty(primary_pairs) && !isempty(secondary_pairs)
            println(io, Core._dim("│", io))
        end

        # Secondary fields
        for p in secondary_pairs
            _print_pipe_field(io, p[1], p[2], max_len, p[3])
        end
    end

    # Closing visual
    return println(io, Core._dim("└─", io))
end

"""
    Base.showerror(io::IO, e::IncorrectArgument)

Custom error display for IncorrectArgument.
Shows user-friendly format with enriched information.
"""
function Base.showerror(io::IO, e::IncorrectArgument)
    return _format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::PreconditionError)

Custom error display for PreconditionError.
"""
function Base.showerror(io::IO, e::PreconditionError)
    return _format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::NotImplemented)

Custom error display for NotImplemented.
"""
function Base.showerror(io::IO, e::NotImplemented)
    return _format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::ParsingError)

Custom error display for ParsingError.
"""
function Base.showerror(io::IO, e::ParsingError)
    return _format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::AmbiguousDescription)

Custom error display for AmbiguousDescription.
"""
function Base.showerror(io::IO, e::AmbiguousDescription)
    return _format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::ExtensionError)

Custom error display for ExtensionError.
"""
function Base.showerror(io::IO, e::ExtensionError)
    return _format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::SolverFailure)

Custom error display for SolverFailure.
"""
function Base.showerror(io::IO, e::SolverFailure)
    return _format_user_friendly_error(io, e)
end
