# ============================================================================
# Option disambiguation helpers
# ============================================================================

# ----------------------------------------------------------------------------
# Routed Option Type
# ----------------------------------------------------------------------------

"""
$(TYPEDEF)

Routed option value with explicit strategy targeting.

This type is created by `route_to` to disambiguate options that exist
in multiple strategies. It wraps one or more (strategy_id => value) pairs,
allowing the orchestration layer to route each value to its intended strategy.

# Fields
- `routes::NamedTuple`: NamedTuple of strategy_id => value mappings

# Iteration
`RoutedOption` implements the collection interface and can be iterated like a dictionary:
- `keys(opt)`: Strategy IDs
- `values(opt)`: Option values  
- `pairs(opt)`: (strategy_id, value) pairs
- `for (id, val) in opt`: Direct iteration over pairs
- `opt[:strategy]`: Index by strategy ID
- `haskey(opt, :strategy)`: Check if strategy exists
- `length(opt)`: Number of routes

# Example
```julia-repl
julia> using CTBase.Strategies

julia> # Single strategy
julia> opt = route_to(solver=100)
RoutedOption((solver = 100,))

julia> # Multiple strategies
julia> opt = route_to(solver=100, modeler=50)
RoutedOption((solver = 100, modeler = 50))

julia> # Iterate over routes
julia> for (id, val) in opt
           println("\$id => \$val")
       end
solver => 100
modeler => 50
```

See also: `route_to`
"""
struct RoutedOption
    routes::NamedTuple

    function RoutedOption(routes::NamedTuple)
        if isempty(routes)
            throw(
                Exceptions.PreconditionError(
                    "RoutedOption requires at least one route";
                    reason="empty routes NamedTuple provided",
                    suggestion="Use route_to(strategy=value) to create a routed option",
                    context="RoutedOption constructor precondition",
                ),
            )
        end
        return new(routes)
    end
end

"""
$(TYPEDSIGNATURES)

Validate a NamedTuple of routes and wrap it in a `RoutedOption`.

Throws `PreconditionError` if `routes` is empty.
"""
function _route_to_from_namedtuple(routes::NamedTuple)
    if isempty(routes)
        throw(
            Exceptions.PreconditionError(
                "route_to requires at least one strategy-value pair";
                reason="empty routes NamedTuple provided",
                suggestion="Use route_to(solver=100) or route_to(:solver, 100)",
                context="route_to - internal helper precondition",
            ),
        )
    end
    return RoutedOption(routes)
end

"""
$(TYPEDSIGNATURES)

Create a disambiguated option value by explicitly routing it to specific strategies.

This function resolves ambiguity when the same option name exists in multiple
strategies (e.g., both modeler and solver have `max_iter`). It creates a
`RoutedOption` that tells the orchestration layer exactly which strategy
should receive which value.

# Arguments
- `kwargs...`: Named arguments where keys are strategy identifiers (`:solver`, `:modeler`, etc.)
  and values are the option values to route to those strategies

# Returns
- `RoutedOption`: A routed option containing the strategy => value mappings

# Throws
- `Exceptions.PreconditionError`: If no strategies are provided

# Example
```julia-repl
julia> using CTBase.Strategies

julia> # Single strategy
julia> route_to(solver=100)
RoutedOption((solver = 100,))

julia> # Multiple strategies with different values
julia> route_to(solver=100, modeler=50)
RoutedOption((solver = 100, modeler = 50))

julia> # Alternative positional syntax
julia> route_to(:solver, 100, :modeler, 50)
RoutedOption((solver = 100, modeler = 50))
```

# Usage in solve()
```julia
# Without disambiguation - error if max_iter exists in multiple strategies
solve(ocp, method; max_iter=100)  # ❌ Ambiguous!

# With disambiguation - explicit routing (keyword syntax)
solve(ocp, method;
    max_iter = route_to(solver=100)              # Only solver gets 100
)

solve(ocp, method;
    max_iter = route_to(solver=100, modeler=50)  # Different values for each
)

# With disambiguation - explicit routing (positional syntax)
solve(ocp, method;
    max_iter = route_to(:solver, 100, :modeler, 50)  # Different values for each
)
```

# Notes
- Strategy identifiers must match the actual strategy IDs in your method tuple
- You can route to one or multiple strategies in a single call
- Alternative positional syntax: `route_to(:solver, 100, :modeler, 50)`
- Both syntaxes are equivalent; choose based on preference
- This is the recommended way to disambiguate options
- The orchestration layer will validate that the strategy IDs exist

See also: `RoutedOption`, `route_all_options`
"""
function route_to(; kwargs...)
    return _route_to_from_namedtuple(NamedTuple(kwargs))
end

