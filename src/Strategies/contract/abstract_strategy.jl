"""
$(TYPEDEF)

Abstract base type for all strategies in the control-toolbox ecosystem.

Every concrete strategy must implement a **two-level contract** separating static type metadata from dynamic instance configuration.

## Contract Overview

### Type-Level Contract (Static Metadata)

Methods defined on the **type** that describe what the strategy can do:

- `id(::Type{<:MyStrategy})::Symbol` - Unique identifier for routing and introspection
- `metadata(::Type{<:MyStrategy})::StrategyMetadata` - Option specifications and validation rules

**Why type-level?** These methods enable:
- **Introspection without instantiation** - Query capabilities without creating objects
- **Routing and dispatch** - Select strategies by symbol for automated construction
- **Validation before construction** - Verify compatibility before resource allocation

### Instance-Level Contract (Configured State)

Methods defined on **instances** that provide the actual configuration:

- `options(strategy::MyStrategy)::StrategyOptions` - Current option values with provenance tracking

**Why instance-level?** These methods enable:
- **Multiple configurations** - Different instances with different settings
- **Provenance tracking** - Know which options came from user vs defaults
- **Encapsulation** - Configuration state belongs to the executing object

## Implementation Requirements

Every concrete strategy must provide:

1. **Type definition** with an `options::StrategyOptions` field (recommended)
2. **Type-level methods** for `id` and `metadata`
3. **Constructor** accepting keyword arguments (uses `build_strategy_options`)
4. **Instance-level access** to configured options

## Validation Modes

The strategy system supports two validation modes for option handling:

- **Strict Mode (default)**: Rejects unknown options with detailed error messages
  - Provides early error detection and safety
  - Suggests corrections for typos using Levenshtein distance
  - Ideal for development and production environments

- **Permissive Mode**: Accepts unknown options with warnings
  - Allows backend-specific options without breaking changes
  - Maintains validation for known options (types, custom validators)
  - Ideal for advanced users and experimental features

The validation mode is controlled by the `mode` parameter in constructors:

```julia-repl
# Strict mode (default) - rejects unknown options
julia> MyStrategy(unknown_option=123)  # ERROR

# Permissive mode - accepts unknown options with warning
julia> MyStrategy(unknown_option=123; mode=:permissive)  # WARNING but works
```

## API Methods

The Strategies module provides these methods for working with strategies:

- `id(strategy_type)` - Get the unique identifier
- `metadata(strategy_type)` - Get option specifications  
- `options(strategy)` - Get current configuration
- `build_strategy_options(Type; mode=:strict, kwargs...)` - Validate and merge options

# Example

```julia-repl
# Define strategy type
julia> struct MyStrategy <: AbstractStrategy
           options::StrategyOptions
       end

# Implement type-level contract
julia> id(::Type{<:MyStrategy}) = :mystrategy
julia> metadata(::Type{<:MyStrategy}) = StrategyMetadata(
           OptionDefinition(name=:max_iter, type=Int, default=100, description="Max iterations")
       )

# Implement constructor (required)
julia> function MyStrategy(; mode::Symbol=:strict, kwargs...)
           options = build_strategy_options(MyStrategy; mode=mode, kwargs...)
           return MyStrategy(options)
       end

# Use the strategy
julia> strategy = MyStrategy(max_iter=200)  # Instance with custom config (strict mode)
julia> id(typeof(strategy))                 # => :mystrategy (type-level)
julia> options(strategy)                    # => StrategyOptions (instance-level)

# Use with permissive mode for unknown options
julia> strategy = MyStrategy(max_iter=200, custom_option=123; mode=:permissive)
```

# Notes

- **Type-level methods** are called on the type: `id(MyStrategy)`
- **Instance-level methods** are called on instances: `options(strategy)`
- **Constructor pattern** is required for registry-based construction
- **Strategy families** can be created with intermediate abstract types
"""
abstract type AbstractStrategy end

