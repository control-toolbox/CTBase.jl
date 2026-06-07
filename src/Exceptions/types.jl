# Exception type definitions for CTBase
# Based on CTBase.jl but with enriched error handling

"""
$(TYPEDEF)

Abstract supertype for all CTBase exceptions.

All exceptions in the CTBase ecosystem inherit from this type, enabling
uniform error handling via a single `catch` clause.

# Example

```julia-repl
julia> using CTBase

julia> try
           throw(CTBase.Exceptions.IncorrectArgument("invalid input"))
       catch e
           e isa CTBase.Exceptions.CTException || rethrow()
           println("Caught: ", e)
       end
Caught: IncorrectArgument: invalid input
```

See also: [`CTBase.Exceptions.IncorrectArgument`](@ref), [`CTBase.Exceptions.NotImplemented`](@ref)
"""
abstract type CTException <: Exception end

"""
$(TYPEDEF)

Exception thrown when an individual argument is invalid or violates a constraint.

Use when the problem is with the **input data itself** (wrong range, duplicate,
empty collection, type mismatch) rather than the calling context or system state.

# Fields
- `msg::String`: Main error message describing the problem.
- `got::Union{String, Nothing}`: The invalid value received (optional).
- `expected::Union{String, Nothing}`: What was expected (optional).
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional).
- `context::Union{String, Nothing}`: Where the error occurred (optional).

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.IncorrectArgument("the argument must be a non-empty tuple"))
ERROR: IncorrectArgument: the argument must be a non-empty tuple
```

With optional fields:

```julia
throw(CTBase.Exceptions.IncorrectArgument(
    "Dimension mismatch",
    got="vector of length 3",
    expected="vector of length 2",
    suggestion="Provide a vector matching the state dimension",
    context="initial_guess for state",
))
```

See also: [`CTBase.Exceptions.AmbiguousDescription`](@ref), [`CTBase.Exceptions.PreconditionError`](@ref)
"""
struct IncorrectArgument <: CTException
    msg::String
    got::Union{String,Nothing}
    expected::Union{String,Nothing}
    suggestion::Union{String,Nothing}
    context::Union{String,Nothing}

    # Constructor for enriched exceptions
    function IncorrectArgument(
        msg::String;
        got::Union{String,Nothing}=nothing,
        expected::Union{String,Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
        context::Union{String,Nothing}=nothing,
    )
        return new(msg, got, expected, suggestion, context)
    end
end

"""
$(TYPEDEF)

Exception thrown when a function call violates a precondition or is not allowed in the
current state of the system.

Use when the **arguments are valid** but the call is forbidden because of when or how it
is made (e.g., calling a method twice, missing a required prior setup step).
Distinct from [`CTBase.Exceptions.IncorrectArgument`](@ref), which signals a problem
with the input values themselves.

# Fields
- `msg::String`: Main error message.
- `reason::Union{String, Nothing}`: Why the precondition failed (optional).
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional).
- `context::Union{String, Nothing}`: Where the error occurred (optional).

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.PreconditionError("state must be set before dynamics"))
ERROR: PreconditionError: state must be set before dynamics
```

With optional fields:

```julia
throw(CTBase.Exceptions.PreconditionError(
    "Cannot call state! twice",
    reason="state has already been defined for this OCP",
    suggestion="Create a new OCP instance",
    context="state definition",
))
```

See also: [`CTBase.Exceptions.IncorrectArgument`](@ref), [`CTBase.Exceptions.NotImplemented`](@ref)
"""
struct PreconditionError <: CTException
    msg::String
    reason::Union{String,Nothing}
    suggestion::Union{String,Nothing}
    context::Union{String,Nothing}

    function PreconditionError(
        msg::String;
        reason::Union{String,Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
        context::Union{String,Nothing}=nothing,
    )
        return new(msg, reason, suggestion, context)
    end
end

"""
$(TYPEDEF)

Exception thrown to mark interface points that must be implemented by concrete subtypes.

Use when a default method on an abstract type should explicitly signal that a concrete
subtype has not provided the required implementation. Prefer this over a generic
`error("not implemented")` to give users a typed, catchable error.

# Fields
- `msg::String`: Description of what is not implemented.
- `required_method::Union{String, Nothing}`: The missing method signature (optional).
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional).
- `context::Union{String, Nothing}`: Where the error occurred (optional).

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.NotImplemented("feature X is not implemented"))
ERROR: NotImplemented: feature X is not implemented
```

Typical interface stub pattern:

```julia
abstract type MyAbstractAlgorithm end

function run!(algo::MyAbstractAlgorithm, state)
    throw(CTBase.Exceptions.NotImplemented(
        "run! is not implemented for \$(typeof(algo))",
        required_method="run!(::MyAbstractAlgorithm, state)",
        suggestion="Implement run! for your concrete algorithm type",
        context="algorithm execution",
    ))
end
```

See also: [`CTBase.Exceptions.IncorrectArgument`](@ref), [`CTBase.Exceptions.PreconditionError`](@ref)
"""
struct NotImplemented <: CTException
    msg::String
    required_method::Union{String,Nothing}
    suggestion::Union{String,Nothing}
    context::Union{String,Nothing}

    function NotImplemented(
        msg::String;
        required_method::Union{String,Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
        context::Union{String,Nothing}=nothing,
    )
        return new(msg, required_method, suggestion, context)
    end
end

"""
$(TYPEDEF)

Exception thrown during parsing when a syntax error or invalid structure is detected.

Use when the **structure or syntax** of the input is invalid (e.g., DSL grammar
violation). For semantic errors on a valid-syntax input, prefer
[`CTBase.Exceptions.IncorrectArgument`](@ref) instead.

# Fields
- `msg::String`: Description of the parsing error.
- `location::Union{String, Nothing}`: Where in the input the error occurred (optional).
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional).

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.ParsingError("unexpected token 'end'"))
ERROR: ParsingError: unexpected token 'end'
```

With optional fields:

```julia
throw(CTBase.Exceptions.ParsingError(
    "Unexpected token 'end'",
    location="line 42, column 15",
    suggestion="Check syntax balance or remove extra 'end'",
))
```

See also: [`CTBase.Exceptions.IncorrectArgument`](@ref), [`CTBase.Exceptions.AmbiguousDescription`](@ref)
"""
struct ParsingError <: CTException
    msg::String
    location::Union{String,Nothing}
    suggestion::Union{String,Nothing}

    function ParsingError(
        msg::String;
        location::Union{String,Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
    )
        return new(msg, location, suggestion)
    end
end

"""
$(TYPEDEF)

Exception thrown when a description (a tuple of `Symbol`s) cannot be matched to any
known valid description in a catalogue.

Raised by [`CTBase.Descriptions.complete`](@ref) when the partial description provided
by the user is not a subset of any catalogue entry.

# Fields
- `msg::String`: Main error message.
- `description::Tuple{Vararg{Symbol}}`: The ambiguous or unrecognised description tuple.
- `candidates::Union{Vector{String}, Nothing}`: Suggested valid descriptions (optional).
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional).
- `context::Union{String, Nothing}`: Where the error occurred (optional).
- `diagnostic::Union{String, Nothing}`: Diagnostic tag, e.g. `"unknown symbols"` (optional).

# Example

```julia-repl
julia> using CTBase

julia> D = ((:a, :b), (:a, :b, :c), (:b, :c))
julia> CTBase.complete(:f; descriptions=D)
ERROR: AmbiguousDescription: the description (:f,) is ambiguous / incorrect
```

With optional fields:

```julia
throw(CTBase.Exceptions.AmbiguousDescription(
    (:f,),
    candidates=["(:descent, :bfgs, :bisection)", "(:descent, :gradient, :fixedstep)"],
    suggestion="Use a complete description like (:descent, :bfgs, :bisection)",
    context="algorithm selection",
))
```

See also: [`CTBase.Descriptions.complete`](@ref), [`CTBase.Descriptions.add`](@ref), [`CTBase.Exceptions.IncorrectArgument`](@ref)
"""
struct AmbiguousDescription <: CTException
    msg::String
    description::Tuple{Vararg{Symbol}}
    candidates::Union{Vector{String},Nothing}
    suggestion::Union{String,Nothing}
    context::Union{String,Nothing}
    diagnostic::Union{String,Nothing}

    function AmbiguousDescription(
        description::Tuple{Vararg{Symbol}};
        msg::String="cannot find matching description",
        candidates::Union{Vector{String},Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
        context::Union{String,Nothing}=nothing,
        diagnostic::Union{String,Nothing}=nothing,
    )
        return new(msg, description, candidates, suggestion, context, diagnostic)
    end
end

"""
$(TYPEDEF)

Exception thrown when an optional dependency (weak dependency) is required by a feature
but has not been loaded.

Calling the zero-argument constructor `ExtensionError()` is forbidden and throws a
[`CTBase.Exceptions.PreconditionError`](@ref) instead — at least one dependency symbol
must be supplied.

# Fields
- `msg::String`: Auto-generated error message listing the missing packages.
- `weakdeps::Tuple{Vararg{Symbol}}`: The missing dependency symbols.
- `feature::Union{String, Nothing}`: The functionality that requires these dependencies (optional).
- `context::Union{String, Nothing}`: Where the error occurred (optional).

# Throws
- [`CTBase.Exceptions.PreconditionError`](@ref): If called with no arguments.

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.ExtensionError(:MyExtension))
ERROR: ExtensionError. Please make: julia> using MyExtension
```

With multiple dependencies:

```julia-repl
julia> throw(CTBase.Exceptions.ExtensionError(:MyExtension, :AnotherDep; message="to use this feature"))
ERROR: ExtensionError. Please make: julia> using MyExtension, AnotherDep to use this feature
```

With full context:

```julia
throw(CTBase.Exceptions.ExtensionError(
    :Plots;
    message="to plot optimization results",
    feature="plotting functionality",
    context="solve! call",
))
```

See also: [`CTBase.Exceptions.PreconditionError`](@ref)
"""
struct ExtensionError <: CTException
    msg::String
    weakdeps::Tuple{Vararg{Symbol}}
    feature::Union{String,Nothing}
    context::Union{String,Nothing}
    function ExtensionError(
        weakdeps::Symbol...;
        message::String="",
        feature::Union{String,Nothing}=nothing,
        context::Union{String,Nothing}=nothing,
    )
        isempty(weakdeps) && throw(
            PreconditionError(
                "Please provide at least one weak dependence for the extension.";
                reason="ExtensionError called without dependencies",
            ),
        )
        msg = isempty(message) ? "missing dependencies" : "missing dependencies $(message)"
        return new(msg, weakdeps, feature, context)
    end
end

"""
$(TYPEDEF)

Exception thrown when a numerical solver (ODE integrator, NLP solver, linear solver, etc.)
fails to complete successfully.

Use this when the **numerical computation itself** fails, not when the input is invalid
([`CTBase.Exceptions.IncorrectArgument`](@ref)) or a precondition is violated
([`CTBase.Exceptions.PreconditionError`](@ref)).

# Fields
- `msg::String`: Main error message describing the failure.
- `retcode::Union{String, Nothing}`: Solver-specific return code, e.g. `":Unstable"` (optional).
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional).
- `context::Union{String, Nothing}`: Where the error occurred (optional).

# Example

```julia-repl
julia> using CTBase

julia> throw(CTBase.Exceptions.SolverFailure("ODE integration failed", retcode=":Unstable"))
ERROR: SolverFailure: ODE integration failed
```

With full context:

```julia
throw(CTBase.Exceptions.SolverFailure(
    "Optimization solver did not converge",
    retcode=":MaxIterations",
    suggestion="Increase max iterations or adjust tolerance settings",
    context="IPOPT solver in CTDirect",
))
```

See also: [`CTBase.Exceptions.IncorrectArgument`](@ref), [`CTBase.Exceptions.PreconditionError`](@ref)
"""
struct SolverFailure <: CTException
    msg::String
    retcode::Union{String,Nothing}
    suggestion::Union{String,Nothing}
    context::Union{String,Nothing}

    function SolverFailure(
        msg::String;
        retcode::Union{String,Nothing}=nothing,
        suggestion::Union{String,Nothing}=nothing,
        context::Union{String,Nothing}=nothing,
    )
        return new(msg, retcode, suggestion, context)
    end
end