"""
$(TYPEDSIGNATURES)

Create a disambiguated option value using positional arguments.

This is an alternative syntax to the keyword argument version. Accepts
alternating strategy identifier (Symbol) and value pairs.

# Arguments
- `args::Vararg{Any}`: Alternating strategy_id (Symbol) and value pairs.
  Must have an even number of arguments. Odd-numbered arguments must be Symbols.

# Returns
- `RoutedOption`: A routed option containing the strategy => value mappings

# Throws
- `Exceptions.PreconditionError`: If no arguments provided, odd number of arguments,
  or odd-numbered arguments are not Symbols

# Example
```julia-repl
julia> using CTBase.Strategies

julia> # Single strategy
julia> route_to(:solver, 100)
RoutedOption((solver = 100,))

julia> # Multiple strategies
julia> route_to(:solver, 100, :modeler, 50)
RoutedOption((solver = 100, modeler = 50))
```

# Notes
- This is equivalent to the keyword syntax: `route_to(solver=100, modeler=50)`
- Strategy identifiers must be Symbols (e.g., `:solver`, not `"solver"`)
- The number of arguments must be even (pairs of Symbol-value)

See also: `route_to(; kwargs...)`, `RoutedOption`
"""
function route_to(args::Vararg{Any})
    # Validate at least one pair
    if isempty(args)
        throw(
            Exceptions.PreconditionError(
                "route_to requires at least one strategy-value pair";
                reason="no arguments provided",
                suggestion="Use route_to(:solver, 100) or route_to(:solver, 100, :modeler, 50)",
                context="route_to - positional syntax precondition",
            ),
        )
    end

    # Validate even number of arguments (each Symbol must have a value)
    if length(args) % 2 != 0
        throw(
            Exceptions.PreconditionError(
                "route_to requires an even number of arguments (Symbol-value pairs)";
                got="$(length(args)) arguments (odd number)",
                expected="even number of arguments (e.g., 2 for one strategy, 4 for two strategies)",
                suggestion="Ensure each strategy Symbol has a corresponding value: route_to(:solver, 100) or route_to(:solver, 100, :modeler, 50)",
                context="route_to - positional syntax precondition",
            ),
        )
    end

    # Build NamedTuple from pairs
    pairs = NamedTuple()
    for i in 1:2:length(args)
        strategy_id = args[i]
        value = args[i + 1]

        # Validate strategy_id is a Symbol
        if !(strategy_id isa Symbol)
            throw(
                Exceptions.PreconditionError(
                    "Strategy identifier must be a Symbol";
                    got="strategy_id = $strategy_id (type: $(typeof(strategy_id)))",
                    expected="Symbol (e.g., :solver, :modeler)",
                    suggestion="Use Symbols for strategy identifiers: route_to(:solver, 100)",
                    context="route_to - positional syntax precondition",
                ),
            )
        end

        pairs = merge(pairs, NamedTuple{(strategy_id,)}((value,)))
    end

    # Delegate to internal helper
    return _route_to_from_namedtuple(pairs)
end

# ============================================================================
# Collection Interface for RoutedOption
# ============================================================================

"""
$(TYPEDSIGNATURES)

Return an iterator over the strategy IDs in the routed option.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> collect(keys(opt))
2-element Vector{Symbol}:
 :solver
 :modeler
```
"""
Base.keys(r::RoutedOption) = keys(r.routes)

"""
$(TYPEDSIGNATURES)

Return an iterator over the values in the routed option.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> collect(values(opt))
2-element Vector{Int64}:
 100
  50
```
"""
Base.values(r::RoutedOption) = values(r.routes)

"""
$(TYPEDSIGNATURES)

Return an iterator over (strategy_id => value) pairs.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> for (id, val) in pairs(opt)
           println("\$id => \$val")
       end
solver => 100
modeler => 50
```
"""
Base.pairs(r::RoutedOption) = pairs(r.routes)

"""
$(TYPEDSIGNATURES)

Iterate over (strategy_id => value) pairs.

This allows direct iteration: `for (id, val) in routed_option`.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> for (id, val) in opt
           println("\$id => \$val")
       end
solver => 100
modeler => 50
```
"""
Base.iterate(r::RoutedOption, state...) = iterate(pairs(r.routes), state...)

"""
$(TYPEDSIGNATURES)

Return the number of routes in the routed option.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> length(opt)
2
```
"""
Base.length(r::RoutedOption) = length(r.routes)

"""
$(TYPEDSIGNATURES)

Check if a strategy ID exists in the routed option.

# Example
```julia-repl
julia> opt = route_to(solver=100)
julia> haskey(opt, :solver)
true
julia> haskey(opt, :modeler)
false
```
"""
Base.haskey(r::RoutedOption, key::Symbol) = haskey(r.routes, key)

"""
$(TYPEDSIGNATURES)

Get the value for a specific strategy ID.

# Example
```julia-repl
julia> opt = route_to(solver=100, modeler=50)
julia> opt[:solver]
100
julia> opt[:modeler]
50
```
"""
Base.getindex(r::RoutedOption, key::Symbol) = r.routes[key]
