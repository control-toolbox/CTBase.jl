"""
$(TYPEDEF)

Abstract supertype for variable-dependence traits.

# Trait Pattern

Objects that have a variable-dependence trait must implement two methods:
- `has_variable_dependence_trait(obj::MyType) = true`: Indicates the type has this trait
- `variable_dependence(obj::MyType)`: Returns the specific trait value (`Fixed` or `NonFixed`)

Once these are implemented, the object automatically gains:
- `is_variable(obj)`: Returns true if `variable_dependence(obj)` is `NonFixed`
- `is_nonvariable(obj)`: Returns true if `variable_dependence(obj)` is `Fixed`
- `has_variable(obj)`: Alias for `is_variable` (CTModels compatibility)

If `has_variable_dependence_trait` is not implemented or returns `false`,
calling `is_variable`, `is_nonvariable`, `has_variable`, or `variable_dependence` will throw an error
indicating the object does not support variable-dependence queries.
"""
abstract type VariableDependence <: AbstractTrait end

"""
$(TYPEDEF)

Trait indicating the system or function has no variable parameters.

Indicates that the system operates with fixed parameters only, without additional
variable arguments that can be treated as dynamic variables during integration.

Common use cases include:
- Functions with fixed parameters only
- Systems with constant parameters that are not integrated
- Configurations where all parameters are known at compile time

See also: [`CTBase.Traits.NonFixed`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
struct Fixed <: VariableDependence end

"""
$(TYPEDEF)

Trait indicating the system or function depends on variable parameters.

Indicates that the system operates with additional variable parameters that can
be treated as dynamic variables during integration or optimization. These variables
may be integrated alongside state variables or used for sensitivity analysis.

Common use cases include:
- Functions with an extra variable argument `v`
- Systems with parameters that vary during integration
- Configurations where parameters are treated as control variables
- Sensitivity analysis and parameter estimation

See also: [`CTBase.Traits.Fixed`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
struct NonFixed <: VariableDependence end

# =============================================================================
# Check has trait
# =============================================================================

"""
$(TYPEDSIGNATURES)

Check if the object has the variable-dependence trait.

This fallback method throws an error indicating the object does not support
variable-dependence queries. Concrete types that have the trait should implement
`has_variable_dependence_trait(obj::MyType) = true`.

The calling function name is automatically detected from the stacktrace
for better error messages.

# Arguments
- `obj::Any`: The object to check.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): Always, indicating the object does not have the trait.

See also: [`CTBase.Traits.VariableDependence`](@ref), [`CTBase.Traits.variable_dependence`](@ref).
"""
function has_variable_dependence_trait(obj::Any)
    source_method = _caller_function_name()
    return throw(
        Exceptions.IncorrectArgument(
            "Cannot call $(source_method) on object of type $(typeof(obj)): no variable-dependence trait";
            suggestion="Implement has_variable_dependence_trait(obj::$(typeof(obj))) = true and variable_dependence(obj::$(typeof(obj))) to enable variable-dependence trait support.",
            context="Variable-dependence trait not available",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Return the variable-dependence trait value for the object.

This fallback method throws an error indicating the method is not implemented.
Concrete types that have the trait should implement `variable_dependence(obj::MyType)`
to return the specific trait value (`Fixed` or `NonFixed`).

# Arguments
- `obj::Any`: The object to query.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@ref): Always, indicating the method must be implemented.

See also: [`CTBase.Traits.VariableDependence`](@ref), [`CTBase.Traits.has_variable_dependence_trait`](@ref).
"""
function variable_dependence(obj::Any)
    has_variable_dependence_trait(obj)
    return throw(
        Exceptions.NotImplemented(
            "variable_dependence not implemented for $(typeof(obj))";
            required_method="variable_dependence(obj::$(typeof(obj)))",
            suggestion="Implement variable_dependence for your concrete object type to return the specific variable-dependence trait (Fixed or NonFixed).",
            context="Variable-dependence trait - required method implementation",
        ),
    )
end

# =============================================================================
# Trait accessors
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return true if the object depends on variable parameters.

Checks that the object has the variable-dependence trait, then returns true
if `variable_dependence(obj)` is `NonFixed`.

# Arguments
- `obj::Any`: The object to check.

# Returns
- `Bool`: true if the object depends on variable parameters.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): If the object does not support variable-dependence queries.
- [`CTBase.Exceptions.NotImplemented`](@ref): If `variable_dependence` is not implemented for the object type.

See also: [`CTBase.Traits.VariableDependence`](@ref), [`CTBase.Traits.variable_dependence`](@ref).
"""
function is_variable(obj::Any)
    has_variable_dependence_trait(obj)
    return variable_dependence(obj) === NonFixed
end

"""
$(TYPEDSIGNATURES)

Return true if the object does not depend on variable parameters.

Checks that the object has the variable-dependence trait, then returns true
if `variable_dependence(obj)` is `Fixed`.

# Arguments
- `obj::Any`: The object to check.

# Returns
- `Bool`: true if the object does not depend on variable parameters.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): If the object does not support variable-dependence queries.
- [`CTBase.Exceptions.NotImplemented`](@ref): If `variable_dependence` is not implemented for the object type.

See also: [`CTBase.Traits.VariableDependence`](@ref), [`CTBase.Traits.variable_dependence`](@ref).
"""
function is_nonvariable(obj::Any)
    has_variable_dependence_trait(obj)
    return variable_dependence(obj) === Fixed
end

"""
$(TYPEDSIGNATURES)

Return true if the object depends on variable parameters.

Checks that the object has the variable-dependence trait, then returns true
if `variable_dependence(obj)` is `NonFixed`.

# Arguments
- `obj::Any`: The object to check.

# Returns
- `Bool`: true if the object depends on variable parameters.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): If the object does not support variable-dependence queries.
- [`CTBase.Exceptions.NotImplemented`](@ref): If `variable_dependence` is not implemented for the object type.

See also: `is_variable`, [`CTBase.Traits.VariableDependence`](@ref).
"""
function has_variable(obj::Any)
    has_variable_dependence_trait(obj)
    return variable_dependence(obj) === NonFixed
end
