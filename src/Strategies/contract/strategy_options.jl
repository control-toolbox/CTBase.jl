"""
$(TYPEDEF)

Wrapper for strategy option values with provenance tracking.

This type stores options as a collection of `OptionValue` objects, each containing
both the value and its source (`:user`, `:default`, or `:computed`).

## Validation Modes

Strategy options are built using `build_strategy_options()` which supports two validation modes:

- **Strict Mode (default)**: Only known options are accepted
  - Unknown options trigger detailed error messages with suggestions
  - Type validation and custom validators are enforced
  - Provides early error detection and safety

- **Permissive Mode**: Unknown options are accepted with warnings
  - Unknown options are stored with `:user` source
  - Type validation and custom validators still apply to known options
  - Allows backend-specific options without breaking changes

# Fields
- `options::NamedTuple`: NamedTuple of OptionValue objects with provenance
- `alias_map::Dict{Symbol, Symbol}`: Mapping from alias names to canonical names

# Construction

```julia-repl
julia> using CTBase.Strategies, CTBase.Options

julia> opts = StrategyOptions(
           max_iter = OptionValue(200, :user),
           tol = OptionValue(1e-6, :default)
       )
StrategyOptions with 2 options:
  max_iter = 200  [user]
  tol = 1.0e-6  [default]
```

# Building Options with Validation

```julia-repl
# Strict mode (default) - rejects unknown options
julia> opts = build_strategy_options(MyStrategy; max_iter=200)
StrategyOptions(...)

# Permissive mode - accepts unknown options with warning
julia> opts = build_strategy_options(MyStrategy; max_iter=200, custom_opt=123; mode=:permissive)
StrategyOptions(...)  # with warning about custom_opt
```

# Access patterns

```julia-repl
# Get value only (canonical name)
julia> opts[:max_iter]
200

# Get value using alias
julia> opts[:maxiter]  # Alias automatically resolved
200

# Get OptionValue (value + source)
julia> opts.max_iter
OptionValue(200, :user)

# Get source only
julia> source(opts, :max_iter)
:user

# Check if user-provided
julia> is_user(opts, :max_iter)
true

# Check if option exists (works with aliases)
julia> haskey(opts, :maxiter)
true
```

# Iteration

```julia-repl
# Iterate over values
julia> for value in opts
           println(value)
       end

# Iterate over (name, value) pairs
julia> for (name, value) in opts
           println("\$name = \$value")
       end
```

See also: `OptionValue`, `source`, `is_user`, `is_default`, `is_computed`
"""
struct StrategyOptions{NT<:NamedTuple}
    options::NT
    alias_map::Dict{Symbol,Symbol}

    function StrategyOptions(
        options::NT, alias_map::Dict{Symbol,Symbol}=Dict{Symbol,Symbol}()
    ) where {NT<:NamedTuple}
        for (key, val) in pairs(options)
            if !(val isa Options.OptionValue)
                throw(
                    Exceptions.IncorrectArgument(
                        "Invalid option value type";
                        got="$(typeof(val)) for key :$key",
                        expected="OptionValue for all strategy options",
                        suggestion="Wrap your value with OptionValue(value, :user/:default/:computed) or use the StrategyOptions constructor",
                        context="StrategyOptions constructor - validating option types",
                    ),
                )
            end
        end
        new{NT}(options, alias_map)
    end

    StrategyOptions(; kwargs...) = StrategyOptions((; kwargs...), Dict{Symbol,Symbol}())
end

# ============================================================================
# Alias resolution helper
# ============================================================================

"""
$(TYPEDSIGNATURES)

**Private helper function** - for internal framework use only.

Resolve an alias to its canonical name, or return the key unchanged if not an alias.

This function performs O(1) lookup in the alias_map to resolve aliases to their
canonical names. If the key is not found in the alias_map, it is assumed to be
already canonical and returned unchanged.

!!! warning "Internal Use Only"
    This function is **not part of the public API** and may change without notice.
    External code should use the public access methods which handle alias resolution automatically.

# Arguments
- `opts::StrategyOptions`: Strategy options containing the alias map
- `key::Symbol`: Key to resolve (can be canonical name or alias)

# Returns
- `Symbol`: Canonical name for the option

# Example
```julia
# Internal usage only
canonical = _resolve_key(opts, :maxiter)  # Returns :max_iter
canonical = _resolve_key(opts, :max_iter)  # Returns :max_iter (already canonical)
```

See also: `Base.getindex`, `Base.haskey`
"""
_resolve_key(opts::StrategyOptions, key::Symbol) = get(getfield(opts, :alias_map), key, key)