"""
$(TYPEDSIGNATURES)

Return the unique identifier for this strategy type.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type

# Returns
- `Symbol`: Unique identifier for the strategy

# Example
```julia-repl
# For a concrete strategy type MyStrategy:
julia> id(MyStrategy)
:mystrategy
```
"""
function id end

"""
$(TYPEDSIGNATURES)

Return the current options of a strategy as a StrategyOptions.

# Arguments
- `strategy::AbstractStrategy`: The strategy instance

# Returns
- `StrategyOptions`: Current option values with provenance tracking

# Example
```julia-repl
# For a concrete strategy instance:
julia> strategy = MyStrategy(backend=:sparse)
julia> opts = options(strategy)
julia> opts
StrategyOptions with values=(backend=:sparse), sources=(backend=:user)
```
"""
function options end

"""
$(TYPEDSIGNATURES)

Return metadata about a strategy type.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type

# Returns
- `StrategyMetadata`: Option specifications and validation rules

# Example
```julia-repl
# For a concrete strategy type MyStrategy:
julia> meta = metadata(MyStrategy)
julia> meta
StrategyMetadata with option definitions for max_iter, etc.
```
"""
function metadata end

"""
$(TYPEDSIGNATURES)

Return the strategy parameter type for a concrete strategy type, or `nothing` if the
strategy is non-parameterized.

Every concrete strategy type must implement this method:
- Non-parameterized strategies return `nothing`.
- Parameterized strategies return the concrete parameter type.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type

# Returns
- `Type{<:AbstractStrategyParameter}`: The parameter type (e.g. `CPU`, `GPU`)
- `Nothing`: If the strategy is non-parameterized

# Example
```julia-repl
# Non-parameterized:
julia> parameter(Ipopt)
nothing

# Parameterized:
julia> parameter(MadNLP{CPU})
CPU
```

# Implementation
```julia
# Non-parameterized strategy:
Strategies.parameter(::Type{<:MyStrategy}) = nothing

# Parameterized strategy (bound repeated verbatim from the struct definition):
Strategies.parameter(::Type{<:MyStrategy{P}}) where {P<:AbstractStrategyParameter} = P
```

See also: [`CTBase.Strategies.default_parameter`](@ref), [`CTBase.Strategies.AbstractStrategyParameter`](@ref)
"""
function parameter end

# ============================================================================
# Default implementations that error if not overridden
# ============================================================================

# These default implementations enforce the contract by throwing helpful error
# messages when concrete strategies don't implement required methods.

"""
Default implementation for `id(::Type{T})` that throws `NotImplemented`.

This ensures that any concrete strategy type must explicitly implement
the `id` method to provide its unique identifier.

# Throws

- `Exceptions.NotImplemented`: When the concrete type doesn't override this method
"""
function id(::Type{T}) where {T<:AbstractStrategy}
    return throw(
        Exceptions.NotImplemented(
            "Strategy ID method not implemented";
            required_method="id(::Type{<:$T})",
            suggestion="Implement id(::Type{<:$T}) to return a unique Symbol identifier",
            context="AbstractStrategy.id - required method implementation",
        ),
    )
end

"""
Default implementation for `metadata(::Type{T})` that throws `NotImplemented`.

This ensures that any concrete strategy type must explicitly implement
the `metadata` method to provide its option specifications.

The error message reminds developers to return a `StrategyMetadata` wrapping
a `Dict` of `OptionDefinition` objects.

# Throws

- `Exceptions.NotImplemented`: When the concrete type doesn't override this method
"""
function metadata(::Type{T}) where {T<:AbstractStrategy}
    return throw(
        Exceptions.NotImplemented(
            "Strategy metadata method not implemented";
            required_method="metadata(::Type{<:$T})",
            suggestion="Implement metadata(::Type{<:$T}) to return StrategyMetadata with OptionDefinitions",
            context="AbstractStrategy.metadata - required method implementation",
        ),
    )
end

