# Custom display functions for user-friendly error messages

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
    println(io, "\n" * "━"^70)
    printstyled(io, "❌ Control Toolbox Error\n"; color=:red, bold=true)
    println(io, "━"^70)

    # Main problem
    println(io, "\n📋 Problem:")
    println(io, "   ", typeof(e).name, ": ", e.msg)

    # Type-specific details
    if e isa IncorrectArgument
        if !isnothing(e.got)
            println(io, "\n🔍 Details:")
            println(io, "   Got:      ", e.got)
            if !isnothing(e.expected)
                println(io, "   Expected: ", e.expected)
            end
        end

        if !isnothing(e.context)
            println(io, "\n📂 Context:")
            println(io, "   ", e.context)
        end

        if !isnothing(e.suggestion)
            println(io, "\n💡 Suggestion:")
            println(io, "   ", e.suggestion)
        end

    elseif e isa UnauthorizedCall
        if !isnothing(e.reason)
            println(io, "\n❓ Reason:")
            println(io, "   ", e.reason)
        end

        if !isnothing(e.context)
            println(io, "\n📂 Context:")
            println(io, "   ", e.context)
        end

        if !isnothing(e.suggestion)
            println(io, "\n💡 Suggestion:")
            println(io, "   ", e.suggestion)
        end

    elseif e isa NotImplemented
        if !isnothing(e.type_info)
            println(io, "\n🔧 Type:")
            println(io, "   ", e.type_info)
        end

        if !isnothing(e.context)
            println(io, "\n📂 Context:")
            println(io, "   ", e.context)
        end

        if !isnothing(e.suggestion)
            println(io, "\n💡 Suggestion:")
            println(io, "   ", e.suggestion)
        end

    elseif e isa ParsingError
        if !isnothing(e.location)
            println(io, "\n📍 Location:")
            println(io, "   ", e.location)
        end

        if !isnothing(e.suggestion)
            println(io, "\n💡 Suggestion:")
            println(io, "   ", e.suggestion)
        end

    elseif e isa AmbiguousDescription
        println(io, "\n🔍 Description:")
        println(io, "   ", e.description)

        if !isnothing(e.candidates)
            println(io, "\n💡 Valid candidates:")
            for candidate in e.candidates
                println(io, "   - ", candidate)
            end
        end

        if !isnothing(e.context)
            println(io, "\n📂 Context:")
            println(io, "   ", e.context)
        end

        if !isnothing(e.suggestion)
            println(io, "\n💡 Suggestion:")
            println(io, "   ", e.suggestion)
        end

    elseif e isa ExtensionError
        println(io, "\n📦 Missing dependencies:")
        for (i, dep) in enumerate(e.weakdeps)
            if i == 1
                print(io, "   ", dep)
            else
                print(io, ", ", dep)
            end
        end
        println(io)

        if !isnothing(e.feature)
            println(io, "\n🔧 Feature:")
            println(io, "   ", e.feature)
        end

        if !isnothing(e.context)
            println(io, "\n📂 Context:")
            println(io, "   ", e.context)
        end

        if !isempty(e.msg) && e.msg != "missing dependencies"
            println(io, "\n🎯 Purpose:")
            println(io, "   ", e.msg)
        end

        println(io, "\n💡 Suggestion:")
        printstyled(io, "   julia> using "; color=:green)
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
        println(io, "\n📍 In your code:")
        # Show up to 3 most relevant user frames
        for (i, frame) in enumerate(user_frames[1:min(3, length(user_frames))])
            file_name = basename(string(frame.file))
            line_info = frame.line
            func_name = frame.func

            if i == 1
                # The most recent frame (where error occurred)
                println(io, "   $func_name at $file_name:$line_info")
            else
                # Previous frames (call stack)
                println(io, "   called from $func_name at $file_name:$line_info")
            end
        end
    end

    # Stacktrace info
    if !SHOW_FULL_STACKTRACE[]
        println(io, "\n💬 Note:")
        println(io, "   For full Julia stacktrace, run:")
        printstyled(io, "   CTBase.set_show_full_stacktrace!(true)\n"; color=:cyan)
    end

    println(io, "━"^70 * "\n")
end

"""
    Base.showerror(io::IO, e::IncorrectArgument)

Custom error display for IncorrectArgument.
Shows user-friendly format if SHOW_FULL_STACKTRACE is false.
"""
function Base.showerror(io::IO, e::IncorrectArgument)
    if SHOW_FULL_STACKTRACE[]
        # Standard Julia error display
        printstyled(io, "IncorrectArgument"; color=:red, bold=true)
        print(io, ": ", e.msg)
        if !isnothing(e.got)
            print(io, " (got: ", e.got, ")")
        end
        if !isnothing(e.expected)
            print(io, " (expected: ", e.expected, ")")
        end
    else
        # User-friendly display
        format_user_friendly_error(io, e)
    end
end

"""
    Base.showerror(io::IO, e::UnauthorizedCall)

Custom error display for UnauthorizedCall.
"""
function Base.showerror(io::IO, e::UnauthorizedCall)
    if SHOW_FULL_STACKTRACE[]
        printstyled(io, "UnauthorizedCall"; color=:red, bold=true)
        print(io, ": ", e.msg)
        if !isnothing(e.reason)
            print(io, " (reason: ", e.reason, ")")
        end
    else
        format_user_friendly_error(io, e)
    end
end

"""
    Base.showerror(io::IO, e::NotImplemented)

Custom error display for NotImplemented.
"""
function Base.showerror(io::IO, e::NotImplemented)
    if SHOW_FULL_STACKTRACE[]
        printstyled(io, "NotImplemented"; color=:red, bold=true)
        print(io, ": ", e.msg)
    else
        format_user_friendly_error(io, e)
    end
end

"""
    Base.showerror(io::IO, e::ParsingError)

Custom error display for ParsingError.
"""
function Base.showerror(io::IO, e::ParsingError)
    if SHOW_FULL_STACKTRACE[]
        printstyled(io, "ParsingError"; color=:red, bold=true)
        print(io, ": ", e.msg)
        if !isnothing(e.location)
            print(io, " (at: ", e.location, ")")
        end
    else
        format_user_friendly_error(io, e)
    end
end

"""
    Base.showerror(io::IO, e::AmbiguousDescription)

Custom error display for AmbiguousDescription.
"""
function Base.showerror(io::IO, e::AmbiguousDescription)
    if SHOW_FULL_STACKTRACE[]
        printstyled(io, "AmbiguousDescription"; color=:red, bold=true)
        print(io, ": the description ", e.description, " is ambiguous / incorrect")
        if !isnothing(e.context)
            print(io, " (context: ", e.context, ")")
        end
    else
        format_user_friendly_error(io, e)
    end
end

"""
    Base.showerror(io::IO, e::ExtensionError)

Custom error display for ExtensionError.
"""
function Base.showerror(io::IO, e::ExtensionError)
    if SHOW_FULL_STACKTRACE[]
        printstyled(io, "ExtensionError"; color=:red, bold=true)
        print(io, ". Please make: ")
        printstyled(io, "julia>"; color=:green, bold=true)
        printstyled(io, " using "; color=:magenta)
        N = length(e.weakdeps)
        for i in 1:N
            wd = e.weakdeps[i]
            if i < N
                print(io, string(wd), ", ")
            else
                print(io, string(wd))
            end
        end
        if !isempty(e.msg) && e.msg != "missing dependencies"
            print(io, " ", e.msg)
        end
    else
        format_user_friendly_error(io, e)
    end
end
