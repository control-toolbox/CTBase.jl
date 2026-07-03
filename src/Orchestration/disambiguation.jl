# Disambiguation helpers for strategy-based option routing

"""
$(TYPEDEF)

Resolved representation of a method tuple for strategy-aware option routing.

`ResolvedMethod` contains precomputed lookups derived from a `method` tuple and a
set of `families`. It is intended to be created via `resolve_method` and
then reused by routing and builder utilities.

# Fields
- `tokens::T`: The original method tokens.
- `ids_by_family::I`: Family-wise strategy IDs extracted from `tokens`.
- `strategy_to_family::Dict{Symbol, Symbol}`: Reverse map `strategy_id => family_name`.
- `strategy_ids::Tuple{Vararg{Symbol}}`: Tuple of active strategy IDs.
- `parameter::Union{Nothing, Type{<:Strategies.AbstractStrategyParameter}}`: Optional global
  parameter extracted from the method tuple.

# Notes
- This type is internal to `CTBase.Orchestration`.

See also: [`CTBase.Orchestration.resolve_method`](@ref), [`CTBase.Orchestration.route_all_options`](@ref)
"""
struct ResolvedMethod{T<:Tuple,I<:NamedTuple}
    tokens::T
    ids_by_family::I
    strategy_to_family::Dict{Symbol,Symbol}
    strategy_ids::Tuple{Vararg{Symbol}}
    parameter::Union{Nothing,Type{<:Strategies.AbstractStrategyParameter}}
end

"""
$(TYPEDSIGNATURES)

Resolve a method tuple into a `ResolvedMethod` for routing and builders.

This function extracts one strategy ID per family (using the `Strategies` contract),
builds reverse lookup maps, and extracts a global strategy parameter (if present).

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Method tokens, e.g. `(:collocation, :adnlp, :ipopt)`.
- `families::NamedTuple`: Mapping `family_name => family_type` used for ID extraction.
- `registry::Strategies.StrategyRegistry`: Strategy registry.

# Returns
- `ResolvedMethod`: Precomputed lookups derived from `method`.

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If a family strategy ID cannot be extracted from `method`.

# Example
```julia
resolved = resolve_method(method, families, registry)
resolved.strategy_ids
```

See also: [`CTBase.Orchestration.extract_strategy_ids`](@ref), [`CTBase.Orchestration.build_strategy_to_family_map`](@ref)
"""
function resolve_method(
    method::Tuple{Vararg{Symbol}},
    families::NamedTuple,
    registry::Strategies.StrategyRegistry,
)::ResolvedMethod
    ids_by_family = NamedTuple{keys(families)}(
        Tuple(
            Strategies.extract_id_from_method(method, family_type, registry) for
            (family_name, family_type) in pairs(families)
        ),
    )

    strategy_to_family = Dict{Symbol,Symbol}(
        getfield(ids_by_family, family_name) => family_name for
        family_name in keys(ids_by_family)
    )

    strategy_ids = Tuple(
        getfield(ids_by_family, family_name) for family_name in keys(ids_by_family)
    )

    parameter = Strategies.extract_global_parameter_from_method(method, registry)

    return ResolvedMethod(
        method, ids_by_family, strategy_to_family, strategy_ids, parameter
    )
end

"""
$(TYPEDSIGNATURES)

Extract strategy IDs from a routed option.

This function processes a `RoutedOption` created by `route_to` and
validates that all specified strategy IDs are present in the method tuple.

# Arguments
- `raw::Strategies.RoutedOption`: The routed option to process
- `resolved::ResolvedMethod`: Resolved method information (active strategy IDs)

# Returns
- `Vector{Tuple{Any, Symbol}}`: Vector of (value, strategy_id) pairs

# Throws
- `Exceptions.IncorrectArgument`: If a strategy ID in the routed option
  is not present in the method tuple

# Example
```julia
resolved = resolve_method(method, families, registry)
routed = route_to(solver=100, modeler=50)
ids = extract_strategy_ids(routed, resolved)
```

See also: [`CTBase.Strategies.route_to`](@ref), [`CTBase.Strategies.RoutedOption`](@ref), [`CTBase.Orchestration.extract_strategy_ids`](@ref)
"""
function extract_strategy_ids(
    raw::Strategies.RoutedOption, resolved::ResolvedMethod
)::Vector{Tuple{Any,Symbol}}
    results = Tuple{Any,Symbol}[]
    for (strategy_id, value) in pairs(raw)
        if strategy_id in resolved.strategy_ids
            push!(results, (value, strategy_id))
        else
            throw(
                Exceptions.IncorrectArgument(
                    "Strategy ID not found in method tuple";
                    got="strategy ID :$strategy_id",
                    expected="one of available strategy IDs: $(resolved.tokens)",
                    suggestion="Use a valid strategy ID from your method tuple",
                    context="extract_strategy_ids - validating RoutedOption strategy ID",
                ),
            )
        end
    end
    return results
end

# Strategy-to-family mapping