"""
Default implementation for `parameter(::Type{T})` that throws `NotImplemented`.

Every concrete strategy must override this with either
`parameter(::Type{<:S}) = nothing` (non-parameterized) or
`parameter(::Type{<:S{P}}) where {P<:AbstractStrategyParameter} = P` (parameterized).

# Throws

- `Exceptions.NotImplemented`: When the concrete type doesn't override this method
"""
function parameter(::Type{T}) where {T<:AbstractStrategy}
    return throw(
        Exceptions.NotImplemented(
            "Strategy parameter method not implemented";
            required_method="parameter(::Type{<:$T})",
            suggestion="Define `parameter(::Type{<:$T}) = nothing` for non-parameterized strategies, or `parameter(::Type{<:$T{P}}) where {P<:AbstractStrategyParameter} = P` for parameterized ones",
            context="AbstractStrategy.parameter - required method implementation",
        ),
    )
end

"""
Default implementation for `options(strategy::T)` with flexible field access.

This implementation supports two common patterns for strategy types:

1. **Field-based (recommended)**: Strategy has an `options::StrategyOptions` field
2. **Custom getter**: Strategy implements its own `options()` method

If the strategy type has an `options` field, this implementation returns it.
Otherwise, it throws a `NotImplemented` error to indicate that the concrete
type must implement its own getter.

# Arguments
- `strategy::T`: The strategy instance

# Returns
- `StrategyOptions`: The configured options for the strategy

# Throws

- `Exceptions.NotImplemented`: When the strategy has no `options` field and doesn't
  implement a custom `options()` method
"""
function options(strategy::T) where {T<:AbstractStrategy}
    if hasfield(T, :options)
        # Recommended pattern: direct field access for performance
        return getfield(strategy, :options)
    else
        # Fallback: require custom implementation for complex internal structures
        throw(
            Exceptions.NotImplemented(
                "Strategy options method not implemented";
                required_method="options(strategy::$T)",
                suggestion="Add options::StrategyOptions field to strategy type or implement custom options() method",
                context="AbstractStrategy.options - required method implementation",
            ),
        )
    end
end

# ============================================================================
# Collection Interface - Delegation to StrategyOptions
# ============================================================================

"""
$(TYPEDSIGNATURES)

Get the value of a strategy option (without source information).

This method delegates to the underlying `StrategyOptions` collection, providing
convenient bracket notation access to strategy options. Aliases are automatically
resolved to canonical names.

# Arguments
- `strategy::AbstractStrategy`: The strategy instance
- `key::Symbol`: Option name (canonical or alias)

# Returns
- The unwrapped option value

# Example
```julia-repl
julia> modeler = Modelers.ADNLP(backend=:sparse, max_iter=1000)

julia> modeler[:max_iter]  # Canonical name
1000

julia> modeler[:maxiter]   # Alias - automatically resolved
1000
```

# Notes
- This is syntactic sugar for `options(strategy)[key]`
- All functionality (alias resolution, provenance tracking) is handled by StrategyOptions
- Use `options(strategy)` for full access to OptionValue objects with source information

See also: [`CTBase.Strategies.options`](@ref), `Base.haskey`, `Base.keys`, [`CTBase.Strategies.StrategyOptions`](@ref)
"""
function Base.getindex(strategy::AbstractStrategy, key::Symbol)
    return options(strategy)[key]
end

"""
$(TYPEDSIGNATURES)

Check if a strategy option exists.

This method delegates to the underlying `StrategyOptions` collection. Aliases are
automatically resolved to canonical names.

# Arguments
- `strategy::AbstractStrategy`: The strategy instance
- `key::Symbol`: Option name to check (canonical or alias)

# Returns
- `Bool`: `true` if the option exists

# Example
```julia-repl
julia> modeler = Modelers.ADNLP(backend=:sparse)

julia> haskey(modeler, :max_iter)
true

julia> haskey(modeler, :maxiter)  # Alias - automatically resolved
true

julia> haskey(modeler, :nonexistent)
false
```

# Notes
- This is syntactic sugar for `haskey(options(strategy), key)`
- Aliases are automatically resolved to canonical names

See also: [`CTBase.Strategies.options`](@ref), `Base.getindex`, `Base.keys`, [`CTBase.Strategies.StrategyOptions`](@ref)
"""
function Base.haskey(strategy::AbstractStrategy, key::Symbol)
    return haskey(options(strategy), key)
