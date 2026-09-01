# ============================================================================
# Strategy registry for explicit dependency management
# ============================================================================

"""
$(TYPEDEF)

Registry mapping strategy families to their concrete types.

This type provides an explicit, immutable registry for managing strategy types
organized by family. It enables:
- **Type lookup by ID**: Find concrete types from symbolic identifiers
- **Family introspection**: List all strategies in a family
- **Validation**: Ensure ID uniqueness and type hierarchy correctness

# Design Philosophy

The registry uses an **explicit passing pattern** rather than global mutable state:
- Created once via `create_registry`
- Passed explicitly to functions that need it
- Thread-safe (no shared mutable state)
- Testable (easy to create multiple registries)

# Fields
- `families::Dict{Type{<:AbstractStrategy}, Vector{Type}}`: Maps abstract family types to concrete strategy types

# Example
```julia-repl
julia> using CTBase: Strategies

julia> registry = Strategies.create_registry(
           AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa),
           AbstractNLPSolver => (Solvers.Ipopt, Solvers.MadNLP)
       )
StrategyRegistry with 2 families

julia> Strategies.strategy_ids(AbstractNLPModeler, registry)
(:adnlp, :exa)

julia> T = Strategies.type_from_id(:adnlp, AbstractNLPModeler, registry)
Modelers.ADNLP
```

See also: [`CTBase.Strategies.create_registry`](@extref), [`CTBase.Strategies.strategy_ids`](@extref), [`CTBase.Strategies.type_from_id`](@extref), `Base.merge`
"""
struct StrategyRegistry
    families::Dict{Type{<:AbstractStrategy},Vector{Type}}
    parameters::Dict{Symbol,Type{<:AbstractStrategyParameter}}
end