# ============================================================================
# Value access - returns unwrapped value
# ============================================================================

"""
$(TYPEDSIGNATURES)

Get the value of an option (without source information).

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- The unwrapped option value

# Notes
This method is type-unstable due to dynamic key lookup. For type-stable access,
use the `get(::Val{key})` method or direct field access.

# Example
```julia-repl
julia> opts[:max_iter]  # Canonical name
200

julia> opts[:maxiter]  # Alias - automatically resolved
200

julia> get(opts, Val(:max_iter))  # Type-stable
200
```

# Notes
- Aliases are automatically resolved to canonical names
- Both canonical names and aliases can be used interchangeably

See also: `Base.getproperty`, `source`, `get(::StrategyOptions, ::Val)`
"""
function Base.getindex(opts::StrategyOptions, key::Symbol)
    Options.value(option(opts, _resolve_key(opts, key)))
end

"""
$(TYPEDSIGNATURES)

Type-stable access to option value using Val.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `::Val{key}`: Compile-time key

# Returns
- The unwrapped option value with exact type inference

# Example
```julia-repl
julia> get(opts, Val(:max_iter))
200
```

See also: `Base.getindex`, `Base.getproperty`
"""
function Base.get(opts::StrategyOptions{NT}, ::Val{key}) where {NT<:NamedTuple,key}
    return Options.value(option(opts, key))
end

"""
$(TYPEDSIGNATURES)

Get the OptionValue for an option (with source information).

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name or `:options` for the internal field

# Returns
- `OptionValue`: Complete option with value and source, or the internal options field

# Example
```julia-repl
julia> opts.max_iter
OptionValue(200, :user)

julia> opts.max_iter.value
200

julia> opts.max_iter.source
:user
```

# Notes
- This method does NOT resolve aliases (use `opts[:alias]` for alias resolution)
- Only canonical field names work with dot notation
- Use bracket notation `opts[:alias]` for alias support

See also: `Base.getindex`, `source`
"""
function Base.getproperty(opts::StrategyOptions, key::Symbol)
    # Special handling for internal fields
    if key === :options
        return _raw_options(opts)
    elseif key === :alias_map
        return getfield(opts, :alias_map)
    else
        # Dot notation does NOT resolve aliases - only canonical names work
        return _raw_options(opts)[key]
    end
end

# ==========================================================================
# OptionValue access helpers
# ==========================================================================

"""
$(TYPEDSIGNATURES)

Get the `OptionValue` wrapper for an option.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Options.OptionValue`: The option value wrapper

# Example
```julia-repl
julia> opt = option(opts, :max_iter)
julia> Options.value(opt)
200

julia> opt = option(opts, :maxiter)  # Alias - automatically resolved
julia> Options.value(opt)
200
```

# Notes
- Aliases are automatically resolved to canonical names

See also: `Base.getproperty`, `Options.source`
"""
option(opts::StrategyOptions, key::Symbol) = _raw_options(opts)[_resolve_key(opts, key)]

# ============================================================================
# Source access helpers
# ============================================================================
"""
$(TYPEDSIGNATURES)

Get the value of an option.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Any`: Value of the option

# Example
```julia-repl
julia> Options.value(opts, :max_iter)
200
```

See also: `Options.is_user`, `Options.is_default`, `Options.is_computed`
"""
function Options.value(opts::StrategyOptions, key::Symbol)
    return Options.value(option(opts, key))
end

"""
$(TYPEDSIGNATURES)

Get the source of an option.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Symbol`: Source of the option (`:user`, `:default`, or `:computed`)

# Example
```julia-repl
julia> Options.source(opts, :max_iter)
:user
```

See also: `Options.is_user`, `Options.is_default`, `Options.is_computed`
"""
function Options.source(opts::StrategyOptions, key::Symbol)
    return Options.source(option(opts, key))
end

