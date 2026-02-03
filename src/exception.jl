# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Abstract supertype for all custom exceptions in this module.

Use this as the common ancestor for all domain-specific errors to allow
catching all exceptions of this family via `catch e::CTException`.

No fields.

# Example

```julia-repl
julia> using CTBase

julia> try
           throw(CTBase.IncorrectArgument("invalid input"))
       catch e::CTBase.CTException
           println("Caught a domain-specific exception: ", e)
       end
Caught a domain-specific exception: IncorrectArgument: invalid input
```
"""
abstract type CTException <: Exception end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when a description (a tuple of `Symbol`s) cannot be matched to any known
valid descriptions.

This exception is raised by `CTBase.complete()` when the user provides an incomplete or
inconsistent description that doesn't match any of the available descriptions in the
catalogue. Use this exception when **the high-level choice of description itself** is wrong
or ambiguous and there is no sensible default.

# Fields

- `var::Tuple{Vararg{Symbol}}`: The ambiguous or incorrect description tuple that caused the error.

# Example

```julia-repl
julia> using CTBase

julia> D = ((:a, :b), (:a, :b, :c), (:b, :c))
julia> CTBase.complete(:f; descriptions=D)
ERROR: AmbiguousDescription: the description (:f,) is ambiguous / incorrect
```

In this example, the symbol `:f` does not appear in any of the known descriptions,
so `complete()` cannot determine which description to return.

# See Also

- [`complete`](@ref): Matches a partial description to a complete one
- [`add`](@ref): Adds descriptions to a catalogue (throws [`IncorrectArgument`](@ref) for duplicates)
"""
struct AmbiguousDescription <: CTException
    var::Tuple{Vararg{Symbol}}
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.AmbiguousDescription((:x, :y)))
ERROR: AmbiguousDescription: the description (:x, :y) is ambiguous / incorrect
```
"""
function Base.showerror(io::IO, e::AmbiguousDescription)
    printstyled(io, "AmbiguousDescription"; color=:red, bold=true)
    return print(io, ": the description ", e.var, " is ambiguous / incorrect")
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when an individual argument is invalid or violates a precondition.

This exception is raised when **one input value** is outside the allowed domain, such as:
- Wrong range or bounds (e.g., negative when positive is required)
- Duplicate values when uniqueness is required
- Empty collections when non-empty is required
- Type mismatches or invalid combinations

Use this exception to signal that the problem is with the **input data itself**, not with
the state of the system or the calling context. This is distinct from `UnauthorizedCall`,
which indicates a state-related issue.

# Fields

- `var::String`: A descriptive message explaining the nature of the incorrect argument.

# Examples

```julia-repl
julia> using CTBase

julia> throw(CTBase.IncorrectArgument("the argument must be a non-empty tuple"))
ERROR: IncorrectArgument: the argument must be a non-empty tuple
```

Adding a duplicate description to a catalogue:

```julia-repl
julia> algorithms = CTBase.add((), (:a, :b))
julia> CTBase.add(algorithms, (:a, :b))
ERROR: IncorrectArgument: the description (:a, :b) is already in ((:a, :b),)
```

Invalid indices for Unicode helpers:

```julia-repl
julia> CTBase.ctindice(-1)
ERROR: IncorrectArgument: the subscript must be between 0 and 9
```

# See Also

- [`UnauthorizedCall`](@ref): For state-related or context-related errors
- [`AmbiguousDescription`](@ref): For high-level description matching errors
"""
struct IncorrectArgument <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.
"""
function Base.showerror(io::IO, e::IncorrectArgument)
    printstyled(io, "IncorrectArgument"; color=:red, bold=true)
    return print(io, ": ", e.var)
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown to mark interface points that must be implemented by concrete subtypes.

This exception is used to define abstract interfaces where a default method on an abstract
type throws `NotImplemented`, and each concrete implementation must override it. This makes
it easy to detect missing implementations during testing and development.

Use `NotImplemented` when defining **interfaces** and you want an explicit, typed error
rather than a generic `error("TODO")`.

# Fields

- `var::String`: A message indicating what functionality is not yet implemented.

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.NotImplemented("feature X is not implemented"))
ERROR: NotImplemented: feature X is not implemented
```

A typical pattern for defining an interface:

```julia
abstract type MyAbstractAlgorithm end

function run!(algo::MyAbstractAlgorithm, state)
    throw(CTBase.NotImplemented("run! is not implemented for \$(typeof(algo))"))
end
```

Concrete algorithms then provide their own `run!` method instead of raising this exception.

# See Also

