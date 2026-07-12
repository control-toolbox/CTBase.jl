"""
$(TYPEDEF)

Parametric container for a vector-field function together with its
time-dependence, variable-dependence, and mutability traits.

# Type Parameters
- `F`: concrete type of the wrapped function.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.
- `MD <: AbstractMutabilityTrait`: `InPlace` or `OutOfPlace`.

# Fields
- `f::F`: the vector-field function.

# Construction

Use the keyword constructor:

```julia
VectorField(f; is_autonomous = true, is_variable = false)        # default: f(x)
VectorField((t, x) -> ...; is_autonomous = false)                # f(t, x)
VectorField((x, v) -> ...; is_variable = true)                   # f(x, v)
VectorField((t, x, v) -> ...; is_autonomous = false, is_variable = true)
```

The mutability trait (InPlace/OutOfPlace) is auto-detected from the function signature.

# Call Signatures

Every `VectorField` is callable via its **natural** signature (matching the
traits), and via a **uniform** signature `(t, x, v)` that ignores the
unused arguments — this uniform form is used internally to build the right-hand
side of the ODE in a trait-agnostic way.

For InPlace vector fields, the natural signature includes the derivative buffer
as the first argument (e.g., `(dx, x)` for Autonomous/Fixed).

See also: [`CTBase.Data.AbstractVectorField`](@ref), [`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref), [`CTBase.Traits.AbstractMutabilityTrait`](@ref).
"""
struct VectorField{
    F<:Function,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
} <: AbstractVectorField{TD,VD,MD}
    f::F
end

# =============================================================================
# Internal helpers for mutability detection
# =============================================================================

"""
    _oop_arity_vf(::Type{Traits.Autonomous}, ::Type{Traits.Fixed}) -> Int

Return the out-of-place arity for Autonomous/Fixed vector fields (1: x).
"""
_oop_arity_vf(::Type{Traits.Autonomous}, ::Type{Traits.Fixed}) = 1

"""
    _oop_arity_vf(::Type{Traits.NonAutonomous}, ::Type{Traits.Fixed}) -> Int

Return the out-of-place arity for NonAutonomous/Fixed vector fields (2: t, x).
"""
_oop_arity_vf(::Type{Traits.NonAutonomous}, ::Type{Traits.Fixed}) = 2

"""
    _oop_arity_vf(::Type{Traits.Autonomous}, ::Type{Traits.NonFixed}) -> Int

Return the out-of-place arity for Autonomous/NonFixed vector fields (2: x, v).
"""
_oop_arity_vf(::Type{Traits.Autonomous}, ::Type{Traits.NonFixed}) = 2

"""
    _oop_arity_vf(::Type{Traits.NonAutonomous}, ::Type{Traits.NonFixed}) -> Int

Return the out-of-place arity for NonAutonomous/NonFixed vector fields (3: t, x, v).
"""
_oop_arity_vf(::Type{Traits.NonAutonomous}, ::Type{Traits.NonFixed}) = 3

