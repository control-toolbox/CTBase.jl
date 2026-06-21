# ============================================================================
# Strategy Builders and Construction Utilities
# ============================================================================

"""
$(TYPEDSIGNATURES)

Build a strategy instance from its ID and options.

This function creates a concrete strategy instance by:
1. Looking up the strategy type from its ID in the registry
2. Constructing the instance with the provided options

# Arguments
- `id::Symbol`: Strategy identifier (e.g., `:adnlp`, `:ipopt`)
- `family::Type{<:AbstractStrategy}`: Abstract family type to search within
- `registry::StrategyRegistry`: Registry containing strategy mappings
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
- `kwargs...`: Options to pass to the strategy constructor

# Returns
- Concrete strategy instance of the appropriate type

# Throws
- `Exceptions.IncorrectArgument`: If the strategy ID is not found in the registry for the given family

# Example
```julia-repl
julia> registry = create_registry(
           AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa)
       )

julia> modeler = build_strategy(:adnlp, AbstractNLPModeler, registry; backend=:sparse)
Modelers.ADNLP(options=StrategyOptions{...})

julia> modeler = build_strategy(:adnlp, AbstractNLPModeler, registry; 
           backend=:sparse, mode=:permissive)
Modelers.ADNLP(options=StrategyOptions{...})
```

See also: `type_from_id`
"""
function build_strategy(
    id::Symbol,
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry;
    mode::Symbol=:strict,
    kwargs...,
)
    T = type_from_id(id, family, registry)
    return T(; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Build a parameterized strategy instance from ID, parameter, and options.

This function creates a concrete parameterized strategy instance by:
1. Looking up the parameterized strategy type from its ID and parameter
2. Constructing the instance with the provided options

# Arguments
- `id::Symbol`: Strategy identifier (e.g., `:madnlp`)
- `parameter::Type{<:AbstractStrategyParameter}`: Parameter type (e.g., `GPU`)
- `family::Type{<:AbstractStrategy}`: Abstract family type to search within
- `registry::StrategyRegistry`: Registry containing strategy mappings
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
- `kwargs...`: Options to pass to the strategy constructor

# Returns
- Concrete parameterized strategy instance (e.g., `MadNLP{GPU}`)

# Throws
- `CTBase.Exceptions.IncorrectArgument`: If the strategy-parameter combination is not found

# Example
```julia-repl
julia> registry = create_registry(
           AbstractNLPSolver => ((MadNLP, [CPU, GPU]),)
       )

julia> solver = build_strategy(:madnlp, GPU, AbstractNLPSolver, registry; max_iter=1000)
MadNLP{GPU}(options=StrategyOptions{...})
```

See also: `build_strategy`
"""
function build_strategy(
    id::Symbol,
    parameter::Type{<:AbstractStrategyParameter},
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry;
    mode::Symbol=:strict,
    kwargs...,
)
    T = type_from_id(id, family, registry; parameter=parameter)
    return T(; mode=mode, kwargs...)
end

"""
$(TYPEDSIGNATURES)

Extract the strategy ID for a specific family from a method tuple.

A method tuple contains multiple strategy IDs (e.g., `(:collocation, :adnlp, :ipopt)`).
This function identifies which ID corresponds to the requested family.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Tuple of strategy IDs
- `family::Type{<:AbstractStrategy}`: Abstract family type to search for
- `registry::StrategyRegistry`: Registry containing strategy mappings

# Returns
- `Symbol`: The ID corresponding to the requested family

# Throws
- `Exceptions.IncorrectArgument`: If no ID or multiple IDs are found for the family

# Example
```julia-repl
julia> method = (:collocation, :adnlp, :ipopt)

julia> extract_id_from_method(method, AbstractNLPModeler, registry)
:adnlp

julia> extract_id_from_method(method, AbstractNLPSolver, registry)
:ipopt
```

See also: `strategy_ids`
"""
function extract_id_from_method(
    method::Tuple{Vararg{Symbol}},
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry,
)
    allowed = strategy_ids(family, registry)
    found::Union{Nothing,Symbol} = nothing
    n_hits::Int = 0

    for s in method
        if s in allowed
            n_hits += 1
            if found === nothing
                found = s
            end
        end
    end

    if n_hits == 1
        return (found::Symbol)
    elseif n_hits == 0
        throw(
            Exceptions.IncorrectArgument(
                "No strategy ID found for family in method";
                got="family $family in method $method",
                expected="family ID present in method tuple",
                suggestion="Add the family ID to your method tuple, e.g., (:$family, ...)",
                context="extract_id_from_method - validating method tuple contains family",
            ),
        )
    else
        throw(
            Exceptions.IncorrectArgument(
                "Multiple strategy IDs found for family in method";
                got="family $family appears $n_hits times in method $method",
                expected="exactly one ID per family in method tuple",
                suggestion="Remove duplicate family IDs from method tuple, keep only one",
                context="extract_id_from_method - validating unique family IDs",
            ),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Internal helper returning the set of all registered strategy IDs.

This function is used by registry utilities that need to distinguish strategy
tokens from other tokens that may appear in a method tuple (e.g. parameter
tokens).

# Arguments
- `registry::StrategyRegistry`: Strategy registry.

# Returns
- `Set{Symbol}`: Set of all strategy IDs present in the registry.

# Notes
- This function is internal and not part of the public API.
"""
function _strategy_id_set(registry::StrategyRegistry)
    ids = Set{Symbol}()
    for strategies in values(registry.families)
        for T in strategies
            push!(ids, id(T))
        end
    end
    return ids
end

"""
$(TYPEDSIGNATURES)

Return all available strategy parameter types for a given `(strategy_id, family)`.

This function is used by orchestration to validate that a global parameter token
present in the method tuple is compatible with all selected strategies.

# Arguments
- `strategy_id::Symbol`: Strategy identifier (e.g. `:madnlp`).
- `family::Type{<:AbstractStrategy}`: Family to search within.
- `registry::StrategyRegistry`: Strategy registry.

# Returns
- `Vector{Type{<:AbstractStrategyParameter}}`: Supported parameter types. Returns
  an empty vector if the strategy is not parameterized.

See also: `extract_global_parameter_from_method`, `get_parameter_type`
"""
function available_parameters(
    strategy_id::Symbol, family::Type{<:AbstractStrategy}, registry::StrategyRegistry
)
    params = Type{<:AbstractStrategyParameter}[]
    for T in registry.families[family]
        if id(T) === strategy_id
            P = get_parameter_type(T)
            if P !== nothing
                push!(params, P::Type{<:AbstractStrategyParameter})
            end
        end
    end
    return params
end

"""
$(TYPEDSIGNATURES)

Extract the global strategy parameter from a method tuple.

The method tuple may contain at most one parameter token (e.g. `:cpu`, `:gpu`).
If present, it is resolved to a parameter type using `registry.parameters`.

If any of the selected strategies in the method are parameterized, then a
parameter token is required and must be supported by each parameterized strategy.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Method tuple containing strategy IDs and
  optionally one parameter token.
- `registry::StrategyRegistry`: Strategy registry.

# Returns
- `Union{Nothing, Type{<:AbstractStrategyParameter}}`: The extracted parameter
  type, or `nothing` if none is present.

# Throws
- `Exceptions.IncorrectArgument`: If more than one parameter token is present,
  if a parameter is missing but required, if a parameter is unsupported, or if a
  parameter token is provided but no selected strategy is parameterized.

See also: `available_parameters`, `Strategies.AbstractStrategyParameter`
"""
function extract_global_parameter_from_method(
    method::Tuple{Vararg{Symbol}}, registry::StrategyRegistry
)
    param_map = registry.parameters
    param_tokens = Symbol[s for s in method if haskey(param_map, s)]
    if length(param_tokens) > 1
        throw(
            Exceptions.IncorrectArgument(
                "Multiple parameters found in method";
                got="method $method",
                expected="at most one global parameter token",
                suggestion="Remove extra parameter tokens; keep a single one like :cpu or :gpu",
                context="extract_global_parameter_from_method - validating unique global parameter",
            ),
        )
    end
    param = isempty(param_tokens) ? nothing : param_map[param_tokens[1]]

    strategy_ids = _strategy_id_set(registry)
    selected_strategy_ids = Symbol[s for s in method if s in strategy_ids]

    any_parameterized = false
    for (family, _) in registry.families
        for s_id in selected_strategy_ids
            available = available_parameters(s_id, family, registry)
            if !isempty(available)
                any_parameterized = true
                if param === nothing
                    throw(
                        Exceptions.IncorrectArgument(
                            "Missing parameter in method";
                            got="method $method",
                            expected="a global parameter token for parameterized strategies",
                            suggestion="Add :cpu or :gpu to your method tuple",
                            context="extract_global_parameter_from_method - parameter required",
                        ),
                    )
                end
                if !(param in available)
                    available_ids = Tuple(id(p) for p in available)
                    throw(
                        Exceptions.IncorrectArgument(
                            "Unsupported parameter in method";
                            got="strategy :$s_id with parameter $(id(param)) in method $method",
                            expected="strategy :$s_id with one of: $available_ids",
                            suggestion="Use one of: $available_ids",
                            context="extract_global_parameter_from_method - validating parameter support",
                        ),
                    )
                end
            end
        end
    end

    if param !== nothing && !any_parameterized
        throw(
            Exceptions.IncorrectArgument(
                "Useless parameter in method";
                got="method $method with parameter $(id(param))",
                expected="parameter token to be accepted by at least one selected strategy",
                suggestion="Remove the parameter token or select a strategy that accepts it",
                context="extract_global_parameter_from_method - unused parameter",
            ),
        )
    end

    return param
end
