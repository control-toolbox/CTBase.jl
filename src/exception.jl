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
Base.showerror(io::IO, e::AmbiguousDescription) = print(io, "AmbiguousDescription: the description ", e.var, " is ambiguous / incorrect")

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
Base.showerror(io::IO, e::IncorrectMethod) = print(io, "IncorrectMethod: ", e.var, " is not an existing method")

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