end

"""
$(TYPEDSIGNATURES)

Get all option names for a strategy.

This method delegates to the underlying `StrategyOptions` collection, providing
access to all option names (canonical names only, not aliases).

# Arguments
- `strategy::AbstractStrategy`: The strategy instance

# Returns
- Iterator of option names (Symbols)

# Example
```julia-repl
julia> modeler = Modelers.ADNLP(backend=:sparse, max_iter=1000)

julia> collect(keys(modeler))
[:backend, :max_iter, :matrix_free, :show_time, :name]
```

# Notes
- This is syntactic sugar for `keys(options(strategy))`
- Returns canonical names only (not aliases)

See also: [`CTBase.Strategies.options`](@ref), `Base.getindex`, `Base.haskey`, [`CTBase.Strategies.StrategyOptions`](@ref)
"""
function Base.keys(strategy::AbstractStrategy)
    return keys(options(strategy))
end

# ============================================================================
# Display - Instance
# ============================================================================

"""
$(TYPEDSIGNATURES)

Pretty display of a strategy instance with tree-style formatting.

Shows the concrete type name, strategy id, and all configured options
with their values and provenance sources.

# Arguments
- `io::IO`: Output stream
- `::MIME"text/plain"`: MIME type for pretty printing
- `strategy::AbstractStrategy`: The strategy instance to display

# Example
```julia-repl
julia> FakeSolver()
FakeSolver (instance, id: :fake_solver)
├─ max_iter = 1000  [default]
└─ tol = 1.0e-8  [default]
Tip: use describe(FakeSolver) to see all available options.
```

See also: [`CTBase.Strategies.describe`](@ref), [`CTBase.Strategies.options`](@ref)
"""
function Base.show(io::IO, ::MIME"text/plain", strategy::T) where {T<:AbstractStrategy}
    fmt = Core.get_format_codes(io)
    type_name = nameof(T)
    strategy_id = id(T)
    opts = options(strategy)

    # Build display name: include parameter type when present (e.g. FakeOptimizer{CPU})
    param = parameter(T)
    display_name =
        param === nothing ? string(type_name) : string(type_name, "{", nameof(param), "}")

    # Header with ID on first line
    println(
        io,
        fmt.name,
        display_name,
        fmt.reset,
        " (instance, id=",
        fmt.keyword,
        ":",
        strategy_id,
        fmt.reset,
        ")",
    )

    items = collect(pairs(opts.options))
    for (i, (key, opt)) in enumerate(items)
        is_last = i == length(items)
        prefix = is_last ? "└─ " : "├─ "
        println(
            io,
            prefix,
            fmt.name,
            key,
            fmt.reset,
            " = ",
            fmt.value,
            Options.value(opt),
            fmt.reset,
            "  [",
            fmt.label,
            Options.source(opt),
            fmt.reset,
            "]",
        )
    end

    return println(
        io,
        fmt.label,
        "Tip: use describe(",
        type_name,
        ") to see all available options.",
        fmt.reset,
    )
end

"""
$(TYPEDSIGNATURES)

Compact display of a strategy instance.

# Arguments
- `io::IO`: Output stream
- `strategy::AbstractStrategy`: The strategy instance to display

# Example
```julia-repl
julia> print(FakeSolver())
FakeSolver(max_iter=1000, tol=1.0e-8)
```

See also: `Base.show`
"""
function Base.show(io::IO, strategy::T) where {T<:AbstractStrategy}
    fmt = Core.get_format_codes(io)
    type_name = nameof(T)
    opts = options(strategy)

    param = parameter(T)
    display_name =
        param === nothing ? string(type_name) : string(type_name, "{", nameof(param), "}")

    print(io, fmt.name, display_name, fmt.reset, "(")
    print(
        io,
        join(
            (
                fmt.name *
                "$k" *
                fmt.reset *
                "=" *
                fmt.value *
                "$(Options.value(v))" *
                fmt.reset for (k, v) in pairs(opts.options)
            ),
            ", ",
        ),
    )
    return print(io, ")")
