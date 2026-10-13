# [Orchestration and Routing](@id guide-orchestration-and-routing)

```@meta
CurrentModule = CTBase
```

This guide explains how the Orchestration module routes user-provided keyword arguments to the correct strategy in a multi-strategy pipeline. It covers the method tuple concept, automatic routing, disambiguation syntax, and the helper functions that power the system.

!!! tip "Prerequisites"
    Read [Implementing a Strategy](@ref guide-implementing-a-strategy) first. Orchestration builds on top of the strategy metadata system.

```@setup routing
using CTBase: CTBase
using CTBase: Options
using CTBase: Strategies
using CTBase: Orchestration
```

We define three fake strategies — a discretizer, a modeler, and a solver — with a shared `backend` option to demonstrate routing and disambiguation:

```@example routing
# --- Fake discretizer family ---
abstract type AbstractFakeDiscretizer <:
    CTBase.Strategies.AbstractStrategy end

struct FakeCollocation <: AbstractFakeDiscretizer
    options::CTBase.Strategies.StrategyOptions
end

CTBase.Strategies.id(::Type{<:FakeCollocation}) = :collocation
CTBase.Strategies.parameter(::Type{<:FakeCollocation}) = nothing

CTBase.Strategies.metadata(::Type{<:FakeCollocation}) =
    CTBase.Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name = :grid_size, type = Int,
            default = 100, description = "Grid size",
        ),
    )

FakeCollocation(; kwargs...) = FakeCollocation(
    CTBase.Strategies.build_strategy_options(
        FakeCollocation; kwargs...,
    ),
)

# --- Fake modeler family ---
abstract type AbstractFakeModeler <:
    CTBase.Strategies.AbstractStrategy end

struct FakeADNLP <: AbstractFakeModeler
    options::CTBase.Strategies.StrategyOptions
end

CTBase.Strategies.id(::Type{<:FakeADNLP}) = :adnlp
CTBase.Strategies.parameter(::Type{<:FakeADNLP}) = nothing

CTBase.Strategies.metadata(::Type{<:FakeADNLP}) =
    CTBase.Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name = :backend, type = Symbol,
            default = :default, description = "AD backend",
        ),
    )

FakeADNLP(; kwargs...) = FakeADNLP(
    CTBase.Strategies.build_strategy_options(
        FakeADNLP; kwargs...,
    ),
)

# --- Fake solver family ---
abstract type AbstractFakeSolver <:
    CTBase.Strategies.AbstractStrategy end

struct FakeIpopt <: AbstractFakeSolver
    options::CTBase.Strategies.StrategyOptions
end

CTBase.Strategies.id(::Type{<:FakeIpopt}) = :ipopt
CTBase.Strategies.parameter(::Type{<:FakeIpopt}) = nothing

CTBase.Strategies.metadata(::Type{<:FakeIpopt}) =
    CTBase.Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name = :max_iter, type = Integer,
            default = 1000, description = "Max iterations",
        ),
        Options.OptionDefinition(
            name = :backend, type = Symbol,
            default = :cpu, description = "Compute backend",
        ),
    )

FakeIpopt(; kwargs...) = FakeIpopt(
    CTBase.Strategies.build_strategy_options(
        FakeIpopt; kwargs...,
    ),
)

# --- Registry ---
registry = CTBase.Strategies.create_registry(
    AbstractFakeDiscretizer => (FakeCollocation,),
    AbstractFakeModeler     => (FakeADNLP,),
    AbstractFakeSolver      => (FakeIpopt,),
)
```

## The Method Tuple Concept

A **method tuple** identifies which concrete strategy to use for each role in the pipeline:

```@example routing
method = (:collocation, :adnlp, :ipopt)
nothing # hide
```

Each symbol is a strategy `id` (returned by `Strategies.id(::Type)`). The **families** mapping associates each role with its abstract type:

```@example routing
families = (
    discretizer = AbstractFakeDiscretizer,
    modeler     = AbstractFakeModeler,
    solver      = AbstractFakeSolver,
)
nothing # hide
```

