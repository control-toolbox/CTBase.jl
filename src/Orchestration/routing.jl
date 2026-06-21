# Option routing with strategy-aware disambiguation

"""
$(TYPEDSIGNATURES)

Route all options with support for disambiguation and multi-strategy routing.

This is the main orchestration function that separates action options from
strategy options and routes each strategy option to the appropriate family.
It supports automatic routing for unambiguous options and explicit
disambiguation syntax for options that appear in multiple strategies.

# Arguments
- `method::Tuple{Vararg{Symbol}}`: Complete method tuple (e.g.,
  `(:collocation, :adnlp, :ipopt)`)
- `families::NamedTuple`: NamedTuple mapping family names to AbstractStrategy
  types
- `action_defs::Vector{Options.OptionDefinition}`: Definitions for
  action-specific options
- `kwargs::NamedTuple`: All keyword arguments (action + strategy options mixed)
- `registry::Strategies.StrategyRegistry`: Strategy registry
- `source_mode::Symbol=:description`: Controls error verbosity (`:description`
  for user-facing, `:explicit` for internal)

# Returns
NamedTuple with two fields:
- `action::NamedTuple`: NamedTuple of action options (with `OptionValue`
  wrappers)
- `strategies::NamedTuple`: NamedTuple of strategy options per family (raw
  values, may contain `BypassValue` wrappers for bypassed options)

# Disambiguation Syntax

**Auto-routing** (unambiguous):
```julia
solve(ocp, :collocation, :adnlp, :ipopt; grid_size=100)
# grid_size only belongs to discretizer => auto-route
```

**Single strategy** (disambiguate):
```julia
solve(ocp, :collocation, :adnlp, :ipopt; backend = route_to(adnlp=:sparse))
# backend belongs to both modeler and solver => disambiguate to :adnlp
```

**Multi-strategy** (set for multiple):
```julia
solve(ocp, :collocation, :adnlp, :ipopt; 
    backend = route_to(adnlp=:sparse, ipopt=:cpu)
)
# Set backend to :sparse for modeler AND :cpu for solver
```

**Bypass validation** (unknown backend option):
```julia
solve(ocp, :collocation, :adnlp, :ipopt;
    custom_opt = route_to(ipopt=bypass(42))
)
# BypassValue(42) is routed to solver and accepted unconditionally
```

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If an option is unknown, ambiguous without
  disambiguation, or routed to the wrong strategy

# Example
```julia
method = (:collocation, :adnlp, :ipopt)
families = (discretizer = DiscretizerFamily, modeler = ModelerFamily, solver = SolverFamily)
action_defs = Options.OptionDefinition[]
kwargs = (grid_size=100, backend=Strategies.route_to(adnlp=:sparse))
routed = route_all_options(method, families, action_defs, kwargs, registry)
```

See also: `extract_strategy_ids`, `build_strategy_to_family_map`, `build_option_ownership_map`
"""
function route_all_options(
    method::Tuple{Vararg{Symbol}},
    families::NamedTuple,
    action_defs::Vector{<:Options.OptionDefinition},
    kwargs::NamedTuple,
    registry::Strategies.StrategyRegistry;
    source_mode::Symbol=:description,
)
    # Step 1: Resolve method
    resolved = resolve_method(method, families, registry)

    # Step 2: Separate action and strategy options
    action_options, strategy_kwargs = _separate_action_and_strategy_options(
        kwargs, action_defs
    )

    # Step 3: Build routing context
    context = _build_routing_context(resolved, families, registry)

    # Step 4: Check for shadowing
    _check_action_option_shadowing(action_options, context.option_owners)

    # Step 5: Route strategy options
    routed = _initialize_routing_dict(families)
    for (key, raw_val) in pairs(strategy_kwargs)
        _route_single_option!(
            routed, key, raw_val, context, resolved, families, registry, source_mode
        )
    end

    # Step 6: Build final result
    return _build_routed_result(action_options, routed)
end

# ----------------------------------------------------------------------------
# Private Helper Functions for route_all_options
# ----------------------------------------------------------------------------

