```@meta
CurrentModule = CTBase
```

# Getting Started

## Installation

CTBase.jl is typically installed as a dependency of another package in the ecosystem
(e.g. [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl)).
To install it directly:

```julia
import Pkg
Pkg.add("CTBase")
```

**Requires Julia ≥ 1.10.**

## Mental Model

CTBase is the **base layer** of the control-toolbox ecosystem.
It provides infrastructure shared by every package above it.

Three things to keep in mind:

1. **No top-level exports.** `using CTBase` loads the package but brings no symbols
   into scope. Every symbol is accessed via its qualified path:
   ```julia
   CTBase.Descriptions.add # ✓ always works
   CTBase.Exceptions.NotImplemented
   ```
2. **Submodule-first API.** The public API lives in named submodules
   (`Core`, `Descriptions`, `Exceptions`, `Traits`, `DevTools`, `Unicode`, …).
   You can bring a submodule's exports into scope explicitly:
   ```julia
   using CTBase.Exceptions # brings IncorrectArgument, NotImplemented, … into scope
   using CTBase.Traits     # brings Autonomous, NonAutonomous, is_autonomous, … into scope
   ```
3. **Extension-backed features.** `run_tests`, `postprocess_coverage`, and
   `automatic_reference_documentation` require loading the matching weak dependency
   (`Test`, `Coverage`, `Documenter` respectively) before they become active.

## 5-Minute Walkthrough

### Working with Descriptions

A *description* is a `Tuple` of `Symbol`s that declaratively identifies an algorithm
or configuration. Catalogues collect known descriptions; `complete` resolves a partial
description to an exact one.

```@repl walkthrough
using CTBase

# Build a catalogue
descs = CTBase.Descriptions.add((), (:euler, :explicit))
descs = CTBase.Descriptions.add(descs, (:euler, :implicit))
descs = CTBase.Descriptions.add(descs, (:runge_kutta, :explicit))

# Partial completion: find the unique entry containing :implicit
CTBase.Descriptions.complete(:implicit; descriptions=descs)

# :euler matches two entries; priority (first in catalog) resolves the tie
CTBase.Descriptions.complete(:euler; descriptions=descs)

# No entry contains both :runge_kutta and :implicit → raises AmbiguousDescription
try # hide
CTBase.Descriptions.complete(:runge_kutta, :implicit; descriptions=descs)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

For more, see the **[Descriptions guide](guide/descriptions.md)**.

### Working with Exceptions

CTBase defines a typed exception hierarchy rooted at
[`CTBase.Exceptions.CTException`](@ref).
Each type carries structured context fields for actionable error messages.

```@repl walkthrough
# IncorrectArgument — invalid input value
try # hide
throw(CTBase.Exceptions.IncorrectArgument(
    "state dimension must be positive";
    got="0",
    expected="n > 0",
    suggestion="Pass a positive integer for the state dimension",
))
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide

# NotImplemented — interface stub
try # hide
throw(CTBase.Exceptions.NotImplemented(
    "solve! is not implemented";
    required_method="solve!(::MyStrategy, ocp)",
    suggestion="Import the package that provides this strategy",
))
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

For more, see the **[Exceptions guide](guide/exceptions.md)**.

## Next Steps

| Topic | Guide |
| :--- | :--- |
| Descriptions catalogue and completion | [Descriptions](guide/descriptions.md) |
| Exception hierarchy and best practices | [Exceptions](guide/exceptions.md) |
| Compile-time traits and dispatch | [Traits](guide/traits.md) |
| Modular test runner setup | [Test Runner](guide/test-runner.md) |
| Coverage report generation | [Coverage](guide/coverage.md) |
| Auto-generated API reference | [API Documentation](guide/api-documentation.md) |
| Full API reference | API Reference (left sidebar) |
