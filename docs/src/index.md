# CTBase.jl — Ecosystem Foundation

```@meta
CurrentModule = CTBase
```

CTBase.jl is the foundational package of the [control-toolbox](https://github.com/control-toolbox) ecosystem.
It provides the **base layer** shared by all packages: common types, structured exceptions, description management, compile-time traits, trait-carrying data wrappers, extension infrastructure, and developer tools.

!!! note "Qualified access"
    CTBase exports **no symbols** at the package level. Every public symbol is accessed
    via its full qualified path, e.g. `CTBase.Exceptions.IncorrectArgument` or
    `CTBase.Descriptions.add`. This makes the origin of every symbol explicit at every
    call site and prevents namespace collisions between packages.

    Downstream packages (e.g. [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl))
    may re-export selected symbols for convenience.

!!! tip "[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/control-toolbox/CTBase.jl)"
    DeepWiki offers an interactive, AI-generated overview of this codebase. Answers may be inaccurate — use this
    reference documentation as the source of truth.

## Submodule overview

| Submodule | Role |
| :--- | :--- |
| [`CTBase.Core`](@ref) | Fundamental numeric type alias (`ctNumber`) and internal display helpers |
| [`CTBase.Exceptions`](@ref) | Typed exception hierarchy with rich context fields |
| [`CTBase.Traits`](@ref) | Compile-time trait types for time dependence, variable dependence, mutability, and dynamics dispatch |
| [`CTBase.Data`](@ref) | Trait-carrying function wrappers: `VectorField`, `Hamiltonian`, `HamiltonianVectorField` |
| [`CTBase.Descriptions`](@ref) | Symbolic description tuples: catalogue management, pattern completion, similarity search |
| [`CTBase.Options`](@ref) | Generic option handling: provenance tracking, schema definition, validation, and aliases |
| [`CTBase.Strategies`](@ref) | Strategy contract, registry, building/validation, and metadata for pluggable algorithmic components |
| [`CTBase.Orchestration`](@ref) | Option routing and disambiguation between problem-level actions and strategies |
| [`CTBase.Differentiation`](@ref) | AD-backend strategies for gradients, derivatives, partial derivatives, and Jacobian–vector products |
| [`CTBase.Interpolation`](@ref) | Linear and piecewise-constant interpolation with flat extrapolation |
| [`CTBase.DevTools`](@ref) | Developer tools with tag-based dispatch for `run_tests`, `postprocess_coverage`, and `automatic_reference_documentation` |
| [`CTBase.Unicode`](@ref) | Unicode subscript/superscript helpers for display |
| [`CTBase.Plotting`](@ref) | Backend-agnostic plotting IR: series, axes, layout tree, and render contract |

## User Guides

- **[Getting Started](getting-started.md)** — installation, mental model, 5-minute walkthrough.
- **[Exceptions](guide/exceptions.md)** — exception hierarchy, choosing the right type, best practices.
- **[Traits](guide/traits.md)** — compile-time trait types, the opt-in contract, and predicate functions.
- **[Data](guide/data.md)** — trait-carrying wrappers for vector fields and Hamiltonians.
- **[Descriptions](guide/descriptions.md)** — catalogue API, pattern matching, error handling.
- **[Options System](guide/options-system.md)** — option schema, validation, aliases, and provenance.
- **[Implementing a Strategy](guide/implementing-a-strategy.md)** — the strategy contract and how to add one.
- **[Strategy Parameters](guide/strategy-parameters.md)** — declaring and resolving strategy options.
- **[Orchestration & Routing](guide/orchestration-and-routing.md)** — routing options to strategies with disambiguation.
- **[Differentiation](guide/differentiation.md)** — AD-backend strategies and differentiation primitives (extension-backed).
- **[Test Runner](guide/test-runner.md)** — modular test infrastructure with `CTBase.DevTools.run_tests`.
- **[Coverage](guide/coverage.md)** — post-processing coverage artifacts with `CTBase.postprocess_coverage`.
- **[API Documentation](guide/api-documentation.md)** — auto-generating per-module API pages.
- **[Color System](guide/color-system.md)** — semantic color roles, built-in themes, and runtime customization.
- **[Interpolation](guide/interpolation.md)** — linear and piecewise-constant interpolation with flat extrapolation.
- **[Unicode Helpers](guide/unicode.md)** — subscript and superscript character generation for display.
- **[Plotting Engine](guide/plotting.md)** — backend-agnostic plotting IR, panels, combinators, and render contract.

To browse the complete API, see the **API Reference** section in the left sidebar.