"""
$(TYPEDEF)

Internal struct to encapsulate routing context.

Holds precomputed mappings used during option routing to avoid
passing multiple dictionaries around and improve performance.

# Fields
- `strategy_to_family::Dict{Symbol, Symbol}`: Maps strategy IDs to their family names
- `option_owners::Dict{Symbol, Set{Symbol}}`: Maps option names to the set of families that own them

# Notes
- This struct is immutable and created once per routing operation
- Precomputing these mappings avoids repeated lookups during routing
- Used internally by the routing helper functions
"""
struct RoutingContext
    strategy_to_family::Dict{Symbol,Symbol}
    option_owners::Dict{Symbol,Set{Symbol}}
end

"""
$(TYPEDSIGNATURES)

Separate action options from strategy options.

Filters out RoutedOption values from action extraction, processes action
definitions, and re-integrates RoutedOption values for strategy routing.

# Arguments
- `kwargs::NamedTuple`: All keyword arguments (action + strategy options mixed)
- `action_defs::Vector{<:Options.OptionDefinition}`: Definitions for action-specific options

# Returns
- `Tuple{Dict, NamedTuple}`: (action_options, strategy_kwargs) where:
  - `action_options`: Dict of extracted action options with OptionValue wrappers
  - `strategy_kwargs`: NamedTuple of remaining kwargs for strategy routing

# Notes
- RoutedOption values are excluded from action extraction and preserved for strategy routing
- Action options are wrapped in OptionValue with source tracking
- Strategy options remain in their original form for further processing
"""
function _separate_action_and_strategy_options(
    kwargs::NamedTuple, action_defs::Vector{<:Options.OptionDefinition}
)::Tuple{Dict,NamedTuple}
    # Filter out RoutedOption values for action extraction
    action_kwargs = NamedTuple(
        k => v for (k, v) in pairs(kwargs) if !(v isa Strategies.RoutedOption)
    )

    action_options, remaining_action_kwargs = Options.extract_options(
        action_kwargs, action_defs
    )

    # Re-integrate RoutedOption values for strategy routing
    remaining_kwargs = merge(
        remaining_action_kwargs,
        NamedTuple(k => v for (k, v) in pairs(kwargs) if v isa Strategies.RoutedOption),
    )

    return (action_options, remaining_kwargs)
end

"""
$(TYPEDSIGNATURES)

Build routing context with precomputed mappings.

Creates a RoutingContext containing strategy-to-family and option ownership
maps to optimize routing performance by avoiding repeated computations.

# Arguments
- `resolved::ResolvedMethod`: Resolved method containing strategy information
- `families::NamedTuple`: NamedTuple mapping family names to AbstractStrategy types
- `registry::Strategies.StrategyRegistry`: Strategy registry for metadata lookup

# Returns
- `RoutingContext`: Context containing precomputed mappings for efficient routing

# Notes
- Precomputes expensive mapping operations once per routing call
- Strategy-to-family mapping enables quick family lookup from strategy ID
- Option ownership mapping enables quick validation of option routing
"""
function _build_routing_context(
    resolved::ResolvedMethod, families::NamedTuple, registry::Strategies.StrategyRegistry
)::RoutingContext
    strategy_to_family = build_strategy_to_family_map(resolved, families, registry)
    option_owners = build_option_ownership_map(resolved, families, registry)
    return RoutingContext(strategy_to_family, option_owners)
end

"""
$(TYPEDSIGNATURES)

Check for action option shadowing and emit info messages.

Detects when a user-provided action option also exists in strategy metadata,
which means the action option "shadows" the strategy option. Emits
informational messages to help users understand the shadowing.

# Arguments
- `action_options::Dict`: Dictionary of extracted action options with OptionValue wrappers
- `option_owners::Dict{Symbol, Set{Symbol}}`: Maps option names to families that own them

# Returns
- `Nothing`: This function only emits info messages

# Notes
- Only checks user-provided options (source === :user), not default values
- Provides helpful guidance on using route_to() for specific strategy targeting
- Uses @info to emit messages without interrupting execution
"""
function _check_action_option_shadowing(
    action_options::Dict, option_owners::Dict{Symbol,Set{Symbol}}
)::Nothing
    for (k, opt_val) in action_options
        if opt_val.source === :user &&
            haskey(option_owners, k) &&
            !isempty(option_owners[k])
            owners_str = join(sort(collect(option_owners[k])), ", ")
            @info "Option `$(k)` was intercepted as a global action option. " *
                "It is also available for the following strategy families: $(owners_str). " *
                "To pass it specifically to a strategy, use `route_to($(k)=...)`."
        end
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Initialize the routing dictionary structure.

Creates an empty routing dictionary with one entry per family to collect
routed options during the routing process.

