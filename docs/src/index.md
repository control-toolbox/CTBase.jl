# CTBase.jl

```@meta
CurrentModule = CTBase
```

The `CTBase.jl` package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

!!! note

    The root package is [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) which aims to provide tools to model and solve optimal control problems with ordinary differential equations by direct and indirect methods, both on CPU and GPU.

!!! warning

    In some examples in the documentation, private methods are shown without the module
    prefix. This is done for the sake of clarity and readability.

    ```julia-repl
    julia> using CTBase
    julia> x = 1
    julia> private_fun(x) # throws an error
    ```

    This should instead be written as:

    ```julia-repl
    julia> using CTBase
    julia> x = 1
    julia> CTBase.private_fun(x)
    ```

    If the method is re-exported by another package, 
    
    ```julia
    module OptimalControl
        import CTBase: private_fun
        export private_fun
    end
    ```
    
    then there is no need to prefix it with the original module name:

    ```julia-repl
    julia> using OptimalControl
    julia> x = 1
    julia> private_fun(x)
    ```

## Descriptions: encoding algorithms

One of the central ideas in CTBase is the notion of a **description**.
A description is simply a tuple of `Symbol`s that encodes an algorithm or
configuration in a declarative way.

Formally, CTBase defines:

```julia
const DescVarArg = Vararg{Symbol}
const Description = Tuple{DescVarArg}
```

For example, the tuple

```julia-repl
julia> using CTBase

julia> d = (:descent, :bfgs, :bisection)
(:descent, :bfgs, :bisection)

julia> typeof(d) <: CTBase.Description
true
```

can be read as “a descent algorithm, with BFGS directions and a bisection
line search”. Higher-level packages in the control-toolbox ecosystem use
descriptions to catalogue algorithms in a uniform way.

### Building a library of descriptions

CTBase provides a few small functions to manage collections of descriptions:

- `CTBase.add(x, y)` adds the description `y` to the tuple of descriptions `x`,
  rejecting duplicates with an `IncorrectArgument` exception.
- `CTBase.complete(list; descriptions=D)` picks a complete description from a
  set `D` based on a partial list of symbols.
- `CTBase.remove(x, y)` returns the set difference of two descriptions.

Here is a complete example of a small “algorithm library”:

```julia-repl
julia> algorithms = ()
()

julia> algorithms = CTBase.add(algorithms, (:descent, :bfgs, :bisection))
((:descent, :bfgs, :bisection),)

julia> algorithms = CTBase.add(algorithms, (:descent, :gradient, :fixedstep))
((:descent, :bfgs, :bisection), (:descent, :gradient, :fixedstep))

julia> display(algorithms)
(:descent, :bfgs, :bisection)
(:descent, :gradient, :fixedstep)
```

Given this library, we can **complete** a partial description:

```julia-repl
julia> CTBase.complete((:descent,); descriptions=algorithms)
(:descent, :bfgs, :bisection)

julia> CTBase.complete((:gradient, :fixedstep); descriptions=algorithms)
(:descent, :gradient, :fixedstep)
```

Internally, `CTBase.complete` scans the `descriptions` tuple from top to
bottom. For each candidate description it computes:

- how many symbols it shares with the partial list, and
- whether the partial list is a subset of the full description.

If no description contains all the symbols from the partial list,
`AmbiguousDescription` is thrown. Otherwise, among the descriptions that do
contain the partial list, CTBase selects the one with the largest
intersection; if several have the same score, the **first** one in the
`descriptions` tuple wins. In other words, the order of `descriptions`
encodes a priority from top to bottom.

With this mechanism in place, we can then analyse the *remainder* of a
description by removing a prefix:

```julia-repl
julia> full = CTBase.complete((:descent,); descriptions=algorithms)
(:descent, :bfgs, :bisection)

julia> CTBase.remove(full, (:descent, :bfgs))
(:bisection,)
```

This “description language” lets higher-level packages refer to algorithms in a
structured, composable way, while CTBase takes care of the low-level
operations (adding, completing, and comparing descriptions).

## Error handling and CTBase exceptions

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

### `AmbiguousDescription`

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

### `IncorrectArgument`

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

### `NotImplemented`

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

### `UnauthorizedCall`

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

### `ParsingError`

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