"""
$(TYPEDSIGNATURES)

Create a strategy registry from family-to-strategies mappings.

This function validates the registry structure and ensures:
- All strategy IDs are unique within each family
- All strategies are subtypes of their declared family
- No duplicate family definitions

# Arguments
- `pairs...`: Pairs of family type => tuple of strategy types

# Returns
- `StrategyRegistry`: Validated registry ready for use

# Validation Rules

- **ID Uniqueness**: Within each family, all strategy `id()` values must be unique
- **Type Hierarchy**: Each strategy must be a subtype of its family
- **No Duplicates**: Each family can only appear once in the registry

# Example
```julia-repl
julia> using CTBase: Strategies

julia> registry = Strategies.create_registry(
           AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa),
           AbstractNLPSolver => (Solvers.Ipopt, Solvers.MadNLP, Solvers.Knitro)
       )
StrategyRegistry with 2 families

julia> Strategies.strategy_ids(AbstractNLPModeler, registry)
(:adnlp, :exa)
```

# Throws
- `ErrorException`: If duplicate IDs are found within a family
- `ErrorException`: If a strategy is not a subtype of its family
- `ErrorException`: If a family appears multiple times

See also: [`CTBase.Strategies.StrategyRegistry`](@extref), [`CTBase.Strategies.strategy_ids`](@extref), [`CTBase.Strategies.type_from_id`](@extref), `Base.merge`
"""
function create_registry(pairs::Pair...)
    families = Dict{Type{<:AbstractStrategy},Vector{Type}}()

    # IMPORTANT: Collect all strategy IDs for GLOBAL uniqueness validation
    # Parameter IDs can be reused across different strategies (same CPU parameter for Exa, MadNLP, etc.)
    all_strategy_ids = Set{Symbol}()

    # IMPORTANT: Parameter IDs must be globally unique across parameter types
    # (and must not conflict with strategy IDs).
    parameter_id_to_type = Dict{Symbol,Type{<:AbstractStrategyParameter}}()

    # Validate that all pairs have the correct structure
    for pair in pairs
        family, strategies = pair
        if !(family isa DataType && family <: AbstractStrategy)
            throw(
                Exceptions.IncorrectArgument(
                    "Invalid strategy family type";
                    got="family=$family of type $(typeof(family))",
                    expected="DataType subtype of AbstractStrategy",
                    suggestion="Use a valid AbstractStrategy subtype as the family type",
                    context="StrategyRegistry constructor - validating family types",
                ),
            )
        end
        if !(strategies isa Tuple)
            throw(
                Exceptions.IncorrectArgument(
                    "Invalid strategies format";
                    got="strategies of type $(typeof(strategies))",
                    expected="Tuple of strategy types or (Type, [Param1, Param2, ...]) tuples",
                    suggestion="Provide strategies as a tuple, e.g., (Strategy1, Strategy2) or (Strategy, [Param1, Param2])",
                    context="StrategyRegistry constructor - validating strategies format",
                ),
            )
        end
    end

    for (family, strategy_list) in pairs
        # Check for duplicate family
        if haskey(families, family)
            throw(
                Exceptions.IncorrectArgument(
                    "Duplicate family registration";
                    got="family $family already registered",
                    expected="unique family types in registry",
                    suggestion="Remove duplicate family or use a different family type",
                    context="StrategyRegistry constructor - checking family uniqueness",
                ),
            )
        end

        strategies = Type[]

        for item in strategy_list
            if item isa Tuple
                # Parameterized strategy: (Type, [Param1, Param2, ...])
                strategy_type, param_types = item

                # Validate strategy type (can be DataType or UnionAll for parameterized types)
                if !(
                    strategy_type isa UnionAll ||
                    (strategy_type isa DataType && strategy_type <: AbstractStrategy)
                )
                    throw(
                        Exceptions.IncorrectArgument(
                            "Invalid strategy type in parameterized tuple";
                            got="strategy_type=$strategy_type of type $(typeof(strategy_type))",
                            expected="UnionAll or DataType subtype of AbstractStrategy",
                            suggestion="Use a valid AbstractStrategy subtype, e.g., (MyStrategy, [CPU, GPU])",
                            context="create_registry - validating parameterized strategy type",
                        ),
                    )
                end

                # Validate parameter types
                if !(param_types isa Tuple || param_types isa Vector)
                    throw(
                        Exceptions.IncorrectArgument(
                            "Invalid parameter types in parameterized tuple";
                            got="param_types=$param_types of type $(typeof(param_types))",
                            expected="Tuple or Vector of parameter types",
                            suggestion="Use (MyStrategy, [CPU, GPU]) or (MyStrategy, (CPU, GPU))",
                            context="create_registry - validating parameter types",
                        ),
                    )
                end

                # Check GLOBAL uniqueness of strategy ID
                strategy_id = id(strategy_type)
                if strategy_id in all_strategy_ids
                    throw(
                        Exceptions.IncorrectArgument(
                            "Duplicate ID detected";
                            got="ID :$strategy_id used multiple times",
                            expected="unique IDs across all strategies and parameters",
                            suggestion="Ensure each strategy and parameter has a unique id()",
                            context="create_registry - validating global ID uniqueness",
                        ),
                    )
                end
                push!(all_strategy_ids, strategy_id)

                # Check parameter types and create parameterized types
                # Parameters can be reused across different strategies (same CPU for Exa, MadNLP, etc.)
                for param_type in param_types
                    if !(param_type isa DataType && param_type <: AbstractStrategyParameter)
                        throw(
                            Exceptions.IncorrectArgument(
                                "Invalid parameter type";
                                got="parameter_type=$param_type of type $(typeof(param_type))",
                                expected="DataType subtype of AbstractStrategyParameter",
                                suggestion="Use valid parameter types like CPU, GPU",
                                context="create_registry - validating parameter type",
                            ),
                        )
                    end

                    # Check that parameter ID doesn't conflict with strategy IDs
                    param_id = id(param_type)
                    if param_id in all_strategy_ids
                        throw(
                            Exceptions.IncorrectArgument(
                                "Parameter ID conflicts with strategy ID";
                                got="parameter ID :$param_id conflicts with strategy ID",
                                expected="parameter IDs different from all strategy IDs",
                                suggestion="Choose different parameter IDs or strategy IDs",
                                context="create_registry - validating parameter/strategy ID conflicts",
                            ),
                        )
                    end

                    # Check GLOBAL uniqueness of parameter IDs across parameter types
                    if haskey(parameter_id_to_type, param_id)
                        existing = parameter_id_to_type[param_id]
                        if existing != param_type
                            throw(
                                Exceptions.IncorrectArgument(
                                    "Duplicate parameter ID detected";
                                    got="parameter ID :$param_id used by both $existing and $param_type",
                                    expected="unique IDs across all parameter types",
                                    suggestion="Ensure each parameter type has a unique id()",
                                    context="create_registry - validating global parameter ID uniqueness",
                                ),
                            )
                        end
                    else
                        parameter_id_to_type[param_id] = (
                            param_type::Type{<:AbstractStrategyParameter}
                        )
                    end

                    # Create parameterized strategy type. The strategy parameter must be
                    # the FIRST declared type parameter — every `Strategies.parameter`
                    # implementation in the ecosystem reads slot 1 via
                    # `parameter(::Type{<:X{P}}) where {P} = P`. Round-trip through that
                    # contract method to validate the binding actually landed there,
                    # rather than inspecting TypeVar positions/bounds by hand.
                    applied_type = try
                        strategy_type{param_type}
                    catch e
                        e isa TypeError || rethrow()
                        throw(
                            Exceptions.IncorrectArgument(
                                "Strategy parameter is not compatible with the first type parameter";
                                got="$strategy_type applied to $param_type",
                                expected="$param_type to satisfy the bound of $strategy_type's first type parameter",
                                suggestion="Declare the strategy parameter as the FIRST type parameter, e.g. struct $strategy_type{P<:AbstractStrategyParameter, ...}",
                                context="create_registry - binding strategy parameter to type",
                            ),
                        )
                    end

                    bound_param = try
                        parameter(applied_type)
                    catch
                        nothing
                    end
                    if bound_param !== param_type
                        throw(
                            Exceptions.IncorrectArgument(
                                "Strategy parameter must be the first type parameter";
                                got="parameter($applied_type) returned $bound_param, expected $param_type",
                                expected="Strategies.parameter to return $param_type for $applied_type",
                                suggestion="Declare the strategy parameter as the FIRST type parameter, e.g. struct $strategy_type{P<:AbstractStrategyParameter, ...}",
                                context="create_registry - validating strategy parameter is in the first type-parameter slot",
                            ),
                        )
                    end

                    push!(strategies, applied_type)
                end
            else
                # Non-parameterized strategy: Type (can be UnionAll for parameterized types with default)
                strategy_type = item

                if !(
                    strategy_type isa UnionAll ||
                    (strategy_type isa DataType && strategy_type <: AbstractStrategy)
                )
                    throw(
                        Exceptions.IncorrectArgument(
                            "Invalid strategy type";
                            got="strategy_type=$strategy_type of type $(typeof(strategy_type))",
                            expected="UnionAll or DataType subtype of AbstractStrategy",
                            suggestion="Use a valid AbstractStrategy subtype",
                            context="create_registry - validating strategy type",
                        ),
                    )
                end

                # Check GLOBAL uniqueness of strategy ID
                strategy_id = id(strategy_type)
                if strategy_id in all_strategy_ids
                    throw(
                        Exceptions.IncorrectArgument(
                            "Duplicate ID detected";
                            got="ID :$strategy_id used multiple times",
                            expected="unique IDs across all strategies and parameters",
                            suggestion="Ensure each strategy and parameter has a unique id()",
                            context="create_registry - validating global ID uniqueness",
                        ),
                    )
                end
                push!(all_strategy_ids, strategy_id)
                push!(strategies, strategy_type)
            end
        end

        # Validate all strategies are subtypes of family
        for T in strategies
            if !(T <: family)
                throw(
                    Exceptions.IncorrectArgument(
                        "Strategy type not compatible with family";
                        got="strategy type $T",
                        expected="subtype of family $family",
                        suggestion="Ensure strategy type $T is properly defined as <: $family",
                        context="StrategyRegistry constructor - validating strategy-family relationships",
                    ),
                )
            end
        end

        families[family] = strategies
    end

    return StrategyRegistry(families, parameter_id_to_type)
