"""
    _caller_function_name() -> Symbol

Return the name of the calling function by inspecting the stacktrace.

This is used to provide better error messages in trait check functions
without requiring an explicit `source_method` argument.

Frames internal to the trait-contract machinery are skipped: the helper itself,
the shared throwers (`_throw_missing_trait`, `_throw_trait_not_implemented`), any
`has_<family>_trait` predicate, and compiler-generated closures (names starting
with `#`). The first remaining frame is the user-facing caller.

# Returns
- `Symbol`: The name of the calling function, or `:unknown` if it cannot be determined.
"""
function _caller_function_name()
    stack = stacktrace()
    for frame in stack
        func_name = frame.func
        func_str = string(func_name)
        startswith(func_str, "#") && continue
        func_str == "_caller_function_name" && continue
        func_str == "_throw_missing_trait" && continue
        func_str == "_throw_trait_not_implemented" && continue
        (startswith(func_str, "has_") && endswith(func_str, "_trait")) && continue
        return func_name
    end
    return :unknown
end

"""
    _throw_missing_trait(obj, has_method::Symbol, accessor::Symbol, family::AbstractString)

Throw the standard [`CTBase.Exceptions.IncorrectArgument`](@ref) used by the
fallback `has_<family>_trait(::Any)` method when an object does not opt into a
strict trait family.

The offending caller is detected automatically from the stacktrace via
[`_caller_function_name`](@ref), so the message names the user-facing predicate
(`is_autonomous`, `is_variable`, …) rather than the internal machinery.

# Arguments
- `obj`: The object that lacks the trait.
- `has_method::Symbol`: Name of the `has_<family>_trait` method to implement.
- `accessor::Symbol`: Name of the trait accessor to implement (`time_dependence`, …).
- `family::AbstractString`: Human-readable family name (e.g. `"time-dependence"`).

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): Always.
"""
function _throw_missing_trait(
    obj, has_method::Symbol, accessor::Symbol, family::AbstractString
)
    source_method = _caller_function_name()
    return throw(
        Exceptions.IncorrectArgument(
            "Cannot call $(source_method) on object of type $(typeof(obj)): no $(family) trait";
            suggestion="Implement $(has_method)(obj::$(typeof(obj))) = true and $(accessor)(obj::$(typeof(obj))) to enable $(family) trait support.",
            context="$(uppercasefirst(family)) trait not available",
        ),
    )
end

"""
    _throw_trait_not_implemented(obj, accessor::Symbol, family::AbstractString, valid::AbstractString)

Throw the standard [`CTBase.Exceptions.NotImplemented`](@ref) used by the fallback
accessor (`time_dependence(::Any)`, …) of a strict trait family when the object
declares the trait but does not implement the accessor.

# Arguments
- `obj`: The object whose accessor is missing.
- `accessor::Symbol`: Name of the trait accessor to implement.
- `family::AbstractString`: Human-readable family name (e.g. `"time-dependence"`).
- `valid::AbstractString`: Human-readable list of valid trait values
  (e.g. `"Autonomous or NonAutonomous"`).

# Throws
- [`CTBase.Exceptions.NotImplemented`](@ref): Always.
"""
function _throw_trait_not_implemented(
    obj, accessor::Symbol, family::AbstractString, valid::AbstractString
)
    return throw(
        Exceptions.NotImplemented(
            "$(accessor) not implemented for $(typeof(obj))";
            required_method="$(accessor)(obj::$(typeof(obj)))",
            suggestion="Implement $(accessor) for your concrete object type to return the specific $(family) trait ($(valid)).",
            context="$(uppercasefirst(family)) trait - required method implementation",
        ),
    )
end