"""
    _detect_mutability_vf(f::Function, TD, VD) -> Type{<:AbstractMutabilityTrait}

Detect the mutability trait from the function signature.

Compares the function arity to the expected out-of-place arity and in-place arity
(arity + 1 for VectorField). Returns `InPlace` or `OutOfPlace` accordingly.

If the function has multiple methods, throws a `PreconditionError` indicating that
auto-detection is ambiguous and the user should specify `is_inplace` explicitly.

# Arguments
- `f::Function`: The vector-field function.
- `TD`: Time dependence trait type.
- `VD`: Variable dependence trait type.

# Returns
- `Type{InPlace}` or `Type{OutOfPlace}`.

# Throws
- `Exceptions.PreconditionError`: If the function has multiple methods, making automatic arity detection ambiguous.
- `Exceptions.IncorrectArgument`: If the arity is invalid (does not match expected out-of-place or in-place arity).

# Notes
- This function is called automatically by the `VectorField` constructor when `is_inplace` is `nothing`.
- Users can bypass auto-detection by specifying `is_inplace=true` or `is_inplace=false` explicitly in the constructor.

See also: [`CTBase.Data.VectorField`](@ref), [`CTBase.Traits.InPlace`](@ref), [`CTBase.Traits.OutOfPlace`](@ref).
"""
function _detect_mutability_vf(f::Function, TD, VD)
    method_count = length(methods(f))
    if method_count > 1
        throw(
            Exceptions.PreconditionError(
                "Cannot auto-detect mutability: function has multiple methods";
                reason="The function has $method_count methods, making automatic arity detection ambiguous",
                suggestion="Specify `is_inplace=true` or `is_inplace=false` explicitly in the constructor",
                context="VectorField mutability detection",
            ),
        )
    end

    arity = first(methods(f)).nargs - 1
    oop_arity = _oop_arity_vf(TD, VD)
    ip_arity = oop_arity + 1

    if arity == oop_arity
        return Traits.OutOfPlace
    elseif arity == ip_arity
        return Traits.InPlace
    else
        throw(
            Exceptions.IncorrectArgument(
                "Invalid function arity: expected $oop_arity (out-of-place) or $ip_arity (in-place), got $arity";
                suggestion="Ensure your function signature matches the expected pattern for the given traits.",
                context="VectorField mutability detection",
            ),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Construct a `VectorField` with trait flags.

# Arguments
- `f::Function`: The vector-field function.
- `is_autonomous::Bool`: If true, system is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, system depends on variable parameters (default: `__is_variable()`).
- `is_inplace::Union{Bool, Nothing}`: If true, function is in-place; if false, function is out-of-place; if `nothing`, mutability is auto-detected from function signature (default: `__is_inplace()`).

# Returns
- `VectorField`: A VectorField with appropriate traits.

# Example
\`\`\`julia-repl
julia> using CTBase.Data

julia> vf = VectorField(x -> -x)  # Uses defaults: is_autonomous=true, is_variable=false
VectorField: autonomous, fixed (no variable), out-of-place
  natural call: f(x)
  uniform call: f(t, x, v)

julia> vf = VectorField((t, x) -> t .* x; is_autonomous=false)
VectorField: non-autonomous, fixed (no variable), out-of-place
  natural call: f(t, x)
  uniform call: f(t, x, v)

julia> vf = VectorField(x -> -x; is_inplace=true)  # Explicit in-place
VectorField: autonomous, fixed (no variable), in-place
  natural call: f(dx, x)
  uniform call: f(dx, t, x, v)
\`\`\`

# Notes
- If `is_inplace` is `nothing` (default), the mutability is auto-detected from the function signature by checking the number of arguments.
- If the function has multiple methods, auto-detection will fail with a `PreconditionError`. In this case, specify `is_inplace` explicitly.

See also: [`CTBase.Data.VectorField`](@ref), [`CTBase.Traits.Autonomous`](@ref), [`CTBase.Traits.NonAutonomous`](@ref), [`CTBase.Traits.Fixed`](@ref), [`CTBase.Traits.NonFixed`](@ref), [`CTBase.Traits.InPlace`](@ref), [`CTBase.Traits.OutOfPlace`](@ref).
"""
function VectorField(
    f;
    is_autonomous::Bool=__is_autonomous(),
    is_variable::Bool=__is_variable(),
    is_inplace::Union{Bool,Nothing}=__is_inplace(),
)
    TD = is_autonomous ? Traits.Autonomous : Traits.NonAutonomous
    VD = is_variable ? Traits.NonFixed : Traits.Fixed
    MD = if is_inplace === nothing
        _detect_mutability_vf(f, TD, VD)
    else
        is_inplace ? Traits.InPlace : Traits.OutOfPlace
    end
    return VectorField{typeof(f),TD,VD,MD}(f)
end

# =============================================================================
# Typed constructor — calls struct inner constructor directly
# =============================================================================

function VectorField(
    f, ::Type{TD}, ::Type{VD}, ::Type{MD}
) where {
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
}
    return VectorField{typeof(f),TD,VD,MD}(f)
end

# =============================================================================
# Natural call signatures - one per trait combination
# =============================================================================

# OutOfPlace signatures (existing)
(F::VectorField{<:Function,Traits.Autonomous,Traits.Fixed,Traits.OutOfPlace})(x) = F.f(x)
function (F::VectorField{<:Function,Traits.NonAutonomous,Traits.Fixed,Traits.OutOfPlace})(
    t, x
)
    return F.f(t, x)
end
function (F::VectorField{<:Function,Traits.Autonomous,Traits.NonFixed,Traits.OutOfPlace})(
    x, v
)
    return F.f(x, v)
end
function (F::VectorField{<:Function,Traits.NonAutonomous,Traits.NonFixed,Traits.OutOfPlace})(
    t, x, v
)
    return F.f(t, x, v)
end

# InPlace signatures (new)
function (F::VectorField{<:Function,Traits.Autonomous,Traits.Fixed,Traits.InPlace})(dx, x)
    return F.f(dx, x)
end
function (F::VectorField{<:Function,Traits.NonAutonomous,Traits.Fixed,Traits.InPlace})(
    dx, t, x
)
    return F.f(dx, t, x)
end
function (F::VectorField{<:Function,Traits.Autonomous,Traits.NonFixed,Traits.InPlace})(
    dx, x, v
)
    return F.f(dx, x, v)
end
function (F::VectorField{<:Function,Traits.NonAutonomous,Traits.NonFixed,Traits.InPlace})(
    dx, t, x, v
)
    return F.f(dx, t, x, v)
end

# =============================================================================
# Uniform (t, x, v) call - used by VectorFieldSystem.rhs
# Every combination forwards to its natural call, ignoring unused args.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
# =============================================================================

# OutOfPlace uniform signatures (existing)
function (F::VectorField{<:Function,Traits.Autonomous,Traits.Fixed,Traits.OutOfPlace})(
    t, x, v
)
    return F.f(x)
end
function (F::VectorField{<:Function,Traits.NonAutonomous,Traits.Fixed,Traits.OutOfPlace})(
    t, x, v
)
    return F.f(t, x)
end
function (F::VectorField{<:Function,Traits.Autonomous,Traits.NonFixed,Traits.OutOfPlace})(
    t, x, v
)
    return F.f(x, v)
end

# InPlace uniform signatures (new)
function (F::VectorField{<:Function,Traits.Autonomous,Traits.Fixed,Traits.InPlace})(
    dx, t, x, v
)
    return F.f(dx, x)
end
function (F::VectorField{<:Function,Traits.NonAutonomous,Traits.Fixed,Traits.InPlace})(
    dx, t, x, v
)
    return F.f(dx, t, x)
end
function (F::VectorField{<:Function,Traits.Autonomous,Traits.NonFixed,Traits.InPlace})(
    dx, t, x, v
)
    return F.f(dx, x, v)
end

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a VectorField.

Shows the type name, time dependence, variable dependence, mutability, and function type.

# Arguments
- `io::IO`: The IO stream to write to.
- `vf::VectorField`: The VectorField to display.

See also: [`CTBase.Data.VectorField`](@ref).
"""
function Base.show(
    io::IO, vf::VectorField{F,TD,VD,MD}
) where {
    F<:Function,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
}
    header = "VectorField: $(_td_label(TD)), $(_vd_label(VD)), $(_md_label(MD))"
    natural = _natural_sig_vf(TD, VD, MD)
    uniform = _uniform_sig_vf(MD)
    println(io, header)
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: ", uniform)
end

"""
$(TYPEDSIGNATURES)

Display a VectorField in the REPL with text/plain MIME type.

Delegates to the compact show method.

# Arguments
- `io::IO`: The IO stream to write to.
- `::MIME"text/plain"`: The MIME type for REPL display.
- `vf::VectorField`: The VectorField to display.

See also: [`CTBase.Data.VectorField`](@ref).
"""
function Base.show(
    io::IO, ::MIME"text/plain", vf::VectorField{F,TD,VD,MD}
) where {
    F<:Function,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
}
    return show(io, vf)
end
