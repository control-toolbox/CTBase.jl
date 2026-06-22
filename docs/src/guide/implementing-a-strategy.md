# Implementing a Strategy

```@meta
CurrentModule = CTBase
```

This guide walks you through implementing a complete strategy family using the `AbstractStrategy` contract. We use **Collocation** and **DirectShooting** discretizers as concrete examples.

!!! tip "Prerequisites"
    Read the [Options System](@ref) guide first to understand `OptionDefinition`, `StrategyMetadata`, and `StrategyOptions`.

```@setup strategy
using CTBase
using CTBase.Strategies
using CTBase.Options
```

## The Two-Level Contract

Every strategy implements a **two-level contract** that separates static metadata from dynamic configuration:

```text
Type-Level (no instantiation needed)
├─ id(::Type{<:S})        → Symbol            (routing, registry lookup)
└─ metadata(::Type{<:S})  → StrategyMetadata  (option specs + validation rules)
            │
            ▼  routing, validation
   Constructor(; mode, kwargs...)
            │
            ▼
Instance-Level (configured object)
└─ options(instance)  → StrategyOptions  (values + provenance)
            │
            ▼  execution
   Strategy computation
```

- **Type-level** methods (`id`, `metadata`) can be called on the **type itself** — no object needed. This enables registry lookup, option routing, and validation before any resource allocation.
- **Instance-level** methods (`options`) are called on **instances** — they carry the actual configuration with provenance tracking (user vs default).

## Defining a Strategy Family

A strategy family is an intermediate abstract type that groups related strategies. Here we define a family for optimal control discretizers:

```@example strategy
abstract type AbstractOptimalControlDiscretizer <: Strategies.AbstractStrategy end
nothing # hide
```

This type enables:

- Grouping discretizers in a `StrategyRegistry` by family
- Dispatching on the family in option routing
- Adding methods common to all discretizers

## Implementing a Concrete Strategy: Collocation

### Step 1 — Define the struct

A strategy struct needs a field: `options::Strategies.StrategyOptions`.

```@example strategy
struct Collocation <: AbstractOptimalControlDiscretizer
    options::Strategies.StrategyOptions
end
nothing # hide
```

### Step 2 — Implement `id`

The `id` method returns a unique `Symbol` identifier for the strategy. It is a **type-level** method.

```@example strategy
Strategies.id(::Type{<:Collocation}) = :collocation
nothing # hide
```

### Step 3 — Define default values

Use the `__name()` convention for private default functions:

```@example strategy
__collocation_grid_size()::Int = 250
__collocation_scheme()::Symbol = :midpoint
nothing # hide
```

### Step 4 — Implement `metadata`

The `metadata` method returns a `StrategyMetadata` containing `OptionDefinition` objects. It is a **type-level** method.

```@example strategy
function Strategies.metadata(::Type{<:Collocation})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name = :grid_size,
            type = Int,
            default = __collocation_grid_size(),
            description = "Number of time steps for the collocation grid",
        ),
        Options.OptionDefinition(
            name = :scheme,
            type = Symbol,
            default = __collocation_scheme(),
            description = "Time integration scheme (e.g., :midpoint, :trapeze)",
        ),
    )
end
nothing # hide
```

Let's verify the metadata:

```@example strategy
Strategies.metadata(Collocation)
```

### Step 5 — Implement the constructor

The constructor uses `build_strategy_options` to validate and merge user-provided options with defaults:

```@example strategy
function Collocation(; mode::Symbol = :strict, kwargs...)
    opts = Strategies.build_strategy_options(Collocation; mode = mode, kwargs...)
    return Collocation(opts)
end
nothing # hide
```

### Step 6 — Implement `options`

The `options` method provides instance-level access to the configured options:

```@example strategy
Strategies.options(c::Collocation) = c.options
nothing # hide
```

Now let's create instances and inspect them:

```@example strategy
c = Collocation()
```

```@example strategy
c = Collocation(grid_size = 500, scheme = :trapeze)
```

```@example strategy
describe(Collocation)
```

### Step 7 — Access options

The `StrategyOptions` object tracks both values and their provenance. You can access options in two ways:

**Via the `options` getter:**

```@example strategy
c = Collocation(grid_size = 100)
```

```@example strategy
Strategies.options(c)
```

```@repl strategy
Strategies.options(c)[:grid_size]
```

**Directly on the strategy instance (syntactic sugar):**

```@repl strategy
c[:grid_size]
```

Both methods are equivalent — the direct access delegates to `options(strategy)[key]`. Use whichever style you prefer.

**Accessing provenance information:**

```@repl strategy
Strategies.source(Strategies.options(c), :grid_size)
```

```@repl strategy
Strategies.is_user(Strategies.options(c), :grid_size)
```

```@repl strategy
Strategies.is_default(Strategies.options(c), :scheme)
```

### Error handling

A typo in an option name triggers a helpful error with Levenshtein suggestion:

```@repl strategy
try # hide
Collocation(grdi_size = 500)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Adding a Second Strategy: DirectShooting

The same pattern applies to any strategy in the family. Here is `DirectShooting` with different options:

```@example strategy
struct DirectShooting <: AbstractOptimalControlDiscretizer
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:DirectShooting}) = :direct_shooting

