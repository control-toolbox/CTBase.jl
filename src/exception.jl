"""
$(TYPEDEF)

Abstract type for exceptions.
"""
abstract type CTException <: Exception end

"""
$(TYPEDEF)

Exception thrown when the description is ambiguous / incorrect.

**Fields**

$(TYPEDFIELDS)
"""
struct AmbiguousDescription <: CTException
    var::Tuple{Vararg{Symbol}}
end

"""
$(TYPEDSIGNATURES)

Print the exception.
"""
Base.showerror(io::IO, e::AmbiguousDescription) =
    print(io, "AmbiguousDescription: the description ", e.var, " is ambiguous / incorrect")

"""
$(TYPEDEF)

Exception thrown when an argument is inconsistent.

**Fields**

$(TYPEDFIELDS)
"""
struct IncorrectArgument <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Print the exception.
"""
Base.showerror(io::IO, e::IncorrectArgument) = print(io, "IncorrectArgument: ", e.var)

"""
$(TYPEDEF)

Exception thrown when a method is incorrect.

**Fields**

$(TYPEDFIELDS)
"""
struct IncorrectMethod <: CTException
    var::Symbol
end

"""
$(TYPEDSIGNATURES)

Print the exception.
"""
Base.showerror(io::IO, e::IncorrectMethod) =
    print(io, "IncorrectMethod: ", e.var, " is not an existing method")

"""
$(TYPEDEF)

Exception thrown when the output is incorrect.

**Fields**

$(TYPEDFIELDS)
"""
struct IncorrectOutput <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Print the exception.
"""
Base.showerror(io::IO, e::IncorrectOutput) = print(io, "IncorrectOutput: ", e.var)

"""
$(TYPEDEF)

Exception thrown when a method is not implemented.

**Fields**

$(TYPEDFIELDS)
"""
struct NotImplemented <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Print the exception.
"""
Base.showerror(io::IO, e::NotImplemented) = print(io, "NotImplemented: ", e.var)

"""
$(TYPEDEF)

Exception thrown when a call to a function is not authorized.

**Fields**

$(TYPEDFIELDS)
"""
struct UnauthorizedCall <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Print the exception.
"""
Base.showerror(io::IO, e::UnauthorizedCall) = print(io, "UnauthorizedCall: ", e.var)
"""
$(TYPEDEF)

Exception thrown for syntax error during abstract parsing.

**Fields**

$(TYPEDFIELDS)
"""
struct ParsingError <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Print the exception.
"""
Base.showerror(io::IO, e::ParsingError) = print(io, "ParsingError: ", e.var)

"""
$(TYPEDEF)

Exception thrown when an extension is not loaded but the user tries to call a function of it.

**Fields**

$(TYPEDFIELDS)
"""
mutable struct ExtensionError <: CTException
    weakdeps::Tuple{Vararg{Symbol}}
    function ExtensionError(weakdeps::Symbol...)
        isempty(weakdeps) && throw(
            UnauthorizedCall(
                "Please provide at least one weak dependence for the extension.",
            ),
        )
        e = new()
        e.weakdeps = weakdeps
        return e
    end
end

"""
$(TYPEDSIGNATURES)

Print the exception.
"""
function Base.showerror(io::IO, e::ExtensionError)
    print(io, "ExtensionError. Please make: ")
    printstyled(io, "julia>", color = :green, bold = true)
    printstyled(io, " using ", color = :magenta)
    N = size(e.weakdeps, 1)
    for i ∈ range(1, N)
        wd = e.weakdeps[i]
        i < N ? print(io, string(wd), ", ") : print(io, string(wd))
    end
    nothing
end