"""
$(TYPEDSIGNATURES)

Check if an option was provided by the user.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Bool`: `true` if the option was provided by the user

# Example
```julia-repl
julia> Options.is_user(opts, :max_iter)
true
```

See also: `Options.source`, `Options.is_default`, `Options.is_computed`
"""
function Options.is_user(opts::StrategyOptions, key::Symbol)
    return Options.is_user(option(opts, key))
end

"""
$(TYPEDSIGNATURES)

Check if an option is using its default value.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Bool`: `true` if the option is using its default value

# Example
```julia-repl
julia> Options.is_default(opts, :tol)
true
```

See also: `Options.source`, `Options.is_user`, `Options.is_computed`
"""
function Options.is_default(opts::StrategyOptions, key::Symbol)
    return Options.is_default(option(opts, key))
end

"""
$(TYPEDSIGNATURES)

Check if an option was computed.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name

# Returns
- `Bool`: `true` if the option was computed

# Example
```julia-repl
julia> Options.is_computed(opts, :step)
true
```

See also: `Options.source`, `Options.is_user`, `Options.is_default`
"""
function Options.is_computed(opts::StrategyOptions, key::Symbol)
    return Options.is_computed(option(opts, key))
end

# ============================================================================
# Private Helper for Internal Use
# ============================================================================

"""
$(TYPEDSIGNATURES)

**Private helper function** - for internal framework use only.

Returns the raw NamedTuple of OptionValue objects from the internal storage.
This is needed for `Options.extract_raw_options` which requires access to the
full OptionValue objects, not just their `.value` fields.

!!! warning "Internal Use Only"
    This function is **not part of the public API** and may change without notice.
    External code should use the public collection interface (`pairs`, `keys`, `values`, etc.).

# Returns
- NamedTuple of `(Symbol => OptionValue)` from the internal storage
"""
_raw_options(opts::StrategyOptions) = getfield(opts, :options)

# ============================================================================
# Collection interface
# ============================================================================

"""
$(TYPEDSIGNATURES)

Get all option names.

# Arguments
- `opts::StrategyOptions`: Strategy options

# Returns
- Iterator of option names (Symbols)

# Example
```julia-repl
julia> collect(keys(opts))
[:max_iter, :tol]
```

See also: `Base.values`, `Base.pairs`
"""
Base.keys(opts::StrategyOptions) = keys(_raw_options(opts))
"""
$(TYPEDSIGNATURES)

Get all option values (unwrapped).

# Arguments
- `opts::StrategyOptions`: Strategy options

# Returns
- Generator of unwrapped option values

# Example
```julia-repl
julia> collect(values(opts))
[200, 1.0e-6]
```

See also: `Base.keys`, `Base.pairs`
"""
function Base.values(opts::StrategyOptions)
    (Options.value(opt) for opt in values(_raw_options(opts)))
end
"""
$(TYPEDSIGNATURES)

Get all (name, value) pairs (values unwrapped).

# Arguments
- `opts::StrategyOptions`: Strategy options

# Returns
- Generator of (Symbol, value) pairs

# Example
```julia-repl
julia> collect(pairs(opts))
[:max_iter => 200, :tol => 1.0e-6]
```

See also: `Base.keys`, `Base.values`
"""
function Base.pairs(opts::StrategyOptions)
    (k => Options.value(v) for (k, v) in pairs(_raw_options(opts)))
end

"""
$(TYPEDSIGNATURES)

Iterate over option values (unwrapped).

# Arguments
- `opts::StrategyOptions`: Strategy options
- `state...`: Iteration state (optional)

# Returns
- Tuple of (value, state) or `nothing` when done

# Example
```julia-repl
julia> for value in opts
           println(value)
       end
200
1.0e-6
```

See also: `Base.keys`, `Base.values`, `Base.pairs`
"""
function Base.iterate(opts::StrategyOptions, state...)
    result = iterate(values(_raw_options(opts)), state...)
    result === nothing && return nothing
    (opt, newstate) = result
    return (Options.value(opt), newstate)
end