end

"""
$(TYPEDSIGNATURES)

Get all strategy IDs for a given family.

Returns a tuple of symbolic identifiers for all strategies registered under
the specified family type. The order matches the registration order.

# Arguments
- `family::Type{<:AbstractStrategy}`: The abstract family type
- `registry::StrategyRegistry`: The registry to query

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple of strategy IDs in registration order

# Example
```julia-repl
julia> using CTBase: Strategies

julia> ids = Strategies.strategy_ids(AbstractNLPModeler, registry)
(:adnlp, :exa)

julia> for strategy_id in ids
           println("Available: ", strategy_id)
       end
Available: adnlp
Available: exa
```

# Throws
- `ErrorException`: If the family is not found in the registry

See also: [`CTBase.Strategies.type_from_id`](@extref), [`CTBase.Strategies.create_registry`](@extref)
"""
function strategy_ids(family::Type{<:AbstractStrategy}, registry::StrategyRegistry)
    if !haskey(registry.families, family)
        available_families = collect(keys(registry.families))
        throw(
            Exceptions.IncorrectArgument(
                "Strategy family not found in registry";
                got="family $family",
                expected="one of registered families: $available_families",
                suggestion="Check available families or register the missing family first",
                context="strategy_ids - looking up family in registry",
            ),
        )
    end
    strategies = registry.families[family]

    # Deduplicate IDs (important for parameterized strategies)
    seen = Set{Symbol}()
    ids = Symbol[]
    for T in strategies
        s_id = id(T)
        if s_id ∉ seen
            push!(seen, s_id)
            push!(ids, s_id)
        end
    end
    return Tuple(ids)
