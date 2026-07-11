# Interpolation

```@meta
CurrentModule = CTBase
```

The [`CTBase.Interpolation`](@ref) submodule provides lightweight, dependency-free
interpolation for one-dimensional data. Two methods are available:

- **Linear** interpolation with flat extrapolation outside the node range.
- **Piecewise-constant** (right-continuous *steppost*) interpolation.

Both produce a callable [`Interpolant`](@ref) — a `Function` subtype whose evaluation
rule is selected at compile time via a trait parameter.

## Linear interpolation

[`ctinterpolate`](@ref) builds a linear interpolant from nodes `x` and values `f`.
Outside `[x[1], x[end]]` the value is held flat (clamped to the nearest endpoint):

```@repl interp
using CTBase

x = [0.0, 1.0, 2.0, 3.0]
f = [0.0, 1.0, 0.0, -1.0]

interp = CTBase.Interpolation.ctinterpolate(x, f)

interp(0.5)   # linear between x[1] and x[2]
interp(2.5)   # linear between x[3] and x[4]
interp(-1.0)  # flat extrapolation → f[1]
interp(5.0)   # flat extrapolation → f[end]
```

## Piecewise-constant interpolation

[`ctinterpolate_constant`](@ref) builds a right-continuous steppost interpolant:
the value at node `x[i]` is held on `[x[i], x[i+1])`.

```@repl interp
const_interp = CTBase.Interpolation.ctinterpolate_constant(x, f)

const_interp(0.0)   # f[1]
const_interp(0.5)   # still f[1] (held on [0, 1))
const_interp(1.0)   # f[2] (right-continuous jump)
const_interp(1.5)   # still f[2]
```

This is the standard representation for piecewise-constant control functions in
optimal control.

## The Interpolant type

An [`Interpolant`](@ref) is parametrised by its method trait (`Linear` or `Constant`),
which makes the call type-stable:

```@repl interp
typeof(interp)
```

The method can be recovered with [`method`](@ref):

```@repl interp
CTBase.Interpolation.method(interp)
CTBase.Interpolation.method(const_interp)
```

## Display

```@repl interp
interp
const_interp
```

## Function Reference

| Function | Purpose |
| :--- | :--- |
| [`ctinterpolate`](@ref) | Linear interpolation with flat extrapolation |
| [`ctinterpolate_constant`](@ref) | Piecewise-constant (steppost) interpolation |
| [`method`](@ref) | Return the interpolation method trait of an `Interpolant` |

## See Also

- [Traits guide](traits.md) — the trait-parameter pattern used by `Interpolant`.
