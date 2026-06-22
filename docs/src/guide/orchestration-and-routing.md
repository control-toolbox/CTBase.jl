# Orchestration and Routing

```@meta
CurrentModule = CTBase
```

This guide explains how the Orchestration module routes user-provided keyword arguments to the correct strategy in a multi-strategy pipeline. It covers the method tuple concept, automatic routing, disambiguation syntax, and the helper functions that power the system.

!!! tip "Prerequisites"
    Read [Implementing a Strategy](@ref) first. Orchestration builds on top of the strategy metadata system.

```@setup routing
using CTBase
using CTBase.Options: OptionDefinition
using CTBase.Strategies: route_to
using CTBase.Orchestration: resolve_method, route_all_options
using CTBase.Orchestration: extract_strategy_ids, build_strategy_to_family_map, build_option_ownership_map
```

We define three fake strategies — a discretizer, a modeler, and a solver — with a shared `backend` option to demonstrate routing and disambiguation:

```@example routing
# --- Fake discretizer family ---
abstract type AbstractFakeDiscretizer <: CTBase.Strategies.AbstractStrategy end
struct FakeCollocation <: AbstractFakeDiscretizer; options::CTBase.Strategies.StrategyOptions; end
CTBase.Strategies.id(::Type{<:FakeCollocation}) = :collocation
CTBase.Strategies.metadata(::Type{<:FakeCollocation}) = CTBase.Strategies.StrategyMetadata(
    OptionDefinition(name = :grid_size, type = Int, default = 100, description = "Grid size"),
)
FakeCollocation(; kwargs...) = FakeCollocation(CTBase.Strategies.build_strategy_options(FakeCollocation; kwargs...))

# --- Fake modeler family ---
abstract type AbstractFakeModeler <: CTBase.Strategies.AbstractStrategy end
struct FakeADNLP <: AbstractFakeModeler; options::CTBase.Strategies.StrategyOptions; end
CTBase.Strategies.id(::Type{<:FakeADNLP}) = :adnlp
CTBase.Strategies.metadata(::Type{<:FakeADNLP}) = CTBase.Strategies.StrategyMetadata(
    OptionDefinition(name = :backend, type = Symbol, default = :default, description = "AD backend"),
)
FakeADNLP(; kwargs...) = FakeADNLP(CTBase.Strategies.build_strategy_options(FakeADNLP; kwargs...))

# --- Fake solver family ---
abstract type AbstractFakeSolver <: CTBase.Strategies.AbstractStrategy end
struct FakeIpopt <: AbstractFakeSolver; options::CTBase.Strategies.StrategyOptions; end
CTBase.Strategies.id(::Type{<:FakeIpopt}) = :ipopt
CTBase.Strategies.metadata(::Type{<:FakeIpopt}) = CTBase.Strategies.StrategyMetadata(
    OptionDefinition(name = :max_iter, type = Integer, default = 1000, description = "Max iterations"),
    OptionDefinition(name = :backend, type = Symbol, default = :cpu, description = "Compute backend"),
)
FakeIpopt(; kwargs...) = FakeIpopt(CTBase.Strategies.build_strategy_options(FakeIpopt; kwargs...))

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

1. **Extract action options** — options like `display` are matched against `action_defs` and removed from the pool
2. **Build strategy-to-family map** — maps each strategy ID to its family name (e.g., `:ipopt → :solver`)
3. **Build option ownership map** — scans all strategy metadata to determine which family defines each option name
4. **Route each remaining option** — auto-route if unambiguous, require disambiguation if ambiguous, error if unknown

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
opt = route_to(ipopt = 100, adnlp = 50)
```

The orchestration layer uses `extract_strategy_ids` to unpack this object during routing — see [Helper Functions](@ref) below.

## Helper Functions

The helper functions below are used internally by `route_all_options`. They operate on a `ResolvedMethod` — a precomputed view of the method tuple. In normal usage you do not need to call them directly; they are exposed for advanced use cases (custom routing logic, introspection, testing).

To use them, first call `resolve_method`:

```@example routing
resolved = resolve_method(method, families, registry)
nothing # hide
```

### `build_strategy_to_family_map`

Maps each strategy ID in the method to its family name:

```@example routing
build_strategy_to_family_map(resolved, families, registry)
```

### `build_option_ownership_map`

Scans all strategy metadata and maps each option name to the set of families that define it:

```@example routing
build_option_ownership_map(resolved, families, registry)
```

Note that `:backend` is owned by both `:modeler` and `:solver` — it is ambiguous and requires disambiguation.

### `extract_strategy_ids`

Unpacks a `RoutedOption` into a vector of `(value, strategy_id)` pairs:

```@example routing
extract_strategy_ids(route_to(ipopt = 100, adnlp = 50), resolved)
```

For plain (non-routed) values, no disambiguation is detected — the function returns `nothing`:

```@repl routing
extract_strategy_ids(:plain_value, resolved)
```

Passing an unknown strategy ID throws an error:

```@repl routing
try # hide
extract_strategy_ids(route_to(unknown = 42), resolved)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Complete Example

Auto-routing with disambiguation and action option extraction:

```@example routing
action_defs = [
    OptionDefinition(name = :display, type = Bool, default = true,
                     description = "Display solver progress"),
]

kwargs = (
    grid_size = 100,                          # auto-routed to discretizer
    max_iter  = 500,                          # auto-routed to solver
    backend   = route_to(adnlp = :optimized), # disambiguated to modeler
    display   = false,                        # action option
)

routed = route_all_options(method, families, action_defs, kwargs, registry)
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
try # hide
route_all_options(method, families, action_defs, (foo = 42,), registry)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

### Error: ambiguous option without disambiguation

```@repl routing
try # hide
route_all_options(method, families, action_defs, (backend = :sparse,), registry)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```