# Arguments
- `families::NamedTuple`: NamedTuple mapping family names to AbstractStrategy types

# Returns
- `Dict{Symbol, Vector{Pair{Symbol, Any}}}`: Empty routing dictionary with entries for each family

# Notes
- Each family gets an empty Vector{Pair{Symbol, Any}} to collect routed options
- The structure enables efficient accumulation of options per family
- Used as the starting point for routing operations
"""
function _initialize_routing_dict(
    families::NamedTuple
)::Dict{Symbol,Vector{Pair{Symbol,Any}}}
    routed = Dict{Symbol,Vector{Pair{Symbol,Any}}}()
    for family_name in keys(families)
        routed[family_name] = Pair{Symbol,Any}[]
    end
    return routed
end

"""
$(TYPEDSIGNATURES)

Route a single option with explicit disambiguation.

Handles options wrapped in route_to() with explicit strategy targets.
Validates that the target family owns the option or that bypass is used.

# Arguments
- `routed::Dict{Symbol, Vector{Pair{Symbol, Any}}}`: Routing dictionary to populate
- `key::Symbol`: Option name being routed
- `disambiguations::Vector{Tuple{Any, Symbol}}`: List of (value, strategy_id) pairs
- `context::RoutingContext`: Precomputed routing mappings
- `resolved::ResolvedMethod`: Resolved method containing strategy information
- `families::NamedTuple`: NamedTuple mapping family names to AbstractStrategy types
- `registry::Strategies.StrategyRegistry`: Strategy registry for metadata lookup

# Returns
- `Nothing`: Modifies `routed` in-place

# Throws
- `Exceptions.IncorrectArgument`: If option is unknown or routed to wrong family

# Notes
- BypassValue allows routing unknown options without validation
- Validates option ownership to prevent incorrect routing
- Provides helpful error messages for misrouted options
"""
function _route_with_disambiguation!(
    routed::Dict{Symbol,Vector{Pair{Symbol,Any}}},
    key::Symbol,
    disambiguations::Vector{Tuple{Any,Symbol}},
    context::RoutingContext,
    resolved::ResolvedMethod,
    families::NamedTuple,
    registry::Strategies.StrategyRegistry,
)::Nothing
    for (value, strategy_id) in disambiguations
        family_name = context.strategy_to_family[strategy_id]
        owners = get(context.option_owners, key, Set{Symbol}())

        if family_name in owners || value isa Strategies.BypassValue
            # Known option → route normally
            # BypassValue → route without validation
            push!(routed[family_name], key => value)
        elseif isempty(owners)
            # Unknown option with explicit target but no bypass → error
            _error_unknown_option(
                key, resolved, families, context.strategy_to_family, registry
            )
        else
            # Option exists but in wrong family
            valid_strategies = [
                id for (id, fam) in context.strategy_to_family if fam in owners
            ]
            throw(
                Exceptions.IncorrectArgument(
                    "Invalid option routing";
                    got="option :$key to strategy :$strategy_id",
                    expected="option to be routed to one of: $valid_strategies",
                    suggestion="Check option ownership or use correct strategy identifier",
                    context="route_options - validating strategy-specific option routing",
                ),
            )
        end
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Route a single option automatically based on ownership.

Handles options without explicit disambiguation by checking ownership:
- Unknown option → error with helpful suggestions
- Single owner → auto-route to that family
- Multiple owners → ambiguity error requiring disambiguation

# Arguments
- `routed::Dict{Symbol, Vector{Pair{Symbol, Any}}}`: Routing dictionary to populate
- `key::Symbol`: Option name being routed
- `value::Any`: Option value to route
- `context::RoutingContext`: Precomputed routing mappings
- `resolved::ResolvedMethod`: Resolved method containing strategy information
- `families::NamedTuple`: NamedTuple mapping family names to AbstractStrategy types
- `registry::Strategies.StrategyRegistry`: Strategy registry for metadata lookup
- `source_mode::Symbol`: Controls error verbosity (:description or :explicit)

# Returns
- `Nothing`: Modifies `routed` in-place

# Throws
- `Exceptions.IncorrectArgument`: If option is unknown or ambiguous

# Notes
- Uses option ownership mapping to determine routing destination
- Provides detailed error messages with suggestions for unknown/ambiguous options
- Auto-routing only occurs when option has exactly one owner
"""
function _route_auto!(
    routed::Dict{Symbol,Vector{Pair{Symbol,Any}}},
    key::Symbol,
    value::Any,
    context::RoutingContext,
    resolved::ResolvedMethod,
    families::NamedTuple,
    registry::Strategies.StrategyRegistry,
    source_mode::Symbol,
)::Nothing
    owners = get(context.option_owners, key, Set{Symbol}())

    if isempty(owners)
        # Unknown option - provide helpful error
        _error_unknown_option(key, resolved, families, context.strategy_to_family, registry)
    elseif length(owners) == 1
        # Unambiguous - auto-route
        family_name = first(owners)
        push!(routed[family_name], key => value)
    else
        # Ambiguous - need disambiguation
        _error_ambiguous_option(
            key,
            value,
            owners,
            context.strategy_to_family,
            source_mode,
            resolved,
            families,
            registry,
        )
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Route a single option (dispatcher).

