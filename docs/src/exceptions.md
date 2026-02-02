# Error handling and CTBase exceptions

CTBase defines a small hierarchy of domain-specific exceptions to make error
handling explicit and consistent across the control-toolbox ecosystem.

All custom exceptions inherit from `CTBase.CTException`:

```julia
abstract type CTBase.CTException <: Exception end
```

You should generally catch exceptions like this:

```julia
try
    # call into CTBase or a package built on top of it
catch e
    if e isa CTBase.CTException
        # handle CTBase domain errors in a uniform way
        @warn "CTBase error" exception=(e, catch_backtrace())
    else
        # non-CTBase error: rethrow so it is not hidden
        rethrow()
    end
end
```

This pattern avoids accidentally swallowing unrelated internal errors while still
giving you a single place to handle all CTBase-specific problems.

## [AmbiguousDescription](@id ambiguous-description-tutorial)

```julia
CTBase.AmbiguousDescription <: CTBase.CTException
```

Thrown when a description (a tuple of `Symbol`s) cannot be matched to any known
valid description. This typically happens in `CTBase.complete` when the user
provides an incomplete or inconsistent description.

```julia-repl
julia> using CTBase

julia> D = ((:a, :b), (:a, :b, :c), (:b, :c))
julia> CTBase.complete(:f; descriptions=D)
ERROR: AmbiguousDescription: the description (:f,) is ambiguous / incorrect
```

Use this exception when *the high-level choice of description itself* is wrong
or ambiguous and there is no sensible default.

## [IncorrectArgument](@id incorrect-argument-tutorial)

```julia
CTBase.IncorrectArgument <: CTBase.CTException
```

Thrown when an individual argument is invalid or violates a precondition.

Examples from CTBase:

- Adding a duplicate description:

  ```julia-repl
  julia> algorithms = CTBase.add((), (:a, :b))
  julia> CTBase.add(algorithms, (:a, :b))
  ERROR: IncorrectArgument: the description (:a, :b) is already in ((:a, :b),)
  ```

- Using invalid indices for the Unicode helpers:

  ```julia-repl
  julia> CTBase.ctindice(-1)
  ERROR: IncorrectArgument: the subscript must be between 0 and 9
  ```

Use this exception whenever *one input value* is outside the allowed domain
(wrong range, duplicate, empty when it must not be, etc.).

## [NotImplemented](@id not-implemented-tutorial)

```julia
CTBase.NotImplemented <: CTBase.CTException
```

Used to mark interface points that must be implemented by concrete subtypes.
The typical pattern is to provide a method on an abstract type that throws
`NotImplemented`, and then override it in each concrete implementation:

```julia
abstract type MyAbstractAlgorithm end

function run!(algo::MyAbstractAlgorithm, state)
    throw(CTBase.NotImplemented("run! is not implemented for $(typeof(algo))"))
end
```

Concrete algorithms then provide their own `run!` method instead of raising
this exception. This makes it easy to detect missing implementations during
testing.

Use `NotImplemented` when defining *interfaces* and you want an explicit,
typed error rather than a generic `error("TODO")`.

## [UnauthorizedCall](@id unauthorized-call-tutorial)

```julia
CTBase.UnauthorizedCall <: CTBase.CTException
```

Signals that a function call is not allowed in the **current state** of the
object or system. This is different from `IncorrectArgument`: here the
arguments may be valid, but the call is forbidden because of *when* or *how*
it is made.

A common pattern is a method that is meant to be called only once:

```julia
function finalize!(s::SomeState)
    if s.is_finalized
        throw(CTBase.UnauthorizedCall("finalize! was already called for this state"))
    end
    # ... perform finalisation and mark state as finalised ...
end
```

Use `UnauthorizedCall` when the calling context is invalid (wrong phase of a
computation, method already called, state already closed, missing
permissions, illegal order of calls, etc.).

It is also used internally by `ExtensionError` when it is called without any
weak dependencies:

```julia-repl
julia> using CTBase

julia> CTBase.ExtensionError()
ERROR: UnauthorizedCall: Please provide at least one weak dependence for the extension.
```

## [ParsingError](@id parsing-error-tutorial)

```julia
CTBase.ParsingError <: CTBase.CTException
```

Intended for errors detected during parsing of input structures or DSLs
(domain-specific languages).

```julia-repl
julia> using CTBase

julia> throw(CTBase.ParsingError("unexpected token 'end'"))
ERROR: ParsingError: unexpected token 'end'
```
