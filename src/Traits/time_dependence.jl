# =============================================================================
# Time-dependence trait types
#
# These were historically defined in CTModels.Components; they now live here so
# the whole ecosystem (CTModels, CTFlows, ...) shares a single set of types.
# Kept as abstract types (used as the `Model{TD,...}` type parameter in CTModels).
# =============================================================================

"""
$(TYPEDEF)

Abstract base type representing time dependence of an object (e.g. an optimal
control problem, a vector field, a Hamiltonian).

Used as a type parameter to distinguish between autonomous and non-autonomous
objects at the type level, enabling dispatch and compile-time optimisations.

See also: [`Autonomous`](@ref), [`NonAutonomous`](@ref).
"""
abstract type TimeDependence end

"""
$(TYPEDEF)

Type tag indicating that the dynamics and other functions do not explicitly
depend on time. For autonomous systems, the dynamics have the form `ẋ = f(x, u)`
rather than `ẋ = f(t, x, u)`.

See also: [`TimeDependence`](@ref), [`NonAutonomous`](@ref).
"""
abstract type Autonomous <: TimeDependence end

"""
$(TYPEDEF)

Type tag indicating that the dynamics and other functions explicitly depend on
time. For non-autonomous systems, the dynamics have the form `ẋ = f(t, x, u)`.

See also: [`TimeDependence`](@ref), [`Autonomous`](@ref).
"""
abstract type NonAutonomous <: TimeDependence end

# =============================================================================
# Time-dependence trait contract
# =============================================================================

"""
$(TYPEDSIGNATURES)

Check if the object has the time-dependence trait.

This fallback method throws an error indicating the object does not support
time-dependence queries. Concrete types that have the trait should implement
`has_time_dependence_trait(obj::MyType) = true`.

The calling function name is automatically detected from the stacktrace
for better error messages.

# Arguments
- `obj::Any`: The object to check.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): Always, indicating the object does not have the trait.

See also: [`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.time_dependence`](@ref).
"""
function has_time_dependence_trait(obj::Any)
    source_method = _caller_function_name()
    throw(Exceptions.IncorrectArgument(
        "Cannot call $(source_method) on object of type $(typeof(obj)): no time-dependence trait";
        suggestion = "Implement has_time_dependence_trait(obj::$(typeof(obj))) = true and time_dependence(obj::$(typeof(obj))) to enable time-dependence trait support.",
        context = "Time-dependence trait not available",
    ))
end

"""
$(TYPEDSIGNATURES)

Return the time-dependence trait value for the object.

This fallback method throws an error indicating the method is not implemented.
Concrete types that have the trait should implement `time_dependence(obj::MyType)`
to return the specific trait value (`Autonomous` or `NonAutonomous`).

# Arguments
- `obj::Any`: The object to query.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@extref): Always, indicating the method must be implemented.

See also: [`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.has_time_dependence_trait`](@ref).
"""
function time_dependence(obj::Any)
    has_time_dependence_trait(obj)
    throw(Exceptions.NotImplemented(
        "time_dependence not implemented for $(typeof(obj))";
        required_method = "time_dependence(obj::$(typeof(obj)))",
        suggestion = "Implement time_dependence for your concrete object type to return the specific time-dependence trait (Autonomous or NonAutonomous).",
        context = "Time-dependence trait - required method implementation",
    ))
end

"""
$(TYPEDSIGNATURES)

Return true if the object is autonomous (time-independent).

Checks that the object has the time-dependence trait, then returns true
if `time_dependence(obj)` is `Autonomous`.

# Arguments
- `obj::Any`: The object to check.

# Returns
- `Bool`: true if the object is autonomous.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If the object does not support time-dependence queries.
- [`CTBase.Exceptions.NotImplemented`](@extref): If `time_dependence` is not implemented for the object type.

See also: [`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.time_dependence`](@ref).
"""
function is_autonomous(obj::Any)
    has_time_dependence_trait(obj)
    return time_dependence(obj) === Autonomous
end

"""
$(TYPEDSIGNATURES)

Return true if the object is non-autonomous (time-dependent).

Checks that the object has the time-dependence trait, then returns true
if `time_dependence(obj)` is `NonAutonomous`.

# Arguments
- `obj::Any`: The object to check.

# Returns
- `Bool`: true if the object is non-autonomous.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@extref): If the object does not support time-dependence queries.
- [`CTBase.Exceptions.NotImplemented`](@extref): If `time_dependence` is not implemented for the object type.

See also: [`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.time_dependence`](@ref).
"""
function is_nonautonomous(obj::Any)
    has_time_dependence_trait(obj)
    return time_dependence(obj) === NonAutonomous
end
