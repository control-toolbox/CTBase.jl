# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Abstract supertype for all custom exceptions in this module.

Use this as the common ancestor for all domain-specific errors to allow
catching all exceptions of this family via `catch e::CTException`.

No fields.

# Example

```julia-repl
julia> try
           throw(IncorrectArgument("invalid input"))
       catch e::CTException
           println("Caught a domain-specific exception: ", e)
       end
Caught a domain-specific exception: IncorrectArgument: invalid input
```
"""
abstract type CTException <: Exception end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when a description is ambiguous or does not match any known descriptions.

# Fields

- `var::Tuple{Vararg{Symbol}}`: The ambiguous or incorrect description tuple that caused the error.

# Example

```julia-repl
julia> complete(:f; descriptions=((:a, :b), (:a, :b, :c)))
ERROR: AmbiguousDescription: the description (:f,) is ambiguous / incorrect
```

This error is useful to signal when a user provides a description that cannot be matched
to any known valid descriptions.
"""
struct AmbiguousDescription <: CTException
    var::Tuple{Vararg{Symbol}}
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.

# Example

```julia-repl
julia> throw(AmbiguousDescription((:x, :y)))
ERROR: AmbiguousDescription: the description (:x, :y) is ambiguous / incorrect
```
"""
Base.showerror(io::IO, e::AmbiguousDescription) = begin
    printstyled(io, "AmbiguousDescription", color=:red, bold=true)
    print(io, ": the description ", e.var, " is ambiguous / incorrect")
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when an argument passed to a function or constructor is inconsistent,
invalid, or does not satisfy preconditions.

# Fields

- `var::String`: A descriptive message explaining the nature of the incorrect argument.

# Example

```julia-repl
julia> throw(IncorrectArgument("the argument must be a non-empty tuple"))
ERROR: IncorrectArgument: the argument must be a non-empty tuple
```
"""
struct IncorrectArgument <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.
"""
Base.showerror(io::IO, e::IncorrectArgument) = begin
    printstyled(io, "IncorrectArgument", color=:red, bold=true)
    print(io, ": ", e.var)
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when a specified method name or function symbol does not exist.

# Fields

- `var::Symbol`: The method or function symbol that was expected but not found.

# Example

```julia-repl
julia> throw(IncorrectMethod(:nonexistent_func))
ERROR: IncorrectMethod: nonexistent_func is not an existing method
```
"""
struct IncorrectMethod <: CTException
    var::Symbol
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.
"""
Base.showerror(io::IO, e::IncorrectMethod) = begin
    printstyled(io, "IncorrectMethod", color=:red, bold=true)
    print(io, ": ", e.var, " is not an existing method")
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when the output produced by a function is incorrect or inconsistent
with expected results.

# Fields

- `var::String`: A descriptive message explaining the incorrect output.

# Example

```julia-repl
julia> throw(IncorrectOutput("the function returned NaN"))
ERROR: IncorrectOutput: the function returned NaN
```
"""
struct IncorrectOutput <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.
"""
Base.showerror(io::IO, e::IncorrectOutput) = begin
    printstyled(io, "IncorrectOutput", color=:red, bold=true)
    print(io, ": ", e.var)
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when a method or function has not been implemented yet.

# Fields

- `var::String`: A message indicating what functionality is not yet implemented.

# Example

```julia-repl
julia> throw(NotImplemented("feature X is not implemented"))
ERROR: NotImplemented: feature X is not implemented
```
"""
struct NotImplemented <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.
"""
Base.showerror(io::IO, e::NotImplemented) = begin
    printstyled(io, "NotImplemented", color=:red, bold=true)
    print(io, ": ", e.var)
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when a function call is not authorized in the current context
or with the given arguments.

# Fields

- `var::String`: A message explaining why the call is unauthorized.

# Example

```julia-repl
julia> throw(UnauthorizedCall("user does not have permission"))
ERROR: UnauthorizedCall: user does not have permission
```
"""
struct UnauthorizedCall <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.
"""
Base.showerror(io::IO, e::UnauthorizedCall) = begin
    printstyled(io, "UnauthorizedCall", color=:red, bold=true)
    print(io, ": ", e.var)
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown during parsing when a syntax error or invalid structure
is detected.

# Fields

- `var::String`: A message describing the parsing error.

# Example

```julia-repl
julia> throw(ParsingError("unexpected token"))
ERROR: ParsingError: unexpected token
```
"""
struct ParsingError <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.
"""
Base.showerror(io::IO, e::ParsingError) = begin
    printstyled(io, "ParsingError", color=:red, bold=true)
    print(io, ": ", e.var)
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when an extension or optional dependency is not loaded but
a function requiring it is called.

# Fields

- `weakdeps::Tuple{Vararg{Symbol}}`: The tuple of symbols representing the missing dependencies.

# Constructor

Throws `UnauthorizedCall` if no weak dependencies are provided.

# Example

```julia-repl
julia> throw(ExtensionError(:MyExtension))
ERROR: ExtensionError. Please make: julia> using MyExtension
```
"""
struct ExtensionError <: CTException
    weakdeps::Tuple{Vararg{Symbol}}
    function ExtensionError(weakdeps::Symbol...)
        isempty(weakdeps) && throw(
            UnauthorizedCall(
                "Please provide at least one weak dependence for the extension."
            ),
        )
        new(weakdeps)
    end
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception, prompting the user
to load the required extensions.

# Example

```julia-repl
julia> e = ExtensionError(:MyExtension, :AnotherDep)
julia> showerror(stdout, e)
ERROR: ExtensionError. Please make: julia> using MyExtension, AnotherDep
```
"""
function Base.showerror(io::IO, e::ExtensionError)
    printstyled(io, "ExtensionError", color=:red, bold=true)
    print(io, ". Please make: ")
    printstyled(io, "julia>", color=:green, bold=true)
    printstyled(io, " using ", color=:magenta)
    N = length(e.weakdeps)
    for i in 1:N
        wd = e.weakdeps[i]
        if i < N
            print(io, string(wd), ", ")
        else
            print(io, string(wd))
        end
    end
    return nothing
end
