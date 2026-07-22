```@meta
CurrentModule = CTBase
Draft = false
```

# Performance & Type Stability

This guide explains **how CTBase keeps its runtime-critical code fast**, and how a
contributor can check that a change has not introduced a regression.

The whole approach rests on one distinction.

## The one principle: hot path vs. setup path

CTBase code falls into two categories:

- **Hot path** — code called *repeatedly* during a solve: evaluating a
  [`Data.VectorField`](@ref) or a [`Data.Hamiltonian`](@ref) at each integration
  step, reading a strategy option inside an inner loop, evaluating an
  [`Interpolation.Interpolant`](@ref) at many time points. This code **must be
  type-stable** — an instability here multiplies over thousands of calls.
- **Setup path** — code called *once per problem*, before the solve: building a
  strategy registry, constructing a strategy's options, resolving a strategy ID
  from a symbol. Here some runtime dispatch is **acceptable and by design** — the
  registry/options system is deliberately built for runtime extensibility, and the
  cost is paid once, not per iteration.

The rule of thumb for contributors: **keep the hot path inferable; do not worry
about a few dispatches in one-time construction code.** When in doubt, the tools
below tell you which side of the line you are on.

## The toolbox

| Tool | What it does | When to reach for it |
| --- | --- | --- |
| `@code_warntype f(args...)` | Colored dump of inferred types for one call; red marks instability. | First local look at a single function in the REPL. |
| `Cthulhu.@descend f(args...)` | Interactive, navigable version of the above; descend into callees. | Finding *where* deep in a call chain an instability originates. |
| `JET.@report_opt f(args...)` | Reports runtime-dispatch / optimization failures for one concrete call. | The at-a-glance stability check used on this page. |
| `JET.report_package(CTBase)` | Whole-package *correctness* scan (undefined names, method errors). | Catching latent bugs; runs automatically in the test suite (see below). |
| `Test.@inferred f(args...)` | Fails unless the call is type-stable. | Locking a fixed hot-path function against future regressions in a test. |

`JET` is a dev/test/docs dependency only — it is **not** a runtime dependency of
CTBase.

## Checking the hot path at a glance

[`JET.@report_opt`](https://aviatesk.github.io/JET.jl/stable/optanalysis/) inspects a
concrete call and prints `No errors detected` when the call is free of runtime
dispatch. The blocks below run **live at documentation build time**, so if a change
ever destabilises one of these hot-path entry points, this page's build surfaces it.

First, build the objects we will exercise:

```@example perf
using CTBase
using CTBase.Data, CTBase.Interpolation, CTBase.Differentiation
using JET

vf = VectorField(x -> -x)                       # autonomous, out-of-place
ham = Hamiltonian((x, p) -> sum(x .* p))        # H(x, p)
interp = ctinterpolate([0.0, 1.0, 2.0], [1.0, 2.0, 0.0])
backend = DifferentiationInterface()            # wraps AutoForwardDiff() (CPU default)
nothing # hide
```

**Evaluating a vector field** (the per-step ODE right-hand side):

```@example perf
JET.@report_opt vf([1.0, 2.0])
```

**Evaluating a Hamiltonian:**

```@example perf
JET.@report_opt ham([1.0, 2.0], [3.0, 4.0])
```

**Evaluating an interpolant** (called at many time points during a solve):

```@example perf
JET.@report_opt interp(0.5)
```

**Reading a strategy option** (the per-iteration option lookup, distinct from the
one-time *construction* of the options):

```@example perf
JET.@report_opt ad_backend(backend)
```

All four report `No errors detected`: the repeated-call path is stable.

## What is enforced automatically

The whole-package correctness scan runs as part of the test suite, so a
correctness-level regression fails CI:

```julia
# test/suite/meta/test_code_quality.jl
JET.test_package(CTBase; target_modules=(CTBase,))
```

To run the same scan interactively on a fresh checkout:

```julia
using CTBase, JET
JET.report_package(CTBase; target_modules=(CTBase,))
```

Note that `report_package` is a **correctness** analysis (undefined bindings,
method errors), not a type-stability one — for stability, use `@report_opt` on a
concrete call as shown above.

## Known, acceptable dynamism

Running `@report_opt` on some *construction* entry points does report runtime
dispatch. This is expected and does not indicate a regression:

- **Strategy / options construction** (`Strategies.create_registry`,
  `Strategies.build_strategy_options`, `Options.extract_options`) uses
  `Vector`/`Dict` storage with abstract element types so that strategies and
  options can be registered at runtime. The dispatch is confined to this setup
  code and is paid once per problem, before any solve.
- **`VectorField` / `HamiltonianVectorField` mutability auto-detection.** When the
  constructor is called without an explicit `is_inplace`, it inspects the
  function's signature via `methods(f)` to decide between in-place and
  out-of-place. `methods` is inherently non-inferable, so the *construction* call
  shows dispatch:

  ```julia
  using CTBase.Data, JET
  JET.@report_opt VectorField(x -> -x)   # reports dispatch — expected
  ```

  You can bypass the reflection (and the dispatch) by passing the trait explicitly:

  ```julia
  VectorField(x -> -x; is_inplace = false)
  ```

  Either way the resulting object's *call* is fully type-stable, as shown in the
  section above — the dynamism never reaches the hot path.

## Investigating a regression

If a hot-path check above starts reporting dispatch, drill in locally:

```julia
using CTBase.Data
vf = VectorField(x -> -x)

# 1. Quick look
using InteractiveUtils
@code_warntype vf([1.0, 2.0])

# 2. Navigate the call chain to the root cause
using Cthulhu
@descend vf([1.0, 2.0])
```

Once fixed, lock the result with a stability test so it cannot silently regress:

```julia
using Test
@inferred vf([1.0, 2.0])
```

## See Also

- [Test Runner Guide](test-runner.md): running the test suite, including the
  automatic `JET.test_package` check.
- [Coverage Post-processing Guide](coverage.md): the complementary "is this code
  exercised at all?" question.
