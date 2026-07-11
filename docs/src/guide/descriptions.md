# Descriptions: encoding algorithms

```@meta
CurrentModule = CTBase
```

A *description* is a [`CTBase.Descriptions.Description`](@ref) — a `Tuple` of `Symbol`s
that declaratively encodes an algorithm or configuration.

```@repl desc
using CTBase

d = (:descent, :bfgs, :bisection)
typeof(d) <: CTBase.Descriptions.Description
```

Higher-level packages use descriptions to catalogue algorithms in a uniform,
string-free, and composable way.

## Building a catalogue

[`CTBase.Descriptions.add`](@ref) adds a description to a catalogue (a
`Tuple{Vararg{Description}}`). Start with an empty tuple `()`:

```@repl desc
algorithms = ()
algorithms = CTBase.Descriptions.add(
    algorithms, (:descent, :bfgs, :bisection),
)
algorithms = CTBase.Descriptions.add(
    algorithms, (:descent, :gradient, :fixedstep),
)
```

Attempting to add a duplicate raises [`CTBase.Exceptions.IncorrectArgument`](@ref):

```@repl desc
try # hide
CTBase.Descriptions.add(
    algorithms, (:descent, :bfgs, :bisection),
)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Completing a partial description

[`CTBase.Descriptions.complete`](@ref) picks the unique catalogue entry that contains
all provided symbols:

```@repl desc
CTBase.Descriptions.complete(
    :bisection; descriptions=algorithms,
)
CTBase.Descriptions.complete(
    :gradient, :fixedstep; descriptions=algorithms,
)
```

Among all entries that are a superset of the requested symbols, the one with the
largest overlap is returned (first wins on tie). If no entry matches,
[`CTBase.Exceptions.AmbiguousDescription`](@ref) is raised:

```@repl desc
try # hide
CTBase.Descriptions.complete(
    :euler; descriptions=algorithms,
)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Removing symbols from a description

[`CTBase.Descriptions.remove`](@ref) returns a new description with specified symbols
removed — useful for extracting the remainder after stripping a known prefix:

```@repl desc
full = CTBase.Descriptions.complete(
    :bisection; descriptions=algorithms,
)
CTBase.Descriptions.remove(full, (:descent, :bfgs))
```

## Function Reference

| Function | Purpose | Throws |
| :--- | :--- | :--- |
| [`CTBase.Descriptions.add`](@ref) | Add a description to a catalogue | [`IncorrectArgument`](@ref CTBase.Exceptions.IncorrectArgument) on duplicate |
| [`CTBase.Descriptions.complete`](@ref) | Complete a partial description | [`AmbiguousDescription`](@ref CTBase.Exceptions.AmbiguousDescription) on no match |
| [`CTBase.Descriptions.remove`](@ref) | Remove symbols from a description | — |

## See Also

- [Exceptions guide](exceptions.md) — understanding `IncorrectArgument` and `AmbiguousDescription`.
