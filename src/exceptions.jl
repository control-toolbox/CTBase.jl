# --------------------------------------------------------------------------------------------------
# General abstract type for exceptions
abstract type CTException <: Exception end

# ambiguous description
struct AmbiguousDescription <: CTException
    var::Description
end
Base.showerror(io::IO, e::AmbiguousDescription) = print(io, "the description ", e.var, " is ambiguous / incorrect")

# inconsistent argument
struct InconsistentArgument <: CTException
    var::String
end
Base.showerror(io::IO, e::InconsistentArgument) = print(io, e.var)

# incorrect method
struct IncorrectMethod <: CTException
    var::Symbol
end
Base.showerror(io::IO, e::IncorrectMethod) = print(io, e.var, " is not an existing method")

# incorrect argument
struct IncorrectArgument <: CTException
    var::String
end
Base.showerror(io::IO, e::IncorrectArgument) = print(io, e.var)

# incorrect argument
struct IncorrectOutput <: CTException
    var::String
end
Base.showerror(io::IO, e::IncorrectOutput) = print(io, e.var)