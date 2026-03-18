# Custom display functions for user-friendly error messages

"""
Generate ANSI escape sequence for the specified color and formatting.
"""
function _ansi_color(color::Symbol, bold::Bool=false)
    color_codes = Dict(
        :black => 30,
        :red => 31,
        :green => 32,
        :yellow => 33,
        :blue => 34,
        :magenta => 35,
        :cyan => 36,
        :white => 37,
        :default => 39,
    )

    code = get(color_codes, color, 39)
    return bold ? "\033[1;$(code)m" : "\033[$(code)m"
end

"""Generate ANSI reset sequence to clear formatting."""
_ansi_reset() = "\033[0m"

"""
Print text with ANSI color formatting for Documenter compatibility.
"""
function _print_ansi_styled(
    io, text::Union{String,Symbol,Type}, color::Symbol, bold::Bool=false
)
    print(io, _ansi_color(color, bold), string(text), _ansi_reset())
end

"""
    extract_user_frames(st::Vector)

Extract stacktrace frames that are relevant to user code.
Filters out Julia stdlib.

# Arguments
- `st::Vector`: Stacktrace from `stacktrace(catch_backtrace())`

# Returns
- `Vector`: Filtered stacktrace frames
"""
function extract_user_frames(st::Vector)
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
    format_user_friendly_error(io::IO, e::CTException)

Display an error in a user-friendly format with clear sections and user code location.

# Arguments
- `io::IO`: Output stream
- `e::CTException`: The exception to display
"""
function format_user_friendly_error(io::IO, e::CTException)
    #println(io, "\n" * "━"^70)
    _print_ansi_styled(io, "Control Toolbox Error\n", :red, true)
    #println(io, "─"^28)

    # Main problem
    print(io, "\n❌ Error: ")
    _print_ansi_styled(io, typeof(e), :red, true)
    println(io, ", ", e.msg)

    # Type-specific details
    if e isa IncorrectArgument
        if !isnothing(e.got)
            print(io, "🔍 Got: ", e.got)
            if !isnothing(e.expected)
                print(io, ", Expected: ", e.expected)
            end
            println(io)
        end

        if !isnothing(e.context)
            println(io, "📂 Context: ", e.context)
        end

        if !isnothing(e.suggestion)
            println(io, "💡 Suggestion: ", e.suggestion)
        end

    elseif e isa PreconditionError
        if !isnothing(e.reason)
            println(io, "❓ Reason: ", e.reason)
        end

        if !isnothing(e.context)
            println(io, "📂 Context: ", e.context)
        end

        if !isnothing(e.suggestion)
            println(io, "💡 Suggestion: ", e.suggestion)
        end

    elseif e isa NotImplemented
        if !isnothing(e.required_method)
            println(io, "🔧 Required method: ", e.required_method)
        end

        if !isnothing(e.context)
            println(io, "📂 Context: ", e.context)
        end

        if !isnothing(e.suggestion)
            println(io, "💡 Suggestion: ", e.suggestion)
        end

    elseif e isa ParsingError
        if !isnothing(e.location)
            println(io, "📍 Location: ", e.location)
        end

        if !isnothing(e.suggestion)
            println(io, "💡 Suggestion: ", e.suggestion)
        end

    elseif e isa AmbiguousDescription
        # Show diagnostic first for clarity - on one line
        if !isnothing(e.diagnostic)
            print(io, "⚠️  Diagnostic: ")
            if e.diagnostic == "empty catalog"
                _print_ansi_styled(io, "Empty catalog", :yellow, true)
                print(io, " - no descriptions available")
            elseif e.diagnostic == "unknown symbols"
                _print_ansi_styled(io, "Unknown symbols", :yellow, true)
                print(
                    io,
                    " - none of the requested symbols appear in any available description",
                )
            elseif e.diagnostic == "no complete match"
                _print_ansi_styled(io, "No complete match", :yellow, true)
                print(io, " - no available description contains all the requested symbols")
            else
                print(io, e.diagnostic)
            end
            println(io)
        end

        # Requested description on one line
        println(io, "🎯 Requested description: ", e.description)

        if !isnothing(e.candidates) && !isempty(e.candidates)
            println(io, "📋 Available descriptions:")
            for candidate in e.candidates
                println(io, "   - ", candidate)
            end
        end

        if !isnothing(e.context)
            println(io, "📂 Context: ", e.context)
        end

        # Suggestion on one line
        if !isnothing(e.suggestion)
            print(io, "💡 Suggestion: ", e.suggestion)

            # Show closest matches directly in the suggestion if it ends with ":"
            if endswith(strip(e.suggestion), ":") &&
                contains(e.suggestion, "closest matches")
                if !isnothing(e.candidates) && !isempty(e.candidates)
                    # Show up to 3 candidates as closest matches
                    max_show = min(3, length(e.candidates))
                    for i in 1:max_show
                        if i == 1
                            print(io, " ", e.candidates[i])
                        else
                            print(io, ", ", e.candidates[i])
                        end
                    end
                end
            end
            println(io)
        end

    elseif e isa ExtensionError
        # Missing dependencies on one line
        print(io, "📦 Missing dependencies: ")
        for (i, dep) in enumerate(e.weakdeps)
            if i == 1
                print(io, dep)
            else
                print(io, ", ", dep)
            end
        end
        println(io)

        # Suggestion on one line
        print(io, "💡 Suggestion: ")
        _print_ansi_styled(io, "julia>", :green, true)
        _print_ansi_styled(io, " using ", :magenta)
        for (i, dep) in enumerate(e.weakdeps)
            if i == 1
                print(io, dep)
            else
                print(io, ", ", dep)
            end
        end
        println(io)
    end

    # Add user code location
    user_frames = extract_user_frames(stacktrace(catch_backtrace()))
    if !isempty(user_frames)
        println(io, "📍 In your code:")
        # Show up to 3 most relevant user frames
        for (i, frame) in enumerate(user_frames[1:min(3, length(user_frames))])
            file_name = basename(string(frame.file))
            line_info = frame.line
            func_name = frame.func

            if i == 1
                # The most recent frame (where error occurred)
                println(io, "     $func_name at $file_name:$line_info")
            else
                # Previous frames (call stack) - show call hierarchy with visual arrows
                arrow_prefix = "     " * "    "^(i-2) * "└── "
                println(io, "$(arrow_prefix)$func_name at $file_name:$line_info")
            end
        end
    end

    #println(io, "━"^70 * "\n")
end

"""
    Base.showerror(io::IO, e::IncorrectArgument)

Custom error display for IncorrectArgument.
Shows user-friendly format with enriched information.
"""
function Base.showerror(io::IO, e::IncorrectArgument)
    format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::PreconditionError)

Custom error display for PreconditionError.
"""
function Base.showerror(io::IO, e::PreconditionError)
    format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::NotImplemented)

Custom error display for NotImplemented.
"""
function Base.showerror(io::IO, e::NotImplemented)
    format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::ParsingError)

Custom error display for ParsingError.
"""
function Base.showerror(io::IO, e::ParsingError)
    format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::AmbiguousDescription)

Custom error display for AmbiguousDescription.
"""
function Base.showerror(io::IO, e::AmbiguousDescription)
    format_user_friendly_error(io, e)
end

"""
    Base.showerror(io::IO, e::ExtensionError)

Custom error display for ExtensionError.
"""
function Base.showerror(io::IO, e::ExtensionError)
    format_user_friendly_error(io, e)
end