__shooting_grid_size()::Int = 100

function Strategies.metadata(::Type{<:DirectShooting})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name = :grid_size,
            type = Int,
            default = __shooting_grid_size(),
            description = "Number of shooting intervals",
        ),
    )
end

function DirectShooting(; mode::Symbol = :strict, kwargs...)
    opts = Strategies.build_strategy_options(DirectShooting; mode = mode, kwargs...)
    return DirectShooting(opts)
end

Strategies.options(ds::DirectShooting) = ds.options
nothing # hide
```

!!! note "Same option name, different definitions"
    Both `Collocation` and `DirectShooting` define a `:grid_size` option, but with different defaults (250 vs 100) and descriptions. Each strategy has its own independent `OptionDefinition` set.

```@example strategy
DirectShooting()
```

```@example strategy
DirectShooting(grid_size = 50)
```

## Registering the Family

A `StrategyRegistry` maps abstract family types to their concrete strategies. This enables lookup by symbol and automated construction.

```@example strategy
registry = Strategies.create_registry(
    AbstractOptimalControlDiscretizer => (Collocation, DirectShooting),
)
```

Query the registry:

```@repl strategy
Strategies.strategy_ids(AbstractOptimalControlDiscretizer, registry)
```

```@repl strategy
Strategies.type_from_id(:collocation, AbstractOptimalControlDiscretizer, registry)
```

Build a strategy from the registry:

```@example strategy
Strategies.build_strategy(:collocation, AbstractOptimalControlDiscretizer, registry; grid_size = 300)
```

```@example strategy
Strategies.build_strategy(:direct_shooting, AbstractOptimalControlDiscretizer, registry; grid_size = 50)
```

## Integration with Method Tuples

In the full CTBase pipeline, a **method tuple** like `(:collocation, :adnlp, :ipopt)` identifies one strategy per family. The orchestration layer extracts the right ID for each family:

```@repl strategy
method = (:collocation, :adnlp, :ipopt)
Strategies.extract_id_from_method(method, AbstractOptimalControlDiscretizer, registry)
```

Build a strategy directly from a method tuple:

```@example strategy
id = Strategies.extract_id_from_method(method, AbstractOptimalControlDiscretizer, registry)
Strategies.build_strategy(id, AbstractOptimalControlDiscretizer, registry; grid_size = 500, scheme = :trapeze)
```

See [Orchestration & Routing](@ref) for the full multi-strategy routing system.

## Introspection

The Strategies API provides type-level introspection without instantiation:

```@repl strategy
Strategies.option_names(Collocation)
```

```@repl strategy
Strategies.option_names(DirectShooting)
```

```@repl strategy
Strategies.option_defaults(Collocation)
```

```@repl strategy
Strategies.option_defaults(DirectShooting)
```

```@repl strategy
Strategies.option_type(Collocation, :scheme)
```

```@repl strategy
Strategies.option_description(Collocation, :grid_size)
```

## Advanced Patterns

### Permissive Mode

Use `mode = :permissive` to accept backend-specific options that are not declared in the metadata:

```@example strategy
Collocation(grid_size = 500, custom_backend_param = 42; mode = :permissive)
```

Unknown options are stored with `:user` source but bypass type validation. Known options are still fully validated.

### Bypass Validation for Specific Options

Use `bypass(val)` (or its alias `force(val)`) to skip validation for a **single option value** while keeping strict mode for everything else.

**Unknown option** — accepted silently, no warning:

```@example strategy
Collocation(grid_size = 500, custom_backend_param = bypass(42))
```

**Known option with wrong type** — normally rejected, accepted with `bypass`:

```@repl strategy
try # hide
Collocation(grid_size = "oops")   # type error: grid_size expects Int
catch e; showerror(IOContext(stdout, :color => false), e) end # hide
```

```@example strategy
Collocation(grid_size = bypass("oops"))   # no error: validation skipped
```

This is more surgical than `mode = :permissive`:

| Approach                       | Scope       | Unknown option names  | Type validation             |
|--------------------------------|-------------|-----------------------|-----------------------------|
| `mode = :permissive`           | all options | accepted with warning | skipped for unknowns        |
| `bypass(val)` / `force(val)`   | one value   | accepted silently     | skipped for that value only |

`force` is an alias for `bypass` — choose the name that fits your mental model:

```julia
Collocation(grid_size = force("oops"))   # same as bypass("oops")
```

!!! warning "Use with care"
    Bypassed values are not type-checked, even for declared options. A wrong type or invalid value will only surface as a backend-level error.

### Option Aliases

An `OptionDefinition` can declare aliases — alternative names that resolve to the primary name:

```julia
Options.OptionDefinition(
    name = :grid_size,
    type = Int,
    default = 250,
    description = "Number of time steps",
    aliases = [:N, :num_steps],
)
```

With this definition, `Collocation(N = 100)` would be equivalent to `Collocation(grid_size = 100)`.

### Custom Validators

Add a `validator` function to enforce constraints beyond type checking:

```julia
Options.OptionDefinition(
    name = :grid_size,
    type = Int,
    default = 250,
    description = "Number of time steps",
    validator = x -> x > 0 || throw(ArgumentError("grid_size must be positive")),
)
```

The validator is called during construction in both strict and permissive modes.
