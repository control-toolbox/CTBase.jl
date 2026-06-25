"""
$(TYPEDEF)

Abstract trait for mutability characteristics of function evaluation.

Distinguishes between in-place functions (which modify a pre-allocated buffer)
and out-of-place functions (which allocate and return new results).

Subtypes must implement:
- `InPlace`: For functions that write to a mutable buffer
- `OutOfPlace`: For functions that return newly allocated results

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> InPlace() isa AbstractMutabilityTrait
true

julia> OutOfPlace() isa AbstractMutabilityTrait
true
\`\`\`

See also: [`CTBase.Traits.InPlace`](@ref), [`CTBase.Traits.OutOfPlace`](@ref).
"""
abstract type AbstractMutabilityTrait <: AbstractTrait end

"""
$(TYPEDEF)

Trait for in-place function evaluation.

Indicates that a function modifies a pre-allocated buffer passed as an argument,
rather than allocating and returning a new result. This pattern is used for
performance-critical code where avoiding allocations is important.

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> ip = InPlace()
InPlace()

julia> ip isa AbstractMutabilityTrait
true
\`\`\`

See also: [`CTBase.Traits.AbstractMutabilityTrait`](@ref), [`CTBase.Traits.OutOfPlace`](@ref).
"""
struct InPlace <: AbstractMutabilityTrait end

"""
$(TYPEDEF)

Trait for out-of-place function evaluation.

Indicates that a function allocates and returns a new result, rather than
modifying a pre-allocated buffer. This is the default pattern in Julia and
is suitable for most use cases.

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> oop = OutOfPlace()
OutOfPlace()

julia> oop isa AbstractMutabilityTrait
true
\`\`\`

See also: [`CTBase.Traits.AbstractMutabilityTrait`](@ref), [`CTBase.Traits.InPlace`](@ref).
"""
struct OutOfPlace <: AbstractMutabilityTrait end

"""
$(TYPEDSIGNATURES)

Check if the object has the mutability trait.

This fallback method throws an error indicating the object does not support
mutability queries. Concrete types that have the trait should implement
`has_mutability_trait(obj::MyType) = true`.

The calling function name is automatically detected from the stacktrace
for better error messages.

# Arguments
- `obj::Any`: The object to check.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): Always, indicating the object does not have the trait.

See also: [`CTBase.Traits.AbstractMutabilityTrait`](@ref), [`CTBase.Traits.mutability`](@ref).
"""
function has_mutability_trait(obj::Any)
    source_method = _caller_function_name()
    return throw(
        Exceptions.IncorrectArgument(
            "Cannot call $(source_method) on object of type $(typeof(obj)): no mutability trait";
            suggestion="Implement has_mutability_trait(obj::$(typeof(obj))) = true and mutability(obj::$(typeof(obj))) to enable mutability trait support.",
            context="Mutability trait not available",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Return the mutability trait value for the object.

This fallback method throws an error indicating the method is not implemented.
Concrete types that have the trait should implement `mutability(obj::MyType)`
to return the specific trait value (`InPlace` or `OutOfPlace`).

# Arguments
- `obj::Any`: The object to query.

# Throws
- [`CTBase.Exceptions.NotImplemented`](@ref): Always, indicating the method must be implemented.

See also: [`CTBase.Traits.AbstractMutabilityTrait`](@ref), [`CTBase.Traits.has_mutability_trait`](@ref).
"""
function mutability(obj::Any)
    has_mutability_trait(obj)
    return throw(
        Exceptions.NotImplemented(
            "mutability not implemented for $(typeof(obj))";
            required_method="mutability(obj::$(typeof(obj)))",
            suggestion="Implement mutability for your concrete object type to return the specific mutability trait (InPlace or OutOfPlace).",
            context="Mutability trait - required method implementation",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Return true if the object uses in-place function evaluation.

Checks that the object has the mutability trait, then returns true
if `mutability(obj)` is `InPlace`.

# Arguments
- `obj::Any`: The object to check.

# Returns
- `Bool`: true if the object uses in-place evaluation.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): If the object does not support mutability queries.
- [`CTBase.Exceptions.NotImplemented`](@ref): If `mutability` is not implemented for the object type.

See also: [`CTBase.Traits.AbstractMutabilityTrait`](@ref), [`CTBase.Traits.mutability`](@ref).
"""
function is_inplace(obj::Any)
    has_mutability_trait(obj)
    return mutability(obj) === InPlace
end

"""
$(TYPEDSIGNATURES)

Return true if the object uses out-of-place function evaluation.

Checks that the object has the mutability trait, then returns true
if `mutability(obj)` is `OutOfPlace`.

# Arguments
- `obj::Any`: The object to check.

# Returns
- `Bool`: true if the object uses out-of-place evaluation.

# Throws
- [`CTBase.Exceptions.IncorrectArgument`](@ref): If the object does not support mutability queries.
- [`CTBase.Exceptions.NotImplemented`](@ref): If `mutability` is not implemented for the object type.

See also: [`CTBase.Traits.AbstractMutabilityTrait`](@ref), [`CTBase.Traits.mutability`](@ref).
"""
function is_outofplace(obj::Any)
    has_mutability_trait(obj)
    return mutability(obj) === OutOfPlace
end