"""
$(TYPEDSIGNATURES)

Get number of options.

# Arguments
- `opts::StrategyOptions`: Strategy options

# Returns
- `Int`: Number of options

# Example
```julia-repl
julia> length(opts)
2
```

See also: `Base.isempty`, `Base.haskey`
"""
Base.length(opts::StrategyOptions) = length(_raw_options(opts))
"""
$(TYPEDSIGNATURES)

Check if options collection is empty.

# Arguments
- `opts::StrategyOptions`: Strategy options

# Returns
- `Bool`: `true` if no options are present

# Example
```julia-repl
julia> isempty(opts)
false
```

See also: `Base.length`, `Base.haskey`
"""
Base.isempty(opts::StrategyOptions) = isempty(_raw_options(opts))
"""
$(TYPEDSIGNATURES)

Check if an option exists.

# Arguments
- `opts::StrategyOptions`: Strategy options
- `key::Symbol`: Option name to check

# Returns
- `Bool`: `true` if the option exists

# Example
```julia-repl
julia> haskey(opts, :max_iter)
true

julia> haskey(opts, :maxiter)  # Alias - automatically resolved
true

julia> haskey(opts, :nonexistent)
false
```

# Notes
- Aliases are automatically resolved to canonical names
- Both canonical names and aliases can be used

See also: `Base.length`, `Base.isempty`
"""
function Base.haskey(opts::StrategyOptions, key::Symbol)
    haskey(_raw_options(opts), _resolve_key(opts, key))
end

# ============================================================================
# Conversion utilities
# ============================================================================

"""
$(TYPEDSIGNATURES)

Extract strategy options as a mutable Dict, ready for modification.

This method converts StrategyOptions to a Dict by unwrapping OptionValue
wrappers and filtering out NotProvided values. The resulting Dict is mutable
and can be modified before passing to backend solvers or model builders.

# Arguments
- `opts::StrategyOptions`: Strategy options to convert

# Returns
- `Dict{Symbol, Any}`: Mutable dictionary of option values

# Example
```julia-repl
julia> using CTBase.Strategies, CTBase.Options

julia> opts = StrategyOptions(
           max_iter = OptionValue(500, :user),
           tolerance = OptionValue(1e-8, :default)
       )

julia> dict = options_dict(opts)
Dict{Symbol, Any} with 2 entries:
  :max_iter => 500
  :tolerance => 1.0e-8

julia> dict[:verbose] = true  # Modify as needed
true
```

# Notes
- NotProvided values are filtered out
- Explicit nothing values are preserved
- The returned Dict is mutable and independent from the original StrategyOptions

See also: `Options.extract_raw_options`, `_raw_options`
"""
function options_dict(opts::StrategyOptions)
    raw_opts = Options.extract_raw_options(_raw_options(opts))
    return Dict{Symbol,Any}(pairs(raw_opts))
end

# ============================================================================
# Display
# ============================================================================

"""
$(TYPEDSIGNATURES)

Display StrategyOptions with values and their provenance sources.

This method formats the output to show each option value alongside its source
(`:user`, `:default`, or `:computed`) for complete traceability.

# Arguments
- `io::IO`: Output stream
- `::MIME"text/plain"`: MIME type for pretty printing
- `opts::StrategyOptions`: Strategy options to display

# Example
```julia-repl
julia> opts
StrategyOptions with 2 options:
  max_iter = 200  [user]
  tol = 1.0e-6  [default]
```

See also: `Base.show`
"""
function Base.show(io::IO, ::MIME"text/plain", opts::StrategyOptions)
    fmt = Core.get_format_codes(io)
    n = length(opts)
    println(
        io,
        fmt.name,
        "StrategyOptions",
        fmt.reset,
        " with ",
        fmt.count,
        n,
        fmt.reset,
        " option",
        n == 1 ? "" : "s",
        ":",
    )
    items = collect(pairs(_raw_options(opts)))
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
end

"""
$(TYPEDSIGNATURES)

Compact display of StrategyOptions.

# Arguments
- `io::IO`: Output stream
- `opts::StrategyOptions`: Strategy options to display

# Example
```julia-repl
julia> print(opts)
StrategyOptions(max_iter=200, tol=1.0e-6)
```

See also: `Base.show(::IO, ::MIME"text/plain", ::StrategyOptions)`
"""
function Base.show(io::IO, opts::StrategyOptions)
    fmt = Core.get_format_codes(io)
    print(io, fmt.name, "StrategyOptions", fmt.reset, "(")
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
                fmt.reset for (k, v) in pairs(_raw_options(opts))
            ),
            ", ",
        ),
    )
    print(io, ")")
end