Determines whether the option has explicit disambiguation and routes accordingly.
Acts as the main dispatcher for option routing logic.

# Arguments
- `routed::Dict{Symbol, Vector{Pair{Symbol, Any}}}`: Routing dictionary to populate
- `key::Symbol`: Option name being routed
- `raw_val::Any`: Raw option value (may be wrapped in RoutedOption)
- `context::RoutingContext`: Precomputed routing mappings
- `resolved::ResolvedMethod`: Resolved method containing strategy information
- `families::NamedTuple`: NamedTuple mapping family names to AbstractStrategy types
- `registry::Strategies.StrategyRegistry`: Strategy registry for metadata lookup
- `source_mode::Symbol`: Controls error verbosity (:description or :explicit)

# Returns
- `Nothing`: Modifies `routed` in-place

# Notes
- Extracts strategy disambiguations from RoutedOption values if present
- Delegates to _route_with_disambiguation! for explicit routing
- Delegates to _route_auto! for automatic routing
- Central point for all option routing decisions
"""
function _route_single_option!(
    routed::Dict{Symbol,Vector{Pair{Symbol,Any}}},
    key::Symbol,
    raw_val::Any,
    context::RoutingContext,
    resolved::ResolvedMethod,
    families::NamedTuple,
    registry::Strategies.StrategyRegistry,
    source_mode::Symbol,
)::Nothing
    disambiguations = extract_strategy_ids(raw_val, resolved)

    if disambiguations !== nothing
        _route_with_disambiguation!(
            routed, key, disambiguations, context, resolved, families, registry
        )
    else
        _route_auto!(
            routed, key, raw_val, context, resolved, families, registry, source_mode
        )
    end
    return nothing
end

"""
$(TYPEDSIGNATURES)

Build the final routed result structure.

Converts the routing dictionary and action options into the final NamedTuple format
expected by the routing system API.

# Arguments
- `action_options::Dict`: Dictionary of extracted action options with OptionValue wrappers
- `routed::Dict{Symbol, Vector{Pair{Symbol, Any}}}`: Routing dictionary with options per family

# Returns
- `NamedTuple`: Final result with structure `(action=..., strategies=...)` where:
  - `action`: NamedTuple of action options with OptionValue wrappers
  - `strategies`: NamedTuple of strategy options per family (raw values)

