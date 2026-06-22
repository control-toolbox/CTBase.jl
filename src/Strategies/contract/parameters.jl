# ============================================================================
# Strategy Parameters Contract
# ============================================================================

"""
Abstract base type for strategy parameters.

Strategy parameters allow specialization of strategy behavior and default options.
Every concrete parameter must implement:
- `id(::Type{<:AbstractStrategyParameter})::Symbol` - Unique identifier

# Examples
```julia
struct CPU <: AbstractStrategyParameter end
id(::Type{CPU}) = :cpu

struct GPU <: AbstractStrategyParameter end
id(::Type{GPU}) = :gpu
```

# Notes
- Parameters are singleton types (no fields) - they exist only for type dispatch
- IDs must be globally unique across all strategies and parameters
- Parameters are used to specialize default options in strategy metadata
"""
abstract type AbstractStrategyParameter end

"""
$(TYPEDSIGNATURES)

Get the unique identifier for a parameter type.

Every concrete parameter type must implement this method to provide
a unique symbol identifier used in routing and registry operations.

# Arguments
- `parameter_type::Type{<:AbstractStrategyParameter}`: The parameter type

# Returns
- `Symbol`: Unique identifier for the parameter

# Throws
- `CTBase.Exceptions.NotImplemented`: If the parameter type doesn't implement this method

# Examples
```julia-repl
julia> id(CPU)
:cpu

julia> id(GPU)
:gpu
```
"""
function id(parameter_type::Type{<:AbstractStrategyParameter})
    throw(
        Exceptions.NotImplemented(
            "id() must be implemented for parameter type";
            required_method="id(::Type{$(parameter_type)})",
            suggestion="Define id(::Type{$(parameter_type)}) = :your_id",
            context="AbstractStrategyParameter contract",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Check whether a type is a strategy parameter type.

This predicate is useful for contract validation and generic code paths that
need to distinguish parameter types from other types.

# Arguments
- `T::Type`: Any Julia type

# Returns
- `Bool`: `true` if `T <: AbstractStrategyParameter`, otherwise `false`

# Example
```julia-repl
julia> Strategies.is_a_parameter(Strategies.CPU)
true

julia> Strategies.is_a_parameter(Int)
false
```

See also: `AbstractStrategyParameter`, `validate_parameter_type`
"""
is_a_parameter(::Type{T}) where {T} = T <: AbstractStrategyParameter

"""
$(TYPEDSIGNATURES)

!!! warning "Deprecated"
    `is_parameter_type` is deprecated; use `is_a_parameter` instead.
"""
function is_parameter_type(::Type{T}) where {T}
    Base.depwarn("`is_parameter_type` is deprecated, use `is_a_parameter` instead.", :is_parameter_type)
    return is_a_parameter(T)
end

"""
$(TYPEDSIGNATURES)

Get the identifier of a strategy parameter type.

This is an explicit alias for `id` to make code using parameter IDs
more self-documenting.

# Arguments
- `parameter_type::Type{<:AbstractStrategyParameter}`: The parameter type

# Returns
- `Symbol`: The parameter identifier

# Example
```julia-repl
julia> Strategies.parameter_id(Strategies.CPU)
:cpu
```

See also: `id`, `AbstractStrategyParameter`
"""
parameter_id(parameter_type::Type{<:AbstractStrategyParameter}) = id(parameter_type)

"""
$(TYPEDSIGNATURES)

Validate that a parameter type satisfies the `AbstractStrategyParameter` contract.

This function performs lightweight structural checks:
- the parameter type must be concrete
- the parameter type must be a singleton type (no fields)
- the parameter type must implement `id`

# Arguments
- `parameter_type::Type{<:AbstractStrategyParameter}`: The parameter type to validate

# Returns
- `Nothing`: Returns `nothing` if validation succeeds

# Throws
- `Exceptions.IncorrectArgument`: If the parameter type is not concrete or has fields
- `Exceptions.NotImplemented`: If the parameter type does not implement `id`

# Example
```julia
struct MyParam <: Strategies.AbstractStrategyParameter end
Strategies.id(::Type{MyParam}) = :my_param

Strategies.validate_parameter_type(MyParam)  # returns nothing
```

# Notes
- This function does not validate global ID uniqueness; that is handled by registry construction.

See also: `id`, `parameter_id`, `is_a_parameter`
"""
function validate_parameter_type(parameter_type::Type{<:AbstractStrategyParameter})
    if !isconcretetype(parameter_type)
        throw(
            Exceptions.IncorrectArgument(
                "Invalid parameter type";
                got="parameter_type=$parameter_type",
                expected="a concrete DataType subtype of AbstractStrategyParameter",
                suggestion="Define a concrete struct subtype, e.g. struct MyParam <: AbstractStrategyParameter end",
                context="validate_parameter_type - contract validation",
            ),
        )
    end
    if fieldcount(parameter_type) != 0
        throw(
            Exceptions.IncorrectArgument(
                "Invalid parameter type";
                got="parameter_type=$parameter_type with $(fieldcount(parameter_type)) fields",
                expected="a singleton parameter type with no fields",
                suggestion="Remove fields from the parameter type; use type dispatch only",
                context="validate_parameter_type - singleton type requirement",
            ),
        )
    end
    _ = id(parameter_type)
    return nothing
end

# ============================================================================

"""
CPU parameter type for CPU-based computation.

This parameter indicates that a strategy should use CPU-based backends
and default options optimized for CPU execution.
"""
struct CPU <: AbstractStrategyParameter end

"""
GPU parameter type for GPU-based computation.

This parameter indicates that a strategy should use GPU-based backends
and default options optimized for GPU execution.

# Notes
- Requires CUDA.jl to be loaded and functional
- Strategies may throw `CTBase.Exceptions.ExtensionError` if CUDA is not available
"""
struct GPU <: AbstractStrategyParameter end

# Implement the contract for built-in parameters
id(::Type{CPU}) = :cpu
id(::Type{GPU}) = :gpu

# ============================================================================
# Parameter Description Contract
# ============================================================================

"""
$(TYPEDSIGNATURES)

Get the description for a parameter type.

Every concrete parameter type should implement this method to provide
a human-readable description of the parameter's purpose and behavior.

# Arguments
- `parameter_type::Type{<:AbstractStrategyParameter}`: The parameter type

# Returns
- `String`: Human-readable description of the parameter

# Throws
- `Exceptions.NotImplemented`: If the parameter type doesn't implement this method

# Example
\`\`\`julia-repl
julia> using CTBase.Strategies

julia> description(CPU)
"CPU-based computation"

julia> description(GPU)
"GPU-based computation"
\`\`\`

See also: [`id`](@ref), [`AbstractStrategyParameter`](@ref)
"""
function description(parameter_type::Type{<:AbstractStrategyParameter})
    throw(
        Exceptions.NotImplemented(
            "description() must be implemented for parameter type";
            required_method="description(::Type{$(parameter_type)})",
            suggestion="Define description(::Type{$(parameter_type)}) = \"Your description\"",
            context="AbstractStrategyParameter contract",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

CPU parameter description.
"""
description(::Type{CPU}) = "CPU-based computation"

"""
$(TYPEDSIGNATURES)

GPU parameter description.
"""
description(::Type{GPU}) = "GPU-based computation"

# ============================================================================
# Describe - Parameter introspection
# ============================================================================

"""
$(TYPEDSIGNATURES)

Display comprehensive information about a parameter type.

This function provides type-level introspection that shows:
- Parameter ID
- Type hierarchy chain
- Description

# Arguments
- `parameter_type::Type{<:AbstractStrategyParameter}`: The parameter type to describe

# Example
\`\`\`julia-repl
julia> using CTBase.Strategies

julia> describe(CPU)
CPU (parameter)
├─ id: :cpu
├─ hierarchy: CPU → AbstractStrategyParameter
└─ description: CPU-based computation
\`\`\`

See also: [`describe(::Symbol, ::StrategyRegistry)`](@ref), [`id`](@ref), [`description`](@ref)
"""
function describe(parameter_type::Type{T}) where {T<:AbstractStrategyParameter}
    describe(stdout, parameter_type)
end

"""
$(TYPEDSIGNATURES)

Display parameter information to a specific IO stream.

See [`describe(::Type{<:AbstractStrategyParameter})`](@ref) for details.
"""
function describe(io::IO, parameter_type::Type{T}) where {T<:AbstractStrategyParameter}
    fmt = Core.get_format_codes(io)
    type_name = nameof(parameter_type)
    param_id = id(parameter_type)
    param_desc = description(parameter_type)

    # Build hierarchy chain: parameter → AbstractStrategyParameter
    hierarchy_chain = [parameter_type, AbstractStrategyParameter]
    hierarchy_str = join(
        [fmt.type * string(nameof(T)) * fmt.reset for T in hierarchy_chain], " → "
    )

    println(io, fmt.name, type_name, fmt.reset, " (parameter)")
    println(io, "├─ ", fmt.label, "id: ", fmt.reset, fmt.keyword, ":", param_id, fmt.reset)
    println(io, "├─ ", fmt.label, "hierarchy: ", fmt.reset, hierarchy_str)
    _print_labeled_multiline(io, "└─ ", "   ", fmt, "description: ", param_desc)
end

# ============================================================================
# Parameter Support Validation
# ============================================================================

"""
$(TYPEDSIGNATURES)

Get the default parameter type for a strategy.

This function returns the default parameter type that a strategy accepts.
Strategies should override this method to specify their default parameter.

# Arguments
- `strategy_type::Type{<:AbstractStrategy}`: The strategy type

# Returns
- `Type{<:AbstractStrategyParameter}`: Default parameter type

# Default Behavior
By default, returns `CPU` for backward compatibility. Strategies that
have a different default parameter should override this method.

# Example
```julia
# Strategy that defaults to CPU
_default_parameter(::Type{<:MyStrategy}) = CPU

# Strategy that defaults to GPU
_default_parameter(::Type{<:MyOtherStrategy}) = GPU
```

See also: `CPU`, `GPU`
"""
function _default_parameter(::Type{<:AbstractStrategy})
    throw(
        Exceptions.NotImplemented(
            "Strategy must implement _default_parameter";
            required_method="Strategies._default_parameter(::Type{<:YourStrategy})",
            suggestion="Define Strategies._default_parameter(::Type{<:YourStrategy}) = CPU or GPU",
            context="Parameter contract - all parameterized strategies must declare default parameter",
        ),
    )
end