"""
$(TYPEDSIGNATURES)

Build a mapping from strategy IDs to family names.

This helper function creates a reverse lookup dictionary that maps each
strategy ID in the method to its corresponding family name. This is used
by the routing system to determine which family owns each strategy.

# Arguments
- `resolved::ResolvedMethod`: Resolved method information (active strategy IDs)
- `families::NamedTuple`: NamedTuple mapping family names to abstract types
- `registry::Strategies.StrategyRegistry`: Strategy registry

# Returns
- `Dict{Symbol, Symbol}`: Dictionary mapping strategy ID => family name

# Example
```julia
resolved = resolve_method(method, families, registry)
map = build_strategy_to_family_map(resolved, families, registry)
```

See also: [`CTBase.Orchestration.build_option_ownership_map`](@ref), [`CTBase.Orchestration.extract_strategy_ids`](@ref)
"""
function build_strategy_to_family_map(
    resolved::ResolvedMethod, families::NamedTuple, registry::Strategies.StrategyRegistry
)::Dict{Symbol,Symbol}
    return copy(resolved.strategy_to_family)
end

# Option ownership map

"""
$(TYPEDSIGNATURES)

Build a mapping from option names to the families that own them.

This function analyzes the metadata of all strategies in the method to
determine which family (or families) define each option. Options that
appear in multiple families are considered ambiguous and require
disambiguation.

# Arguments
- `resolved::ResolvedMethod`: Resolved method information (active strategies)
- `families::NamedTuple`: NamedTuple mapping family names to abstract types
- `registry::Strategies.StrategyRegistry`: Strategy registry

# Returns
- `Dict{Symbol, Set{Symbol}}`: Dictionary mapping option_name =>
  Set{family_name}

# Example
```julia
resolved = resolve_method(method, families, registry)
map = build_option_ownership_map(resolved, families, registry)
```

# Notes
- Options appearing in only one family can be auto-routed
- Options appearing in multiple families require disambiguation syntax
- Options not appearing in any family will trigger an error during routing

See also: [`CTBase.Orchestration.build_strategy_to_family_map`](@ref), [`CTBase.Orchestration.route_all_options`](@ref)
"""
function build_option_ownership_map(
    resolved::ResolvedMethod, families::NamedTuple, registry::Strategies.StrategyRegistry
)::Dict{Symbol,Set{Symbol}}
    option_owners = Dict{Symbol,Set{Symbol}}()

    for (family_name, family_type) in pairs(families)
        id = getfield(resolved.ids_by_family, family_name)
        strategy_type = Strategies.type_from_id(id, family_type, registry)
        meta = Strategies.metadata(strategy_type)

        for (primary_name, def) in pairs(meta)
            if !haskey(option_owners, primary_name)
                option_owners[primary_name] = Set{Symbol}()
            end
            push!(option_owners[primary_name], family_name)

            for alias in def.aliases
                if !haskey(option_owners, alias)
                    option_owners[alias] = Set{Symbol}()
                end
                push!(option_owners[alias], family_name)
            end
        end
    end

    return option_owners
end

"""
$(TYPEDSIGNATURES)

Extract strategy IDs from a non-routed option.

This fallback method handles option values that do not use disambiguation syntax.
It returns `nothing` to indicate that no routing information is present.

# Arguments
- `raw`: The raw option value to analyze (any type)
- `resolved::ResolvedMethod`: Resolved method information (unused in this method)

# Returns
- `nothing`: Always returns `nothing` since no disambiguation syntax is detected

# Example
```julia
resolved = resolve_method(method, families, registry)
result = extract_strategy_ids(100, resolved)  # Returns nothing
```

See also: [`CTBase.Orchestration.extract_strategy_ids`](@ref), [`CTBase.Strategies.route_to`](@ref)
"""
function extract_strategy_ids(raw, resolved::ResolvedMethod)::Nothing
    return nothing
end

"""
$(TYPEDSIGNATURES)

Build a mapping from alias names to their primary option names for all strategies in the method.

# Arguments
- `resolved::ResolvedMethod`: Resolved method information (active strategies)
- `families::NamedTuple`: NamedTuple mapping family names to abstract types
- `registry::Strategies.StrategyRegistry`: Strategy registry

# Returns
- `Dict{Symbol, Symbol}`: Dictionary mapping `alias => primary_name`

# Example
```julia
resolved = resolve_method(method, families, registry)
alias_map = build_alias_to_primary_map(resolved, families, registry)
```

See also: [`CTBase.Orchestration.build_option_ownership_map`](@ref), [`CTBase.Orchestration.resolve_method`](@ref)

"""
function build_alias_to_primary_map(
    resolved::ResolvedMethod, families::NamedTuple, registry::Strategies.StrategyRegistry
)::Dict{Symbol,Symbol}
    alias_map = Dict{Symbol,Symbol}()

    for (family_name, family_type) in pairs(families)
        id = getfield(resolved.ids_by_family, family_name)
        strategy_type = Strategies.type_from_id(id, family_type, registry)
        meta = Strategies.metadata(strategy_type)

        for (primary_name, def) in pairs(meta)
            for alias in def.aliases
                alias_map[alias] = primary_name
            end
        end
    end

    return alias_map
end