# Notes
- Converts routing dictionary to nested NamedTuple structure
- Preserves OptionValue wrappers for action options
- Strategy options remain in their raw form for downstream processing
- This is the final step in the routing pipeline
"""
function _build_routed_result(
    action_options::Dict, routed::Dict{Symbol,Vector{Pair{Symbol,Any}}}
)::NamedTuple
    strategy_options = NamedTuple(
        family_name => NamedTuple(pairs) for (family_name, pairs) in routed
    )

    action_nt = (; (k => v for (k, v) in action_options)...)

    return (action=action_nt, strategies=strategy_options)
end

# ----------------------------------------------------------------------------
# Error Message Helpers (Private)
# ----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Search for an option in all strategies of the registry, excluding strategies in the current method.

This helper function checks if an unknown option exists in strategies that are not part of the
current method, enabling helpful error messages that suggest the user may have chosen the wrong strategy.

# Arguments
- `key::Symbol`: The option name to search for
- `resolved::ResolvedMethod`: Resolved method containing current strategy IDs
- `families::NamedTuple`: NamedTuple mapping family names to family types
- `registry::Strategies.StrategyRegistry`: Strategy registry containing all registered strategies

# Returns
- `Vector{Tuple{Symbol, Symbol}}`: Vector of (strategy_id, family_name) tuples for strategies that have this option

# Notes
- Strategies in the current method are excluded from the search
- Uses try/catch around metadata() for robustness against incomplete strategy definitions
- Results are not ordered; caller should sort if needed
"""
function _find_option_in_registry(
    key::Symbol,
    resolved::ResolvedMethod,
    families::NamedTuple,
    registry::Strategies.StrategyRegistry,
)::Vector{Tuple{Symbol,Symbol}}
    # Get set of strategy IDs in current method
    current_strategy_ids = Set(collect(resolved.ids_by_family))

    # Search all strategies in registry
    matches = Tuple{Symbol,Symbol}[]
    for (family_type, strategy_types) in registry.families
        # Find the family name for this family_type
        family_name = nothing
        for (fname, ftype) in pairs(families)
            if ftype === family_type
                family_name = fname
                break
            end
        end
        if family_name === nothing
            continue  # This family_type is not in current families, skip
        end

        for strategy_type in strategy_types
            strategy_id = Strategies.id(strategy_type)
            # Skip if this strategy is in current method
            if strategy_id in current_strategy_ids
                continue
            end
            # Check if option exists in this strategy's metadata
            try
                meta = Strategies.metadata(strategy_type)
                if haskey(meta, key)
                    push!(matches, (strategy_id, family_name))
                end
            catch
                # Skip if metadata fails (robustness)
            end
        end
    end

    return matches
end

