"""
$(TYPEDEF)

Abstract supertype for control-dependence traits.

Encodes, at the type level, whether an optimal control problem (or any object
that opts into the trait) carries a control input.

# Trait Pattern

Objects that have a control-dependence trait must implement two methods:
- `has_control_dependence_trait(obj::MyType) = true`: Indicates the type has this trait
- `control_dependence(obj::MyType)`: Returns the specific trait value (`ControlFree` or `WithControl`)

Once these are implemented, the object automatically gains:
- `is_control_free(obj)`: Returns true if `control_dependence(obj)` is `ControlFree`
- `has_control(obj)`: Returns true if `control_dependence(obj)` is `WithControl`

If `has_control_dependence_trait` is not implemented or returns `false`,
calling `is_control_free`, `has_control`, or `control_dependence` will throw an error
indicating the object does not support control-dependence queries.

See also: [`CTBase.Traits.ControlFree`](@ref), [`CTBase.Traits.WithControl`](@ref).
"""
abstract type ControlDependence <: AbstractTrait end

"""
$(TYPEDEF)

Trait indicating the problem has no control input (control-free).

A control-free optimal control problem has dynamics `ẋ = f(t, x, v)` with no
control argument; the trajectory is determined by the state (and costate)
equations alone, without a control law.

See also: [`CTBase.Traits.WithControl`](@ref), [`CTBase.Traits.ControlDependence`](@ref).
"""
struct ControlFree <: ControlDependence end

"""
$(TYPEDEF)

Trait indicating the problem has a control input.

A problem with control has dynamics `ẋ = f(t, x, u, v)` depending on a control
`u`; closing the loop (e.g. for a flow) requires a control law `u(t, x, p)`.

See also: [`CTBase.Traits.ControlFree`](@ref), [`CTBase.Traits.ControlDependence`](@ref).
"""
struct WithControl <: ControlDependence end

# =============================================================================
# Check has trait
# =============================================================================

"""
$(TYPEDSIGNATURES)

Check if the object has the control-dependence trait.

This fallback method throws an error indicating the object does not support
control-dependence queries. Concrete types that have the trait should implement
`has_control_dependence_trait(obj::MyType) = true`.

The calling function name is automatically detected from the stacktrace
for better error messages.

# Arguments
- `obj::Any`: The object to check.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): Always, indicating the object does not have the trait.

See also: [`CTBase.Traits.ControlDependence`](@ref), [`CTBase.Traits.control_dependence`](@ref).
"""
function has_control_dependence_trait(obj::Any)
    return _throw_missing_trait(
        obj, :has_control_dependence_trait, :control_dependence, "control-dependence"
    )
end

"""
$(TYPEDSIGNATURES)

Return the control-dependence trait value for the object.

This fallback method throws an error indicating the method is not implemented.
Concrete types that have the trait should implement `control_dependence(obj::MyType)`
to return the specific trait value (`ControlFree` or `WithControl`).

# Arguments
- `obj::Any`: The object to query.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@ref): Always, indicating the method must be implemented.

See also: [`CTBase.Traits.ControlDependence`](@ref), [`CTBase.Traits.has_control_dependence_trait`](@ref).
"""
function control_dependence(obj::Any)
    has_control_dependence_trait(obj)
    return _throw_trait_not_implemented(
        obj, :control_dependence, "control-dependence", "ControlFree or WithControl"
    )
end

# =============================================================================
# Trait accessors
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return true if the object is control-free (has no control input).

Checks that the object has the control-dependence trait, then returns true
if `control_dependence(obj)` is `ControlFree`.

# Arguments
- `obj::Any`: The object to check.

# Returns
- `Bool`: true if the object has no control input.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): If the object does not support control-dependence queries.
- [`CTBase.Exceptions.NotImplemented`](@ref): If `control_dependence` is not implemented for the object type.

See also: [`CTBase.Traits.ControlDependence`](@ref), [`CTBase.Traits.has_control`](@ref).
"""
function is_control_free(obj::Any)
    has_control_dependence_trait(obj)
    return control_dependence(obj) === ControlFree
end

"""
$(TYPEDSIGNATURES)

Return true if the object has a control input.

Checks that the object has the control-dependence trait, then returns true
if `control_dependence(obj)` is `WithControl`.

# Arguments
- `obj::Any`: The object to check.

# Returns
- `Bool`: true if the object has a control input.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): If the object does not support control-dependence queries.
- [`CTBase.Exceptions.NotImplemented`](@ref): If `control_dependence` is not implemented for the object type.

See also: [`CTBase.Traits.ControlDependence`](@ref), [`CTBase.Traits.is_control_free`](@ref).
"""
function has_control(obj::Any)
    has_control_dependence_trait(obj)
    return control_dependence(obj) === WithControl
end
