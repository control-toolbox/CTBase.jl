# Descriptions: encoding algorithms

One of the central ideas in `CTBase.jl` is the notion of a **description**.
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

## Building a library of descriptions

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

## Function Reference

| Function | Purpose | Returns | Throws |
|----------|---------|---------|--------|
| `add(x, y)` | Add description `y` to collection `x` | Updated tuple | `IncorrectArgument` if duplicate |
| `complete(list; descriptions=D)` | Find complete description matching partial list | Complete description | `AmbiguousDescription` if no match |
| `remove(x, y)` | Remove symbols in `y` from description `x` | Remaining symbols | - |

## Error Handling

The description system uses CTBase exceptions to signal problems:

### Duplicate Descriptions

```@repl
using CTBase
algorithms = CTBase.add((), (:a, :b))
CTBase.add(algorithms, (:a, :b))  # Error: duplicate
```

This throws `IncorrectArgument` because adding a duplicate would create ambiguity.

### Ambiguous or Invalid Descriptions

```@repl
using CTBase
D = ((:a, :b), (:c, :d))
CTBase.complete((:x,); descriptions=D)  # Error: no match
```

This throws `AmbiguousDescription` when no description in the library contains all the requested symbols.

## Best Practices

1. **Order matters**: Place more specific descriptions first in your library
2. **Use meaningful symbols**: Choose symbols that clearly describe the algorithm
3. **Keep it simple**: Descriptions should be short and focused
4. **Handle errors**: Always catch `AmbiguousDescription` when using `complete`
5. **Document your descriptions**: Maintain a list of valid descriptions for your package

## See Also

- [Exception Handling](exceptions.md): Understanding CTBase exceptions