The orchestration system uses the `StrategyRegistry` to resolve each symbol to its concrete type and access its metadata.

## Automatic Routing

When a user passes keyword arguments, `route_all_options` automatically routes each option to the strategy that owns it:

```julia
solve(ocp, :collocation, :adnlp, :ipopt;
    grid_size = 100,    # only discretizer defines this → auto-route
    max_iter  = 1000,   # only solver defines this → auto-route
    display   = true,   # action option → extracted separately
)
```

The routing algorithm:

```text
User kwargs
     │
     ▼
Extract action options (display, etc.)
     │
     ▼
Remaining kwargs
     │
     ▼
Build option ownership map
(which family defines each option)
     │
     ├─ 0 owners  →  ERROR: Unknown option
     │
     ├─ 1 owner   →  Auto-route to owner
     │
     └─ 2+ owners →  Disambiguation syntax used?
                          ├─ Yes → Route to specified strategy
                          └─ No  → ERROR: Ambiguous option
```

### How it works internally

- **Extract action options** — options like `display` are matched against `action_defs` and removed from the pool
- **Build strategy-to-family map** — maps each strategy ID to its family name (e.g., `:ipopt → :solver`)
- **Build option ownership map** — scans all strategy metadata to determine which family defines each option name
- **Route each remaining option** — auto-route if unambiguous, require disambiguation if ambiguous, error if unknown

## Disambiguation

When an option name appears in multiple strategies (e.g., `backend` is defined by both the modeler and the solver), the user must disambiguate using `route_to`:

`route_to` accepts two equivalent syntaxes — keyword and positional — choose based on preference:

| Syntax      | Example                      |
|-------------|------------------------------|
| Keyword     | `route_to(adnlp = :sparse)`  |
| Positional  | `route_to(:adnlp, :sparse)`  |

### Single strategy

```julia
# keyword syntax
solve(ocp, :collocation, :adnlp, :ipopt;
    backend = route_to(adnlp = :sparse),
)

# positional syntax (equivalent)
solve(ocp, :collocation, :adnlp, :ipopt;
    backend = route_to(:adnlp, :sparse),
)
```

### Multiple strategies

```julia
# keyword syntax
solve(ocp, :collocation, :adnlp, :ipopt;
    backend = route_to(adnlp = :sparse, ipopt = :cpu),
)

# positional syntax (equivalent)
solve(ocp, :collocation, :adnlp, :ipopt;
    backend = route_to(:adnlp, :sparse, :ipopt, :cpu),
)
```

### How `route_to` works

`route_to` creates a `RoutedOption` object that carries `(strategy_id => value)` pairs:

```@example routing
opt = Strategies.route_to(ipopt = 100, adnlp = 50)
```

The orchestration layer uses `extract_strategy_ids` to unpack this object during routing — see [Helper Functions](@ref) below.

## Helper Functions

The helper functions below are used internally by `route_all_options`. They operate on a `ResolvedMethod` — a precomputed view of the method tuple. In normal usage you do not need to call them directly; they are exposed for advanced use cases (custom routing logic, introspection, testing).

To use them, first call `resolve_method`:

```@example routing
resolved = Orchestration.resolve_method(method, families, registry)
nothing # hide
```

### `build_strategy_to_family_map`

Maps each strategy ID in the method to its family name:

```@example routing
Orchestration.build_strategy_to_family_map(resolved, families, registry)
```

### `build_option_ownership_map`

Scans all strategy metadata and maps each option name to the set of families that define it:

```@example routing
Orchestration.build_option_ownership_map(resolved, families, registry)
```

Note that `:backend` is owned by both `:modeler` and `:solver` — it is ambiguous and requires disambiguation.

### `extract_strategy_ids`

Unpacks a `RoutedOption` into a vector of `(value, strategy_id)` pairs:

```@example routing
Orchestration.extract_strategy_ids(
    Strategies.route_to(ipopt = 100, adnlp = 50), resolved,
)
```

For plain (non-routed) values, no disambiguation is detected — the function returns `nothing`:

```@repl routing
Orchestration.extract_strategy_ids(:plain_value, resolved)
```

Passing an unknown strategy ID throws an error:

```@repl routing
Orchestration.extract_strategy_ids(
    Strategies.route_to(unknown = 42), resolved,
)

```

## Complete Example

Auto-routing with disambiguation and action option extraction:

```@example routing
action_defs = [
    Options.OptionDefinition(name = :display, type = Bool, default = true,
                     description = "Display solver progress"),
]

kwargs = (
    grid_size = 100,                                     # auto-routed to discretizer
    max_iter  = 500,                                     # auto-routed to solver
    backend   = Strategies.route_to(adnlp = :optimized), # disambiguated to modeler
    display   = false,                                   # action option
)

routed = Orchestration.route_all_options(
    method, families, action_defs,
    kwargs, registry,
)
```

Action options:

```@example routing
routed.action
```

Strategy options per family:

```@example routing
routed.strategies
```

### Error: unknown option

```@repl routing
Orchestration.route_all_options(
    method, families, action_defs,
    (foo = 42,), registry,
)

```

### Error: ambiguous option without disambiguation

```@repl routing
Orchestration.route_all_options(
    method, families, action_defs,
    (backend = :sparse,), registry,
)

```

## Parameterized Strategies

A method tuple may end with a **parameter token** (e.g. `:cpu`, `:gpu`) selecting the
execution device of the parameterized strategies it contains (see
[Strategy Parameters](@ref guide-strategy-parameters)). Routing then uses the metadata
of the **selected** variant: option ownership, aliases, suggestions and ambiguity errors
all follow the parameter.

Here the solver family gains a parameterized `FakeMadNLP{P}` whose GPU variant declares an
extra `cuda_stream` option:

```@example routing
struct FakeMadNLP{P<:Strategies.AbstractStrategyParameter} <: AbstractFakeSolver
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:FakeMadNLP}) = :madnlp
Strategies.parameter(::Type{<:FakeMadNLP{P}}) where {P} = P
Strategies.default_parameter(::Type{<:FakeMadNLP}) = Strategies.CPU

_linear_solver_def(default) = Options.OptionDefinition(
    name = :linear_solver, type = Symbol,
    default = default, description = "Linear solver", computed = true,
)
Strategies.metadata(::Type{FakeMadNLP{Strategies.CPU}}) =
    Strategies.StrategyMetadata(_linear_solver_def(:mumps))
Strategies.metadata(::Type{FakeMadNLP{Strategies.GPU}}) =
    Strategies.StrategyMetadata(
        _linear_solver_def(:cudss),
        Options.OptionDefinition(
            name = :cuda_stream, type = Int,
            default = 0, description = "CUDA stream",
        ),
    )

FakeMadNLP{P}(; kwargs...) where {P} = FakeMadNLP{P}(
    Strategies.build_strategy_options(FakeMadNLP{P}; kwargs...),
)

registry_p = Strategies.create_registry(
    AbstractFakeDiscretizer => (FakeCollocation,),
    AbstractFakeModeler     => (FakeADNLP,),
    AbstractFakeSolver      => (FakeIpopt, (FakeMadNLP, [Strategies.CPU, Strategies.GPU])),
)
nothing # hide
```

The parameter is extracted once by `resolve_method`:

```@example routing
method_gpu = (:collocation, :adnlp, :madnlp, :gpu)
Orchestration.resolve_method(method_gpu, families, registry_p).parameter
```

With `:gpu`, `cuda_stream` is owned by the solver and routed to it:

```@example routing
routed_gpu = Orchestration.route_all_options(
    method_gpu, families, action_defs,
    (grid_size = 50, cuda_stream = 2), registry_p,
)
routed_gpu.strategies
```

With `:cpu`, the same option is unknown — the CPU variant does not declare it:

```@repl routing
Orchestration.route_all_options(
    (:collocation, :adnlp, :madnlp, :cpu), families, action_defs,
    (cuda_stream = 2,), registry_p,
)

```
