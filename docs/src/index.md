# CTBase.jl — Ecosystem Foundation

!!! tip "Ask DeepWiki"
    [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/control-toolbox/CTBase.jl) offers an interactive, AI-generated overview of this codebase. Answers may be inaccurate — use this
    reference documentation as the source of truth.

```@meta
CurrentModule = CTBase
```

CTBase.jl is the foundational package of the [control-toolbox](https://github.com/control-toolbox) ecosystem.
It provides the **base layer** shared by all packages: common types, structured exceptions, description management, extension infrastructure, and developer tools.

!!! note "Qualified access"
    CTBase exports **no symbols** at the package level. Every public symbol is accessed
    via its full qualified path, e.g. `CTBase.Exceptions.IncorrectArgument` or
    `CTBase.Descriptions.add`. This makes the origin of every symbol explicit at every
    call site and prevents namespace collisions between packages.

    Downstream packages (e.g. [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl))
    may re-export selected symbols for convenience.

## Submodule overview

| Submodule | Role |
|:---|:---|
| [`CTBase.Core`](@ref) | Fundamental numeric type alias (`ctNumber`) and internal display helpers |
| [`CTBase.Descriptions`](@ref) | Symbolic description tuples: catalogue management, pattern completion, similarity search |
| [`CTBase.Exceptions`](@ref) | Typed exception hierarchy with rich context fields |
| [`CTBase.Extensions`](@ref) | Tag-based extension dispatch for `run_tests`, `postprocess_coverage`, and `automatic_reference_documentation` |
| [`CTBase.Unicode`](@ref) | Unicode subscript/superscript helpers for display |

## Quick Start

```@repl
using CTBase

# --- Descriptions ---
descs = CTBase.Descriptions.add((), (:euler, :explicit))
descs = CTBase.Descriptions.add(descs, (:euler, :implicit))
CTBase.Descriptions.complete(:euler, :explicit; descriptions=descs)

# --- Exceptions ---
try
    throw(CTBase.Exceptions.IncorrectArgument("n must be positive"; got="-1"))
catch e
    println(e)
end
```

## User Guides

- **[Getting Started](getting-started.md)** — installation, mental model, 5-minute walkthrough.
- **[Descriptions](guide/descriptions.md)** — catalogue API, pattern matching, error handling.
- **[Exceptions](guide/exceptions.md)** — exception hierarchy, choosing the right type, best practices.
- **[Test Runner](guide/test-runner.md)** — modular test infrastructure with `CTBase.Extensions.run_tests`.
- **[Coverage](guide/coverage.md)** — post-processing coverage artifacts with `CTBase.postprocess_coverage`.
- **[API Documentation](guide/api-documentation.md)** — auto-generating per-module API pages.

To browse the complete API, see the **API Reference** section in the left sidebar.