end

# ============================================================================
# Describe - Type introspection
# ============================================================================

"""
$(TYPEDSIGNATURES)

Display detailed information about a strategy type, including its id,
supertype, and full metadata with all available option definitions.

This function is useful for discovering what options a strategy accepts
before constructing an instance.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type to describe

# Example
```julia-repl
julia> describe(Modelers.ADNLP)
Modelers.ADNLP (strategy type)
├─ id: :adnlp
├─ supertype: AbstractNLPModeler
└─ metadata: 4 options defined
   ├─ show_time :: Bool (default: false)
   │  description: Whether to show timing information
   ├─ backend :: Symbol (default: optimized)
   │  description: AD backend used by ADNLPModels
   └─ matrix_free :: Bool (default: false)
      description: Enable matrix-free mode
```

See also: [`CTBase.Strategies.metadata`](@ref), [`CTBase.Strategies.id`](@ref), [`CTBase.Strategies.options`](@ref)
"""
function describe end

"""
$(TYPEDSIGNATURES)

Return an optional description for a strategy type.

By default returns `nothing` (no description). Strategies may override this
to provide a human-readable summary and, optionally, a reference URL.
Multi-line descriptions are supported using `'\\n'`.

# Returns
- `Nothing`: When no description is defined (default)
- `String`: Human-readable description, optionally with URL on a second line

# Example
```julia
# Default: no description
description(MyStrategy)  # returns nothing

# Override with description and URL
description(::Type{<:Modelers.ADNLP}) =
    "NLP modeler using ADNLPModels.\\nSee: https://jso.dev/ADNLPModels.jl"
```

See also: [`CTBase.Strategies.describe`](@ref), [`CTBase.Strategies.AbstractStrategy`](@ref)
"""
description(::Type{<:AbstractStrategy}) = nothing

function describe(strategy_type::Type{T}) where {T<:AbstractStrategy}
    return describe(stdout, strategy_type)
end

function describe(io::IO, ::Type{T}) where {T<:AbstractStrategy}
    fmt = Core.get_format_codes(io)
    type_name = nameof(T)
    strategy_id = id(T)
    meta = metadata(T)
    desc = description(T)

    # Build hierarchy chain up to AbstractStrategy
    hierarchy_chain = Type[T]
    current = T
    while current !== AbstractStrategy && current !== Any
        current = supertype(current)
        push!(hierarchy_chain, current)
        if current === AbstractStrategy
            break
        end
    end
    hierarchy_str = join(
        [fmt.type * string(nameof(t)) * fmt.reset for t in hierarchy_chain], " → "
    )

    println(io, type_name, " (strategy type)")

    # id line
    println(io, "├─ id: :", strategy_id)

    # hierarchy line
    println(io, "├─ hierarchy: ", hierarchy_str)
    if desc !== nothing
        _print_labeled_multiline(io, "├─ ", "│  ", fmt, "description: ", desc)
    end

    # metadata section
    n_opts = length(meta)
    println(io, "└─ metadata: ", n_opts, " option", n_opts == 1 ? "" : "s", " defined")
    items = collect(pairs(meta))
    for (i, (key, def)) in enumerate(items)
        is_first = i == 1
        if is_first
            println(io, "   │  ")
        end
        is_last = i == length(items)
        prefix = is_last ? "   └─ " : "   ├─ "
        cont = is_last ? "      " : "   │  "
        println(io, prefix, def)
        _print_labeled_multiline(
            io, cont, cont, fmt, "description: ", Options.description(def)
        )
        # Add separator line between options (except after last)
        if !is_last
            println(io, cont)
        end
    end
end
