```@meta
CurrentModule = CTBase
```

# Strategy Parameters

This guide explains the **Strategy Parameters** system in CTBase. Parameters are singleton types that allow a strategy to specialize its metadata and default options depending on the execution context (e.g., CPU vs GPU).

!!! tip "Prerequisites"
    Read the [Implementing a Strategy](@ref) guide first. Parameters extend the strategy system with type-based specialization.

```@setup params
using CTBase
using CTBase.Strategies
using CTBase.Options
```

## Concept

**Strategy parameters** are singleton types that enable:

- **Type-based dispatch** so the same strategy struct can carry different defaults on CPU vs GPU
- **Compile-time specialization** through Julia's type system
- **Registry-level routing** so a method tuple like `(:mysolver, :cpu)` resolves to the right concrete type

Parameters are **not** runtime values — they exist purely for dispatch and metadata specialization.

## Built-in Parameters

CTBase ships two built-in parameters:

```@example params
Strategies.id(Strategies.CPU)
```

```@example params
Strategies.id(Strategies.GPU)
```

```@example params
Strategies.description(Strategies.CPU)
```

`describe` shows full introspection for a parameter type:

```@example params
Strategies.describe(Strategies.CPU)
```

## Parameter Contract

Every parameter type must:

1. **Subtype `AbstractStrategyParameter`**
2. **Be a singleton** (no fields)
3. **Implement `id(::Type{<:YourParameter})`** returning a `Symbol`
4. **Implement `description(::Type{<:YourParameter})`** returning a `String`

```@example params
struct Distributed <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{Distributed}) = :distributed
Strategies.description(::Type{Distributed}) = "Distributed multi-node execution"
Strategies.describe(Distributed)
```

## Parameter Validation

```@example params
Strategies.is_a_parameter(Strategies.CPU)   # true
```

```@example params
Strategies.is_a_parameter(Int)              # false
```

```@example params
Strategies.parameter_id(Strategies.CPU)        # :cpu
```

`validate_parameter_type` checks the full contract and returns `nothing` if valid:

```@example params
Strategies.validate_parameter_type(Strategies.CPU)
```

## Parameterized Strategy: Step-by-Step

A parameterized strategy is a generic struct over `P <: AbstractStrategyParameter`. The `metadata` method is specialized on `Type{MyStrategy{P}}`, letting Julia dispatch select the right defaults for each parameter.

### Step 1 — Define the strategy family and struct

```@example params
abstract type AbstractFakeOptimizer <: Strategies.AbstractStrategy end

struct FakeOptimizer{P <: Strategies.AbstractStrategyParameter} <: AbstractFakeOptimizer
    options::Strategies.StrategyOptions
end
nothing # hide
```

### Step 2 — Implement `id`

All parameter variants share the same ID:

```@example params
Strategies.id(::Type{<:FakeOptimizer}) = :fake_optimizer
nothing # hide
```

### Step 3 — Parameter-specific default helpers

```@example params
__fake_default_precision(::Type{Strategies.CPU}) = :float64
__fake_default_precision(::Type{Strategies.GPU}) = :float32
nothing # hide
```

### Step 4 — Implement `metadata` specialized on the parameterized type

The dispatch is on `::Type{FakeOptimizer{P}}` — not on a second argument:

```@example params
function Strategies.metadata(
    ::Type{FakeOptimizer{P}},
) where {P <: Strategies.AbstractStrategyParameter}
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name        = :precision,
            type        = Symbol,
            default     = __fake_default_precision(P),
            description = "Numerical precision
                (:float64 for CPU, :float32 for GPU)",
            computed    = true,
        ),
        Options.OptionDefinition(
            name        = :max_iter,
            type        = Int,
            default     = 1000,
            description = "Maximum number of iterations",
        ),
    )
end
nothing # hide
```

!!! note "Mark computed options with `computed=true`"
    An option whose default value depends on the parameter type `P` should be marked `computed=true`. It is evaluated at metadata construction time, not hard-coded. This flag is optional but strongly recommended: `describe` separates computed options by parameter (showing the actual default for each), making the parameter-specific behavior immediately visible to users.

Let's verify the metadata for each parameter — the `:precision` default differs:

```@example params
Strategies.metadata(FakeOptimizer{Strategies.CPU})
```

```@example params
Strategies.metadata(FakeOptimizer{Strategies.GPU})
```

### Step 5 — Implement the constructor

The constructor is specialized on the parameterized type so `build_strategy_options` calls the right `metadata`:

