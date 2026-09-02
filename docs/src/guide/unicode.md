# [Unicode Helpers](@id guide-unicode)

```@meta
CurrentModule = CTBase
```

The [`CTBase.Unicode`](@ref) submodule provides functions for converting integers
to Unicode subscript and superscript characters. These are useful for generating
mathematical notation in display code (e.g. variable names like `x₁`, `p²`).

## Subscripts

[`CTBase.Unicode.ctindice`](@ref) returns a single subscript digit (0–9) as a `Char`:

```@repl uni
using CTBase

CTBase.Unicode.ctindice(3)
```

[`CTBase.Unicode.ctindices`](@ref) converts a multi-digit non-negative integer to a `String` of
subscript characters:

```@repl uni
CTBase.Unicode.ctindices(123)
```

## Superscripts

[`CTBase.Unicode.ctupperscript`](@ref) returns a single superscript digit (0–9) as a `Char`:

```@repl uni
CTBase.Unicode.ctupperscript(2)
```

[`CTBase.Unicode.ctupperscripts`](@ref) converts a multi-digit non-negative integer to a `String`
of superscript characters:

```@repl uni
CTBase.Unicode.ctupperscripts(123)
```

## Error Handling

Passing a negative integer or a value outside 0–9 to the single-digit functions
raises [`CTBase.Exceptions.IncorrectArgument`](@ref):

```@repl uni
CTBase.Unicode.ctindice(12)
```

## Function Reference

| Function | Returns | Range |
| :--- | :--- | :--- |
| [`CTBase.Unicode.ctindice`](@ref) | `Char` (single subscript digit) | 0–9 |
| [`CTBase.Unicode.ctindices`](@ref) | `String` (multi-digit subscripts) | ≥ 0 |
| [`CTBase.Unicode.ctupperscript`](@ref) | `Char` (single superscript digit) | 0–9 |
| [`CTBase.Unicode.ctupperscripts`](@ref) | `String` (multi-digit superscripts) | ≥ 0 |

## See Also

- [Exceptions guide](@ref guide-exceptions) — understanding `IncorrectArgument`.