- [`UnauthorizedCall`](@ref): For state-related errors
- [`IncorrectArgument`](@ref): For input validation errors
"""
struct NotImplemented <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.
"""
function Base.showerror(io::IO, e::NotImplemented)
    printstyled(io, "NotImplemented"; color=:red, bold=true)
    return print(io, ": ", e.var)
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when a function call is not allowed in the **current state** of the
object or system.

This exception signals that the arguments may be valid, but the call is forbidden because
of **when** or **how** it is made. This is distinct from `IncorrectArgument`, which
indicates a problem with the input values themselves.

Common use cases:
- A method that is meant to be called only once
- State already closed or finalized
- Missing permissions or access rights
- Illegal order of operations
- Wrong phase of a computation

# Fields

- `var::String`: A message explaining why the call is unauthorized.

# Examples

```julia-repl
julia> using CTBase

julia> throw(CTBase.UnauthorizedCall("user does not have permission"))
ERROR: UnauthorizedCall: user does not have permission
```

A typical pattern for state-dependent operations:

```julia
function finalize!(s::SomeState)
    if s.is_finalized
        throw(CTBase.UnauthorizedCall("finalize! was already called for this state"))
    end
    # ... perform finalisation and mark state as finalised ...
end
```

# See Also

- [`IncorrectArgument`](@ref): For input validation errors
- [`NotImplemented`](@ref): For unimplemented interface methods
"""
struct UnauthorizedCall <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.
"""
function Base.showerror(io::IO, e::UnauthorizedCall)
    printstyled(io, "UnauthorizedCall"; color=:red, bold=true)
    return print(io, ": ", e.var)
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown during parsing when a syntax error or invalid structure is detected.

This exception is intended for errors detected during parsing of input structures or
domain-specific languages (DSLs). Use this when processing user input that follows a
specific grammar or format, and the input violates the expected syntax.

# Fields

- `var::String`: A message describing the parsing error.

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.ParsingError("unexpected token 'end'"))
ERROR: ParsingError: unexpected token 'end'
```

# See Also

- [`IncorrectArgument`](@ref): For general input validation errors
- [`AmbiguousDescription`](@ref): For description matching errors
"""
struct ParsingError <: CTException
    var::String
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception.
"""
function Base.showerror(io::IO, e::ParsingError)
    printstyled(io, "ParsingError"; color=:red, bold=true)
    return print(io, ": ", e.var)
end

# ------------------------------------------------------------------------
"""
$(TYPEDEF)

Exception thrown when an extension or optional dependency is not loaded but
a function requiring it is called.

This exception is used to signal that a feature requires one or more optional dependencies
(weak dependencies) to be loaded. When a user tries to use a feature without loading the
required extensions, this exception provides a helpful message indicating exactly which
packages need to be loaded.

It is also used internally by `ExtensionError()` when called without any weak dependencies,
in which case it throws `UnauthorizedCall` instead.

# Fields

- `weakdeps::Tuple{Vararg{Symbol}}`: The tuple of symbols representing the missing dependencies.
- `var::String`: An optional message to display after the "Please make: ..." instruction.

# Constructor

```julia
ExtensionError(weakdeps::Symbol...; message::String="")
```

Throws `UnauthorizedCall` if no weak dependencies are provided:

```julia
CTBase.ExtensionError()  # Throws UnauthorizedCall
```

# Examples

```julia-repl
julia> using CTBase

julia> throw(CTBase.ExtensionError(:MyExtension))
ERROR: ExtensionError. Please make: julia> using MyExtension
```

With multiple dependencies and a custom message:

```julia-repl
julia> throw(CTBase.ExtensionError(:MyExtension, :AnotherDep; message="to use this feature"))
ERROR: ExtensionError. Please make: julia> using MyExtension, AnotherDep to use this feature
```

# See Also

- [`UnauthorizedCall`](@ref): Thrown when `ExtensionError()` is called without arguments
"""
struct ExtensionError <: CTException
    weakdeps::Tuple{Vararg{Symbol}}
    var::String
    function ExtensionError(weakdeps::Symbol...; message::String="")
        isempty(weakdeps) && throw(
            UnauthorizedCall(
                "Please provide at least one weak dependence for the extension."
            ),
        )
        return new(weakdeps, message)
    end
end

"""
$(TYPEDSIGNATURES)

Customizes the printed message of the exception, prompting the user
to load the required extensions.

# Example

```julia-repl
julia> using CTBase

julia> e = CTBase.ExtensionError(:MyExtension, :AnotherDep)
julia> showerror(stdout, e)
ERROR: ExtensionError. Please make: julia> using MyExtension, AnotherDep
```
"""
function Base.showerror(io::IO, e::ExtensionError)
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
    if !isempty(e.var)
        print(io, " ", e.var)
    end
    return nothing
end