```@example params
function FakeOptimizer{P}(;
    mode::Symbol = :strict, kwargs...,
) where {P <: Strategies.AbstractStrategyParameter}
    opts = Strategies.build_strategy_options(
        FakeOptimizer{P}; mode = mode, kwargs...,
    )
    return FakeOptimizer{P}(opts)
end
nothing # hide
```

### Step 6 — Instantiate and inspect

```@example params
FakeOptimizer{Strategies.CPU}()
```

```@example params
FakeOptimizer{Strategies.GPU}()
```

```@example params
FakeOptimizer{Strategies.CPU}(max_iter = 500)
```

Option access works exactly like non-parameterized strategies:

```@example params
solver = FakeOptimizer{Strategies.GPU}(max_iter = 200)
```

```@repl params
solver[:precision]
solver[:max_iter]
Strategies.source(
    Strategies.options(solver), :max_iter,
)
```

## Registering Parameterized Strategies

In `create_registry`, a parameterized strategy is declared as a `(StrategyType, [Param1, Param2, ...])` tuple. Non-parameterized strategies are listed as plain types:

```@example params
registry = Strategies.create_registry(
    AbstractFakeOptimizer => (
        (FakeOptimizer, [Strategies.CPU, Strategies.GPU]),
    ),
)
```

The registry expands this into one concrete type per parameter. `strategy_ids` deduplicates:

```@example params
Strategies.strategy_ids(AbstractFakeOptimizer, registry)
```

```@example params
Strategies.type_from_id(
    :fake_optimizer,
    AbstractFakeOptimizer, registry;
    parameter=Strategies.CPU,
)
```

```@example params
Strategies.type_from_id(
    :fake_optimizer,
    AbstractFakeOptimizer, registry;
    parameter=Strategies.GPU,
)
```

## Building Strategies from the Registry

`build_strategy` accepts an optional parameter type as second argument:

```@example params
Strategies.build_strategy(
    :fake_optimizer, Strategies.CPU,
    AbstractFakeOptimizer, registry;
    max_iter = 300,
)
```

```@example params
Strategies.build_strategy(
    :fake_optimizer, Strategies.GPU,
    AbstractFakeOptimizer, registry,
)
```

## Method Tuple Routing

When using a method tuple (e.g., `(:fake_optimizer, :cpu)`), `extract_global_parameter_from_method` reads the parameter token from the registry:

```@example params
method = (:fake_optimizer, :cpu)
param = Strategies.extract_global_parameter_from_method(method, registry)
```

```@example params
id = Strategies.extract_id_from_method(
    method, AbstractFakeOptimizer, registry,
)
Strategies.build_strategy(
    id, param, AbstractFakeOptimizer, registry,
)
```

## Mixed Registries

A registry can mix parameterized and non-parameterized strategies in the same family:

```@example params
struct FallbackOptimizer <: AbstractFakeOptimizer
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:FallbackOptimizer}) = :fallback

function Strategies.metadata(::Type{<:FallbackOptimizer})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name = :max_iter, type = Int, default = 500,
            description = "Maximum iterations",
        ),
    )
end

function FallbackOptimizer(; mode::Symbol = :strict, kwargs...)
    opts = Strategies.build_strategy_options(
        FallbackOptimizer; mode = mode, kwargs...,
    )
    return FallbackOptimizer(opts)
end

mixed_registry = Strategies.create_registry(
    AbstractFakeOptimizer => (
        FallbackOptimizer,
        (FakeOptimizer, [Strategies.CPU, Strategies.GPU]),
    ),
)
```

```@example params
Strategies.strategy_ids(
    AbstractFakeOptimizer, mixed_registry,
)
```

## `describe` with a Registry

`describe` with a registry shows the full picture including available parameters:

```@example params
Strategies.describe(:fake_optimizer, registry)
```

## Summary

| Aspect | Description |
|--------|-------------|
| **Purpose** | Compile-time specialization of strategy defaults and metadata |
| **Contract** | Singleton struct + `id` + `description` implementations |
| **Built-in** | `CPU`, `GPU` |
| **Metadata dispatch** | `metadata(::Type{MyStrategy{P}}) where {P}` |
| **Registry syntax** | `(MyStrategy, [CPU, GPU])` tuple inside the family tuple |
| **Builder** | `build_strategy(id, Param, Family, registry; kwargs...)` |
| **Validation** | `validate_parameter_type`, `is_a_parameter`, `parameter_id` |

## See Also

- [Implementing a Strategy](@ref) — Strategy contract and metadata
- [Options System](@ref) — `OptionDefinition`, `StrategyOptions`
- `Strategies.AbstractStrategyParameter` — API reference
