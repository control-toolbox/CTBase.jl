# Exception type definitions for CTBase
# Based on CTBase.jl but with enriched error handling

"""
    CTException

Abstract supertype for all CTBase exceptions.
Compatible with CTBase.CTException for future migration.

All exceptions inherit from this type to allow uniform error handling.

# Example

```julia-repl
julia> using CTBase

julia> try
           throw(CTBase.Exceptions.IncorrectArgument("invalid input"))
       catch e::CTBase.Exceptions.CTException
           println("Caught a domain-specific exception: ", e)
       end
Caught a domain-specific exception: IncorrectArgument: invalid input
```

# Usage Pattern

Use this as the common ancestor for all domain-specific errors to allow
catching all exceptions of this family via `catch e::CTException`.

```julia
try
    # code that may throw CTBase exceptions
    risky_operation()
catch e::CTBase.Exceptions.CTException
    # handle all CTBase domain errors uniformly
    handle_error(e)
end
```
"""
abstract type CTException <: Exception end

"""
    IncorrectArgument <: CTException

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
- `msg::String`: Main error message describing the problem
- `got::Union{String, Nothing}`: What value was received (optional)
- `expected::Union{String, Nothing}`: What value was expected (optional)
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional)
- `context::Union{String, Nothing}`: Where the error occurred (optional)

# Examples

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.IncorrectArgument("the argument must be a non-empty tuple"))
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

Enhanced version with detailed context:

```julia
throw(CTBase.Exceptions.IncorrectArgument(
    "Dimension mismatch",
    got="vector of length 3",
    expected="vector of length 2",
    suggestion="Provide a vector matching the state dimension",
    context="initial_guess for state"
))
```

# See Also
- [`UnauthorizedCall`](@ref): For state-related or context-related errors
- [`AmbiguousDescription`](@ref): For high-level description matching errors
- [`set_show_full_stacktrace!`](@ref): Control stacktrace display
"""
struct IncorrectArgument <: CTException
    msg::String
    got::Union{String,Nothing}
    expected::Union{String,Nothing}
    suggestion::Union{String,Nothing}
    context::Union{String,Nothing}

    # Constructor for enriched exceptions
    IncorrectArgument(
        msg::String;
        got::Union{String,Nothing}=nothing,
        expected::Union{String,Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
        context::Union{String,Nothing}=nothing,
    ) = new(msg, got, expected, suggestion, context)
end

"""
    UnauthorizedCall <: CTException

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
- `msg::String`: Main error message
- `reason::Union{String, Nothing}`: Why the call is unauthorized (optional)
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional)
- `context::Union{String, Nothing}`: Where the error occurred (optional)

# Examples

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.UnauthorizedCall("user does not have permission"))
ERROR: UnauthorizedCall: user does not have permission
```

A typical pattern for state-dependent operations:

```julia
function finalize!(s::SomeState)
    if s.is_finalized
        throw(CTBase.Exceptions.UnauthorizedCall(
            "finalize! was already called for this state",
            reason="state already finalized",
            suggestion="Create a new instance or check finalization status"
        ))
    end
    # ... perform finalisation and mark state as finalised ...
end
```

Enhanced version with detailed context:

```julia
throw(CTBase.Exceptions.UnauthorizedCall(
    "Cannot call state! twice",
    reason="state has already been defined for this OCP",
    suggestion="Create a new OCP instance or use a different component name",
    context="state definition"
))
```

# See Also
- [`IncorrectArgument`](@ref): For input validation errors
- [`NotImplemented`](@ref): For unimplemented interface methods
"""
struct UnauthorizedCall <: CTException
    msg::String
    reason::Union{String,Nothing}
    suggestion::Union{String,Nothing}
    context::Union{String,Nothing}

    UnauthorizedCall(
        msg::String;
        reason::Union{String,Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
        context::Union{String,Nothing}=nothing,
    ) = new(msg, reason, suggestion, context)
end

"""
    NotImplemented <: CTException

Exception thrown to mark interface points that must be implemented by concrete subtypes.

This exception is used to define abstract interfaces where a default method on an abstract
type throws `NotImplemented`, and each concrete implementation must override it. This makes
it easy to detect missing implementations during testing and development.

Use `NotImplemented` when defining **interfaces** and you want an explicit, typed error
rather than a generic `error("TODO")`.

# Fields
- `msg::String`: Description of what is not implemented
- `type_info::Union{String, Nothing}`: Type information (optional)
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional)
- `context::Union{String, Nothing}`: Where the error occurred (optional)

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.NotImplemented("feature X is not implemented"))
ERROR: NotImplemented: feature X is not implemented
```

A typical pattern for defining an interface:

```julia
abstract type MyAbstractAlgorithm end

function run!(algo::MyAbstractAlgorithm, state)
    throw(CTBase.Exceptions.NotImplemented(
        "run! is not implemented for \$(typeof(algo))",
        type_info="MyAbstractAlgorithm",
        context="algorithm execution",
        suggestion="Implement run! for your concrete algorithm type"
    ))
end
```

Concrete algorithms then provide their own `run!` method instead of raising this exception.

Enhanced version with full context:

```julia
throw(CTBase.Exceptions.NotImplemented(
    "Method solve! not implemented",
    type_info="MyStrategy",
    context="solve call",
    suggestion="Import the relevant package (e.g. CTDirect) or implement solve!(::MyStrategy, ...)"
))
```

# See Also
- [`UnauthorizedCall`](@ref): For state-related errors
- [`IncorrectArgument`](@ref): For input validation errors
"""
struct NotImplemented <: CTException
    msg::String
    type_info::Union{String,Nothing}
    suggestion::Union{String,Nothing}
    context::Union{String,Nothing}

    NotImplemented(
        msg::String;
        type_info::Union{String,Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
        context::Union{String,Nothing}=nothing,
    ) = new(msg, type_info, suggestion, context)
end

"""
    ParsingError <: CTException

Exception thrown during parsing when a syntax error or invalid structure is detected.

This exception is intended for errors detected during parsing of input structures or
domain-specific languages (DSLs). Use this when processing user input that follows a
specific grammar or format, and the input violates the expected syntax.

This exception is raised when **the structure or syntax** of the input is invalid,
rather than the semantic meaning. For semantic errors, use `IncorrectArgument` instead.

# Fields
- `msg::String`: Description of the parsing error
- `location::Union{String, Nothing}`: Where in the input the error occurred (optional)
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional)

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.ParsingError("unexpected token 'end'"))
ERROR: ParsingError: unexpected token 'end'
```

Enhanced version with location and suggestion:

```julia
throw(CTBase.Exceptions.ParsingError(
    "Unexpected token 'end'",
    location="line 42, column 15",
    suggestion="Check syntax balance or remove extra 'end'"
))
```

Common use cases:
- Parsing mathematical expressions or formulas
- Reading configuration files or DSL syntax
- Processing structured input with specific grammar rules
- Validating syntax of domain-specific languages

# See Also
- [`IncorrectArgument`](@ref): For general input validation errors
- [`AmbiguousDescription`](@ref): For description matching errors
"""
struct ParsingError <: CTException
    msg::String
    location::Union{String,Nothing}
    suggestion::Union{String,Nothing}

    ParsingError(
        msg::String;
        location::Union{String,Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
    ) = new(msg, location, suggestion)
end

"""
    AmbiguousDescription <: CTException

Exception thrown when a description (a tuple of `Symbol`s) cannot be matched to any known
valid descriptions.

This exception is raised by `CTBase.complete()` when the user provides an incomplete or
inconsistent description that doesn't match any of the available descriptions in the
catalogue. Use this exception when **the high-level choice of description itself** is wrong
or ambiguous and there is no sensible default.

Enhanced version with additional context for better error reporting.

# Fields
- `msg::String`: Main error message (auto-generated if not provided)
- `description::Tuple{Vararg{Symbol}}`: The ambiguous or incorrect description tuple
- `candidates::Union{Vector{String}, Nothing}`: Suggested valid descriptions (optional)
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional)
- `context::Union{String, Nothing}`: Where the error occurred (optional)

# Example

```julia-repl
julia> using CTBase

julia> D = ((:a, :b), (:a, :b, :c), (:b, :c))
julia> CTBase.complete(:f; descriptions=D)
ERROR: AmbiguousDescription: the description (:f,) is ambiguous / incorrect
```

In this example, the symbol `:f` does not appear in any of the known descriptions,
so `complete()` cannot determine which description to return.

Enhanced version with full context:

```julia
throw(CTBase.Exceptions.AmbiguousDescription(
    (:f,),
    candidates=["(:descent, :bfgs, :bisection)", "(:descent, :gradient, :fixedstep)"],
    suggestion="Use a complete description like (:descent, :bfgs, :bisection)",
    context="algorithm selection"
))
```

# Common Use Cases
- Algorithm selection in optimization libraries
- Configuration matching in DSL systems
- Pattern matching in description-based APIs
- Validation of symbolic descriptions in mathematical modeling

# See Also
- `complete`: Matches a partial description to a complete one
- `add`: Adds descriptions to a catalogue (throws [`IncorrectArgument`](@ref) for duplicates)
- [`IncorrectArgument`](@ref): For input validation errors
"""
struct AmbiguousDescription <: CTException
    msg::String
    description::Tuple{Vararg{Symbol}}
    candidates::Union{Vector{String},Nothing}
    suggestion::Union{String,Nothing}
    context::Union{String,Nothing}

    AmbiguousDescription(
        description::Tuple{Vararg{Symbol}};
        msg::String="the description $(description) is ambiguous / incorrect",
        candidates::Union{Vector{String},Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
        context::Union{String,Nothing}=nothing,
    ) = new(msg, description, candidates, suggestion, context)
end

"""
    ExtensionError <: CTException

Exception thrown when an extension or optional dependency is not loaded but
a function requiring it is called.

This exception is used to signal that a feature requires one or more optional dependencies
(weak dependencies) to be loaded. When a user tries to use a feature without loading the
required extensions, this exception provides a helpful message indicating exactly which
packages need to be loaded.

It is also used internally by `ExtensionError()` when called without any weak dependencies,
in which case it throws `UnauthorizedCall` instead.

Enhanced version with additional context for better error reporting.

# Fields
- `msg::String`: Main error message (auto-generated from message parameter)
- `weakdeps::Tuple{Vararg{Symbol}}`: The tuple of symbols representing the missing dependencies
- `feature::Union{String, Nothing}`: Which functionality requires these dependencies (optional)
- `context::Union{String, Nothing}`: Where the error occurred (optional)

# Constructor

```julia
ExtensionError(weakdeps::Symbol...; message::String="", feature::Union{String, Nothing}=nothing, context::Union{String, Nothing}=nothing)
```

Throws `UnauthorizedCall` if no weak dependencies are provided:

```julia
ExtensionError()  # Throws UnauthorizedCall
```

# Examples

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.ExtensionError(:MyExtension))
ERROR: ExtensionError. Please make: julia> using MyExtension
```

With multiple dependencies and a custom message:

```julia-repl
julia> throw(CTBase.Exceptions.ExtensionError(:MyExtension, :AnotherDep; message="to use this feature"))
ERROR: ExtensionError. Please make: julia> using MyExtension, AnotherDep to use this feature
```

Enhanced version with full context:

```julia
throw(CTBase.Exceptions.ExtensionError(
    (:Plots, :PlotlyJS),
    message="to plot optimization results",
    feature="plotting functionality",
    context="solve! call"
))
```

# Common Use Cases
- Optional plotting functionality in optimization packages
- Specialized solvers that require additional packages
- Export/import features with format-specific dependencies
- Advanced algorithms that depend on external libraries

# See Also
- [`UnauthorizedCall`](@ref): Thrown when `ExtensionError()` is called without arguments
- [`set_show_full_stacktrace!`](@ref): Control stacktrace display
"""
struct ExtensionError <: CTException
    msg::String
    weakdeps::Tuple{Vararg{Symbol}}
    feature::Union{String,Nothing}
    context::Union{String,Nothing}
    function ExtensionError(weakdeps::Symbol...; message::String="", feature::Union{String,Nothing}=nothing, context::Union{String,Nothing}=nothing)
        isempty(weakdeps) && throw(
            UnauthorizedCall(
                "Please provide at least one weak dependence for the extension.",
                reason="ExtensionError called without dependencies"
            ),
        )
        msg = isempty(message) ? "missing dependencies" : "missing dependencies $(message)"
        return new(msg, weakdeps, feature, context)
    end
end