end

"""
$(TYPEDSIGNATURES)

Lookup a strategy type from its ID within a family.

Searches the registry for a strategy with the given symbolic identifier within
the specified family. This is the core lookup mechanism used by the builder
functions to convert symbolic descriptions to concrete types.

# Arguments
- `strategy_id::Symbol`: The symbolic identifier to look up
- `family::Type{<:AbstractStrategy}`: The family to search within
- `registry::StrategyRegistry`: The registry to query

# Returns
- `Type{<:AbstractStrategy}`: The concrete strategy type matching the ID

# Example
```julia-repl
julia> using CTBase: Strategies

julia> T = Strategies.type_from_id(:adnlp, AbstractNLPModeler, registry)
Modelers.ADNLP

julia> Strategies.id(T)
:adnlp
```

# Throws
- `Exceptions.IncorrectArgument`: If the family is not found in the registry
- `Exceptions.IncorrectArgument`: If the ID is not found within the family (includes suggestions)

See also: [`CTBase.Strategies.strategy_ids`](@extref), [`CTBase.Strategies.build_strategy`](@extref)
"""
function type_from_id(
    strategy_id::Symbol,
    family::Type{<:AbstractStrategy},
    registry::StrategyRegistry;
    parameter::Union{Type{<:AbstractStrategyParameter},Nothing}=nothing,
)
    if !haskey(registry.families, family)
        available_families = collect(keys(registry.families))
        throw(
            Exceptions.IncorrectArgument(
                "Strategy family not found in registry";
                got="family $family",
                expected="one of registered families: $available_families",
                suggestion="Check available families or register the missing family first",
                context="type_from_id - looking up family in registry",
            ),
        )
    end

    for T in registry.families[family]
        if id(T) === strategy_id
            if parameter === nothing || Strategies.parameter(T) == parameter
                return T
            end
        end
    end

    # Not found - provide helpful error with available options
    available = strategy_ids(family, registry)
    if parameter !== nothing
        # More specific error for parameterized search
        param_strategies = [T for T in registry.families[family] if id(T) === strategy_id]
        if isempty(param_strategies)
            throw(
                Exceptions.IncorrectArgument(
                    "Unknown strategy ID";
                    got=":$strategy_id for family $family",
                    expected="one of available IDs: $available",
                    suggestion="Check available strategy IDs or register the missing strategy",
                    context="type_from_id - looking up strategy ID in family",
                ),
            )
        else
            available_params = [
                Strategies.parameter(T) for
                T in param_strategies if Strategies.parameter(T) !== nothing
            ]
            throw(
                Exceptions.IncorrectArgument(
                    "Strategy not found with specified parameter - check available parameters";
                    got="strategy :$strategy_id with parameter $parameter",
                    expected="strategy :$strategy_id with one of: $available_params",
                    suggestion="Check available parameters in the registry or use a non-parameterized version",
                    context="type_from_id - looking up parameterized strategy",
                ),
            )
        end
    else
        throw(
            Exceptions.IncorrectArgument(
                "Unknown strategy ID";
                got=":$strategy_id for family $family",
                expected="one of available IDs: $available",
                suggestion="Check available strategy IDs or register the missing strategy",
                context="type_from_id - looking up strategy ID in family",
            ),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Merge two or more strategy registries into one, validating cross-registry invariants
that `create_registry` already enforces within a single call:

- Every strategy `id()` must be unique across **all** input registries.
- A parameter `id()` shared by more than one input registry must resolve to the same
  parameter type in each.
- No `id()` may be used as a strategy ID in one registry and a parameter ID in another.

If the same family is registered in more than one input, their strategy lists are
**unioned** (still subject to the checks above) — this is what lets a downstream package
extend a family across two independently-built registries (e.g. a solve registry plus a
flow registry), rather than only combining registries with disjoint families.

# Arguments
- `a::StrategyRegistry`, `bs::StrategyRegistry...`: two or more registries to merge

# Returns
- `StrategyRegistry`: a new, validated registry containing every family/strategy/parameter
  from all inputs

# Throws
- `Exceptions.IncorrectArgument`: a strategy ID collides across inputs, a parameter ID
  resolves to different types across inputs, or a strategy/parameter ID collide with
  each other across inputs

# Example
```julia-repl
julia> using CTBase: Strategies

julia> solve_registry = Strategies.create_registry(AbstractNLPSolver => (Ipopt,))
julia> flow_registry  = Strategies.create_registry(AbstractIntegrator => (SciML,))

julia> combined = merge(solve_registry, flow_registry)
StrategyRegistry with 2 families

julia> Strategies.describe(:ipopt, combined)  # works
julia> Strategies.describe(:sciml, combined)  # works, same registry
```

See also: [`CTBase.Strategies.create_registry`](@extref), [`CTBase.Strategies.StrategyRegistry`](@extref)
"""
function Base.merge(a::StrategyRegistry, bs::StrategyRegistry...)
    registries = (a, bs...)
    length(registries) == 1 && return a

    # 1. Global strategy-ID uniqueness across ALL input registries.
    #    Within one registry this is already guaranteed by create_registry, so a
    #    re-assignment to the SAME source index is fine (e.g. DI{CPU}/DI{GPU} share
    #    :di within one registry) — only a different source index is a real collision.
    id_source = Dict{Symbol,Int}()
    for (i, r) in enumerate(registries)
        for (_, types) in r.families
            for T in types
                sid = id(T)
                if haskey(id_source, sid) && id_source[sid] != i
                    throw(
                        Exceptions.IncorrectArgument(
                            "Duplicate strategy ID across registries";
                            got=":$sid present in more than one input registry",
                            expected="each strategy id() present in exactly one input registry",
                            suggestion="Rename the colliding strategy's id(), or merge only non-overlapping registries",
                            context="merge(::StrategyRegistry...) - validating global ID uniqueness across registries",
                        ),
                    )
                end
                id_source[sid] = i
            end
        end
    end

    # 2. Parameter id => type agreement across all input registries.
    merged_parameters = Dict{Symbol,Type{<:AbstractStrategyParameter}}()
    for r in registries
        for (pid, ptype) in r.parameters
            if haskey(merged_parameters, pid) && merged_parameters[pid] != ptype
                throw(
                    Exceptions.IncorrectArgument(
                        "Parameter ID bound to different types across registries";
                        got="parameter :$pid resolves to $(merged_parameters[pid]) in one input and $ptype in another",
                        expected="parameter :$pid to resolve to the same type in every input registry",
                        suggestion="Rename one of the conflicting parameter types or its id()",
                        context="merge(::StrategyRegistry...) - validating parameter id/type agreement across registries",
                    ),
                )
            end
            merged_parameters[pid] = ptype
        end
    end

    # 3. Strategy IDs and parameter IDs must stay disjoint across the merged set.
    conflicting = intersect(keys(id_source), keys(merged_parameters))
    if !isempty(conflicting)
        throw(
            Exceptions.IncorrectArgument(
                "Parameter ID conflicts with strategy ID across registries";
                got="id(s) $(collect(conflicting)) used as both a strategy id and a parameter id across the input registries",
                expected="disjoint strategy IDs and parameter IDs across all input registries",
                suggestion="Rename the colliding id() on one side",
                context="merge(::StrategyRegistry...) - validating strategy/parameter id disjointness across registries",
            ),
        )
    end

    # 4. Union families, concatenating strategy lists for families shared across inputs.
    merged_families = Dict{Type{<:AbstractStrategy},Vector{Type}}()
    for r in registries
        for (family, types) in r.families
            if haskey(merged_families, family)
                append!(merged_families[family], types)
            else
                merged_families[family] = copy(types)
            end
        end
    end

    return StrategyRegistry(merged_families, merged_parameters)
end

# Display
function Base.show(io::IO, registry::StrategyRegistry)
    fmt = Core.get_format_codes(io)
    n_families = length(registry.families)
    return print(
        io,
        fmt.name,
        "StrategyRegistry",
        fmt.reset,
        " with ",
        fmt.count,
        n_families,
        fmt.reset,
        " ",
        n_families == 1 ? "family" : "families",
    )
end

function Base.show(io::IO, ::MIME"text/plain", registry::StrategyRegistry)
    fmt = Core.get_format_codes(io)
    n_families = length(registry.families)
    n_params = length(registry.parameters)
    has_params = n_params > 0

    # Header: "StrategyRegistry with N families and M parameters:"
    print(
        io,
        fmt.name,
        "StrategyRegistry",
        fmt.reset,
        " with ",
        fmt.count,
        n_families,
        fmt.reset,
        " ",
        n_families == 1 ? "family" : "families",
    )
    if has_params
        print(
            io,
            " and ",
            fmt.count,
            n_params,
            fmt.reset,
            " ",
            n_params == 1 ? "parameter" : "parameters",
        )
    end
    println(io, ":")

    items = collect(registry.families)
    for (i, (family, strategies)) in enumerate(items)
        # A family is "last" (uses └─) only when it is the last family AND no parameters follow
        is_last_family = i == length(items) && !has_params
        family_prefix = is_last_family ? "└─ " : "├─ "
        println(io, family_prefix, fmt.name, nameof(family), fmt.reset)

        # Group strategies by ID, preserving registration order
        seen_ids = Symbol[]
        id_to_types = Dict{Symbol,Vector{Type}}()
        for T in strategies
            strategy_id = id(T)
            if !haskey(id_to_types, strategy_id)
                id_to_types[strategy_id] = []
                push!(seen_ids, strategy_id)
            end
            push!(id_to_types[strategy_id], T)
        end

        # Display each unique strategy ID on one line
        for (j, strategy_id) in enumerate(seen_ids)
            types = id_to_types[strategy_id]
            is_last_strategy = j == length(seen_ids)
            strategy_prefix = if is_last_family
                is_last_strategy ? "   └─ " : "   ├─ "
            else
                is_last_strategy ? "│  └─ " : "│  ├─ "
            end

            # Base type name (without parameter)
            base_name = string(nameof(first(types)))

            # Collect parameter types if any
            params = Type{<:AbstractStrategyParameter}[]
            for T in types
                p = Strategies.parameter(T)
                p === nothing || push!(params, p)
            end

            if isempty(params)
                println(
                    io,
                    strategy_prefix,
                    fmt.type,
                    base_name,
                    fmt.reset,
                    " (",
                    fmt.label,
                    "id=",
                    fmt.reset,
                    fmt.keyword,
                    ":",
                    strategy_id,
                    fmt.reset,
                    ")",
                )
            else
                # Show parameter routing keys as symbols: [:cpu, :gpu]
                param_str = join(
                    [fmt.keyword * ":" * string(id(P)) * fmt.reset for P in params], ", "
                )
                println(
                    io,
                    strategy_prefix,
                    fmt.type,
                    base_name,
                    fmt.reset,
                    " (",
                    fmt.label,
                    "id=",
                    fmt.reset,
                    fmt.keyword,
                    ":",
                    strategy_id,
                    fmt.reset,
                    ") [",
                    param_str,
                    "]",
                )
            end
        end
    end

    # Parameters section as last tree entry: "└─ parameters: :cpu → CPU, :gpu → GPU"
    if has_params
        param_items = sort(collect(registry.parameters); by=p -> string(p[1]))
        param_str = join(
            [
                fmt.keyword *
                ":" *
                string(p_id) *
                fmt.reset *
                " → " *
                fmt.type *
                string(nameof(p_type)) *
                fmt.reset for (p_id, p_type) in param_items
            ],
            ", ",
        )
        println(io, "└─ ", fmt.label, "parameters: ", fmt.reset, param_str)
    end
end
