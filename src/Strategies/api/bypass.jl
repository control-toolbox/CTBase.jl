# ============================================================================
# Bypass Mechanism for Explicit Option Validation
# ============================================================================

"""
$(TYPEDEF)

Wrapper type for option values that should bypass validation.

This type is used to explicitly skip validation for specific options when
constructing strategies. It is particularly useful for passing backend-specific
options that are not defined in the strategy's metadata.

# Fields
- `value::T`: The wrapped option value

# Example
```julia-repl
julia> val = bypass(42)
BypassValue(42)
```

See also: [`CTBase.Strategies.bypass`](@ref)
"""
struct BypassValue{T}
    value::T
end

"""
$(TYPEDSIGNATURES)

Mark an option value to bypass validation.

This function creates a `BypassValue` wrapper around the provided value.
When passed to a strategy constructor, this value will be accepted even if the
option name is unknown (not in metadata) or if validation would otherwise fail.

This can be combined with `route_to` to bypass validation for specific
strategies when routing ambiguous options.

# Arguments
- `val`: The option value to wrap

# Returns
- `BypassValue`: The wrapped value

# Example
```julia-repl
julia> using CTBase.Strategies

julia> # Pass an unknown option directly to strategy
julia> solver = Ipopt(
           max_iter=100, 
           custom_backend_option=bypass(42)  # Bypasses validation
       )
Ipopt(options=StrategyOptions{...})

julia> # Alternative syntax using force alias
julia> solver = Ipopt(
           max_iter=100, 
           custom_backend_option=force(42)  # Same as bypass(42)
       )
Ipopt(options=StrategyOptions{...})

julia> # Combine with routing for ambiguous options
julia> solve(ocp, method; 
           backend = route_to(ipopt=bypass(42))  # Route to ipopt AND bypass validation
       )
```

# Notes
- Use with caution! Bypassed options are passed directly to the backend.
- Typos in option names will not be caught by validation.
- Invalid values for the backend will cause backend-level errors.
- Can be combined with `route_to` for strategy-specific bypassing
- `force` is an alias for `bypass` - they are identical functions

See also: [`CTBase.Strategies.BypassValue`](@ref), [`CTBase.Strategies.route_to`](@ref), [`CTBase.Strategies.force`](@ref)
"""
bypass(val) = BypassValue(val)

"""
$(TYPEDSIGNATURES)

Force an option value to bypass validation.

This function is an alias for `bypass` and provides identical functionality.
The name `force` may be more intuitive for users who prefer "force" semantics
when bypassing validation.

# Arguments
- `val`: The option value to wrap

# Returns
- `BypassValue`: The wrapped value

# Example
```julia-repl
julia> using CTBase.Strategies

julia> # Force acceptance of unknown option
julia> solver = Ipopt(
           max_iter=100, 
           custom_backend_option=force(42)  # Forces validation bypass
       )
Ipopt(options=StrategyOptions{...})

julia> # Same as bypass(42)
julia> @test force(42) == bypass(42)
true
```

# Notes
- `force` and `bypass` are the same function: `force === bypass`
- Choose the name that best fits your mental model
- Both functions create `BypassValue` wrappers
- Use with caution for the same reasons as `bypass`

See also: [`CTBase.Strategies.BypassValue`](@ref), [`CTBase.Strategies.bypass`](@ref), [`CTBase.Strategies.route_to`](@ref)
"""
const force = bypass