"""
$(TYPEDSIGNATURES)

Helper to throw an informative error when an option doesn't belong to any strategy.
Lists all available options for the active strategies to help the user.

# Notes
- Also searches the registry for strategies not in the current method that have this option,
  suggesting the user may have chosen the wrong strategy.
"""
function _error_unknown_option(
    key::Symbol,
    resolved::ResolvedMethod,
    families::NamedTuple,
    strategy_to_family::Dict{Symbol,Symbol},
    registry::Strategies.StrategyRegistry,
)
    # Build helpful error message showing all available options
    all_options = Dict{Symbol,Vector{Symbol}}()
    for (family_name, family_type) in pairs(families)
        id = getfield(resolved.ids_by_family, family_name)
        option_names = option_names_from_resolved(resolved, family_name, families, registry)
        all_options[id] = collect(option_names)
    end

    msg =
        "Option :$key doesn't belong to any strategy in method $(resolved.tokens).\n\n" *
        "Available options:\n"
    for (id, option_names) in all_options
        family = strategy_to_family[id]
        msg *= "  $family (:$id): $(join(option_names, ", "))\n"
    end

    # Suggest closest options across all strategies (using primary names + aliases)
    suggestion_parts = String[]

    # First, suggest similar options if any
    all_suggestions = _collect_suggestions_across_strategies(
        key, resolved, families, registry; max_suggestions=3
    )
    if !isempty(all_suggestions)
        push!(
            suggestion_parts,
            "Did you mean?\n" *
            join(["  - $(Strategies.format_suggestion(s))" for s in all_suggestions], "\n"),
        )
    end

    # Then, check if option exists in other strategies in registry
    registry_matches = _find_option_in_registry(key, resolved, families, registry)
    if !isempty(registry_matches)
        if !isempty(all_suggestions)
            push!(suggestion_parts, "\n")
        end
        matches_str = join([" :$sid ($family)" for (sid, family) in registry_matches], ", ")
        push!(
            suggestion_parts,
            "This option exists in other strategies:$matches_str.\n" *
            "Perhaps you selected the wrong strategy? Consider using a different method.",
        )
    end

    # Then, suggest bypass if user is confident about the option
    if !isempty(all_suggestions) || !isempty(registry_matches)
        push!(suggestion_parts, "\n")
    end
    push!(
        suggestion_parts,
        "If you're confident this option exists for a specific strategy, " *
        "use bypass() to skip validation:\n" *
        "  custom_opt = route_to(<strategy_id>=bypass(<value>))",
    )

    # Combine all suggestions
    suggestion = join(suggestion_parts, "")

    throw(
        Exceptions.IncorrectArgument(
            "Unknown option provided";
            got="option :$key in method $(resolved.tokens)",
            expected="valid option name for one of the strategies",
            suggestion=suggestion,
            context="route_options - unknown option validation",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Collect option suggestions across all strategies in the method, deduplicated by primary name.
Returns the top `max_suggestions` results sorted by minimum Levenshtein distance.
"""
function _collect_suggestions_across_strategies(
    key::Symbol,
    resolved::ResolvedMethod,
    families::NamedTuple,
    registry::Strategies.StrategyRegistry;
    max_suggestions::Int=3,
)
    # Collect suggestions from all strategies, keeping best distance per primary name
    best = Dict{
        Symbol,@NamedTuple{primary::Symbol,aliases::Tuple{Vararg{Symbol}},distance::Int}
    }()
    for (family_name, family_type) in pairs(families)
        id = getfield(resolved.ids_by_family, family_name)
        strategy_type = Strategies.type_from_id(id, family_type, registry)
        suggestions = Strategies.suggest_options(
            key, strategy_type; max_suggestions=typemax(Int)
        )
        for s in suggestions
            if !haskey(best, s.primary) || s.distance < best[s.primary].distance
                best[s.primary] = s
            end
        end
    end

    # Sort by distance and take top suggestions
    results = sort(collect(values(best)); by=x -> x.distance)
    n = min(max_suggestions, length(results))
    return results[1:n]
end

"""
$(TYPEDSIGNATURES)

Helper to throw an informative error when an option belongs to multiple strategies and needs disambiguation.
Suggests using `route_to` syntax with specific examples for the conflicting strategies.
"""
function _error_ambiguous_option(
    key::Symbol,
    value::Any,
    owners::Set{Symbol},
    strategy_to_family::Dict{Symbol,Symbol},
    source_mode::Symbol,
    resolved::ResolvedMethod,
    families::NamedTuple,
    registry::Strategies.StrategyRegistry,
)
    # Find which strategies own this option
    strategies = [id for (id, fam) in strategy_to_family if fam in owners]

    # Collect aliases for this option from each strategy's metadata
    alias_info = String[]
    for (family_name, family_type) in pairs(families)
        if family_name in owners
            try
                sid = getfield(resolved.ids_by_family, family_name)
                strategy_type = Strategies.type_from_id(sid, family_type, registry)
                meta = Strategies.metadata(strategy_type)
                if haskey(meta, key)
                    def = meta[key]
                    if !isempty(def.aliases)
                        push!(alias_info, "  :$sid aliases: $(join(def.aliases, ", "))")
                    end
                end
            catch
                # Skip if metadata lookup fails
            end
        end
    end

    if source_mode === :description
        # User-friendly error message with route_to() syntax
        msg =
            "Option :$key is ambiguous between strategies: " *
            "$(join(strategies, ", ")).\n\n" *
            "Disambiguate using route_to():\n"
        for id in strategies
            fam = strategy_to_family[id]
            msg *= "  $key = route_to($id=$value)    # Route to $fam\n"
        end
        msg *=
            "\nOr set for multiple strategies:\n" *
            "  $key = route_to(" *
            join(["$id=$value" for id in strategies], ", ") *
            ")"
        # Build suggestion with alias info
        suggestion = "Use route_to() like $key = route_to($(first(strategies))=$value) to specify target strategy"
        if !isempty(alias_info)
            suggestion *=
                ". Or use strategy-specific aliases to avoid ambiguity:\n" *
                join(alias_info, "\n")
        end
        throw(
            Exceptions.IncorrectArgument(
                "Ambiguous option requires disambiguation";
                got="option :$key between strategies: $(join(strategies, ", "))",
                expected="strategy-specific routing using route_to()",
                suggestion=suggestion,
                context="route_options - ambiguous option resolution",
            ),
        )
    else
        # Internal/developer error message
        throw(
            Exceptions.IncorrectArgument(
                "Ambiguous option in explicit mode";
                got="option :$key between families: $owners",
                expected="unambiguous option routing in explicit mode",
                suggestion="Use route_to() for disambiguation or switch to description mode",
                context="route_options - explicit mode ambiguity validation",
            ),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Helper to warn when an unknown option is routed in permissive mode.
"""
function _warn_unknown_option_permissive(
    key::Symbol, strategy_id::Symbol, family_name::Symbol
)
    @warn """
    Unknown option routed in permissive mode

    Option :$key is not defined in the metadata of strategy :$strategy_id ($family_name).

    This option will be passed directly to the strategy backend without validation.
    Ensure the option name and value are correct for the backend.
    """
end
