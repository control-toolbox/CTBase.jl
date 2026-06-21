# Strategy builders based on ResolvedMethod

"""
$(TYPEDSIGNATURES)

Return the option names for the active strategy of a given family in a resolved method.

This function is the resolved-method counterpart of strategy option introspection.
It avoids re-parsing the method tuple by using `resolved.ids_by_family` and the
global `resolved.parameter`.

# Arguments
- `resolved::ResolvedMethod`: Output of `resolve_method`
- `family_name::Symbol`: Family key in `families` (e.g. `:solver`, `:modeler`)
- `families::NamedTuple`: Mapping `family_name => family_type` used for resolution
- `registry::Strategies.StrategyRegistry`: Strategy registry

# Returns
- `Tuple{Vararg{Symbol}}`: Option names for the active strategy

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If the active strategy is parameterized but
  `resolved.parameter` is `nothing`

# Example
```julia
resolved = resolve_method(method, families, registry)
names = option_names_from_resolved(resolved, :solver, families, registry)
```

See also: `resolve_method`, `build_strategy_from_resolved`, `Strategies.option_names`
"""
function option_names_from_resolved(
    resolved::ResolvedMethod,
    family_name::Symbol,
    families::NamedTuple,
    registry::Strategies.StrategyRegistry,
)
    family_type = getfield(families, family_name)
    s_id = getfield(resolved.ids_by_family, family_name)
    param = resolved.parameter

    available = Strategies.available_parameters(s_id, family_type, registry)
    strategy_type = if isempty(available)
        Strategies.type_from_id(s_id, family_type, registry)
    else
        p = if param === nothing
            throw(
                Exceptions.IncorrectArgument(
                    "Missing parameter in resolved method";
                    got="strategy :$s_id in resolved method with parameter=nothing",
                    expected="a parameter type for parameterized strategies",
                    suggestion="Ensure resolve_method validated a parameter token for the method",
                    context="option_names_from_resolved - parameter required",
                ),
            )
        else
            (param::Type{<:Strategies.AbstractStrategyParameter})
        end
        Strategies.type_from_id(s_id, family_type, registry; parameter=p)
    end

    return Strategies.option_names(strategy_type)
end

"""
$(TYPEDSIGNATURES)

Build the active strategy instance of a given family from a resolved method.

This function is the resolved-method counterpart of strategy construction. It is
intended to be used after option routing, where the method tuple has already been
validated and resolved by `resolve_method`.

# Arguments
- `resolved::ResolvedMethod`: Output of `resolve_method`
- `family_name::Symbol`: Family key in `families` (e.g. `:solver`, `:modeler`)
- `families::NamedTuple`: Mapping `family_name => family_type` used for resolution
- `registry::Strategies.StrategyRegistry`: Strategy registry
- `mode::Symbol=:strict`: Validation mode for option extraction (`:strict` or `:permissive`)
- `kwargs...`: Options to pass to the strategy constructor

# Returns
- Concrete strategy instance for the selected ID (parameterized if required)

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If the active strategy is parameterized but
  `resolved.parameter` is `nothing`

# Example
```julia
resolved = resolve_method(method, families, registry)
solver = build_strategy_from_resolved(resolved, :solver, families, registry; mode=:strict, kwargs...)
```

See also: `resolve_method`, `Strategies.build_strategy`, `option_names_from_resolved`
"""
function build_strategy_from_resolved(
    resolved::ResolvedMethod,
    family_name::Symbol,
    families::NamedTuple,
    registry::Strategies.StrategyRegistry;
    mode::Symbol=:strict,
    kwargs...,
)
    family_type = getfield(families, family_name)
    s_id = getfield(resolved.ids_by_family, family_name)
    param = resolved.parameter

    available = Strategies.available_parameters(s_id, family_type, registry)
    if isempty(available)
        return Strategies.build_strategy(s_id, family_type, registry; mode=mode, kwargs...)
    end

    p = if param === nothing
        throw(
            Exceptions.IncorrectArgument(
                "Missing parameter in resolved method";
                got="strategy :$s_id in resolved method with parameter=nothing",
                expected="a parameter type for parameterized strategies",
                suggestion="Ensure resolve_method validated a parameter token for the method",
                context="build_strategy_from_resolved - parameter required",
            ),
        )
    else
        (param::Type{<:Strategies.AbstractStrategyParameter})
    end

    return Strategies.build_strategy(s_id, p, family_type, registry; mode=mode, kwargs...)
end
