"""
$(TYPEDEF)

Parametric container for a Hamiltonian vector field function together with its
time-dependence, variable-dependence, and mutability traits.

The function returns a tuple `(dx, dp)` representing the derivatives of state `x`
and costate `p` according to Hamiltonian dynamics.

# Type Parameters
- `F`: concrete type of the wrapped function.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.
- `MD <: AbstractMutabilityTrait`: `InPlace` or `OutOfPlace`.

# Fields
- `f::F`: the Hamiltonian vector field function.

# Construction

Use the keyword constructor:

```julia
HamiltonianVectorField(f; is_autonomous = true, is_variable = false)        # default: f(x, p)
HamiltonianVectorField((t, x, p) -> ...; is_autonomous = false)             # f(t, x, p)
HamiltonianVectorField((x, p, v) -> ...; is_variable = true)                # f(x, p, v)
HamiltonianVectorField((t, x, p, v) -> ...; is_autonomous = false, is_variable = true)
```

The mutability trait (InPlace/OutOfPlace) is auto-detected from the function signature.

# Call Signatures

Every `HamiltonianVectorField` is callable via its **natural** signature (matching the
traits), and via a **uniform** signature `(t, x, p, v)` that ignores the
unused arguments.

For InPlace Hamiltonian vector fields, the natural signature includes the derivative
buffers as the first two arguments (e.g., `(dx, dp, x, p)` for Autonomous/Fixed).

See also: [`CTBase.Data.AbstractVectorField`](@ref), [`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref), [`CTBase.Traits.AbstractMutabilityTrait`](@ref).
"""
struct HamiltonianVectorField{
    F<:Function,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
} <: AbstractHamiltonianVectorField{TD,VD,MD}
    f::F
end

# =============================================================================
# Internal helpers for mutability detection
# =============================================================================

"""
    _oop_arity_hvf(::Type{Traits.Autonomous}, ::Type{Traits.Fixed}) -> Int

Return the out-of-place arity for Autonomous/Fixed Hamiltonian vector fields (2: x, p).
"""
_oop_arity_hvf(::Type{Traits.Autonomous}, ::Type{Traits.Fixed}) = 2

"""
    _oop_arity_hvf(::Type{Traits.NonAutonomous}, ::Type{Traits.Fixed}) -> Int

Return the out-of-place arity for NonAutonomous/Fixed Hamiltonian vector fields (3: t, x, p).
"""
_oop_arity_hvf(::Type{Traits.NonAutonomous}, ::Type{Traits.Fixed}) = 3

"""
    _oop_arity_hvf(::Type{Traits.Autonomous}, ::Type{Traits.NonFixed}) -> Int

Return the out-of-place arity for Autonomous/NonFixed Hamiltonian vector fields (3: x, p, v).
"""
_oop_arity_hvf(::Type{Traits.Autonomous}, ::Type{Traits.NonFixed}) = 3

"""
    _oop_arity_hvf(::Type{Traits.NonAutonomous}, ::Type{Traits.NonFixed}) -> Int

Return the out-of-place arity for NonAutonomous/NonFixed Hamiltonian vector fields (4: t, x, p, v).
"""
_oop_arity_hvf(::Type{Traits.NonAutonomous}, ::Type{Traits.NonFixed}) = 4

"""
    _detect_mutability_hvf(f::Function, TD, VD) -> Type{<:AbstractMutabilityTrait}

Detect the mutability trait from the Hamiltonian vector field function signature.

Compares the function arity to the expected out-of-place arity and in-place arity
(arity + 2 for HamiltonianVectorField, which has two output buffers). Returns `InPlace` or `OutOfPlace` accordingly.

If the function has multiple methods, throws a `PreconditionError` indicating that
auto-detection is ambiguous and the user should specify `is_inplace` explicitly.

# Arguments
- `f::Function`: The Hamiltonian vector-field function.
- `TD`: Time dependence trait type.
- `VD`: Variable dependence trait type.

# Returns
- `Type{InPlace}` or `Type{OutOfPlace}`.

# Throws
- `Exceptions.PreconditionError`: If the function has multiple methods, making automatic arity detection ambiguous.
- `Exceptions.IncorrectArgument`: If the arity is invalid (does not match expected out-of-place or in-place arity).

# Notes
- This function is called automatically by the `HamiltonianVectorField` constructor when `is_inplace` is `nothing`.
- Users can bypass auto-detection by specifying `is_inplace=true` or `is_inplace=false` explicitly in the constructor.
- HamiltonianVectorField has two output buffers (dx, dp), so the in-place arity is `oop_arity + 2`.

See also: [`CTBase.Data.HamiltonianVectorField`](@ref), [`CTBase.Traits.InPlace`](@ref), [`CTBase.Traits.OutOfPlace`](@ref).
"""
function _detect_mutability_hvf(f::Function, TD, VD)
    method_count = length(methods(f))
    if method_count > 1
        throw(
            Exceptions.PreconditionError(
                "Cannot auto-detect mutability: function has multiple methods";
                reason="The function has $method_count methods, making automatic arity detection ambiguous",
                suggestion="Specify `is_inplace=true` or `is_inplace=false` explicitly in the constructor",
                context="HamiltonianVectorField mutability detection",
            ),
        )
    end

    arity = first(methods(f)).nargs - 1
    oop_arity = _oop_arity_hvf(TD, VD)
    ip_arity = oop_arity + 2  # HamiltonianVectorField has two output buffers (dx, dp)

    if arity == oop_arity
        return Traits.OutOfPlace
    elseif arity == ip_arity
        return Traits.InPlace
    else
        throw(
            Exceptions.IncorrectArgument(
                "Invalid function arity: expected $oop_arity (out-of-place) or $ip_arity (in-place), got $arity";
                suggestion="Ensure your function signature matches the expected pattern for the given traits.",
                context="HamiltonianVectorField mutability detection",
            ),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Construct a `HamiltonianVectorField` with trait flags.

# Arguments
- `f::Function`: The Hamiltonian vector field function returning `(dx, dp)`.
- `is_autonomous::Bool`: If true, system is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, system depends on variable parameters (default: `__is_variable()`).
- `is_inplace::Union{Bool, Nothing}`: If true, function is in-place; if false, function is out-of-place; if `nothing`, mutability is auto-detected from function signature (default: `__is_inplace()`).

# Returns
- `HamiltonianVectorField`: A HamiltonianVectorField with appropriate traits.

# Example
```julia-repl
julia> using CTBase.Data

julia> hvf = HamiltonianVectorField((x, p) -> (x, -p))  # Uses defaults: is_autonomous=true, is_variable=false
HamiltonianVectorField: autonomous, fixed (no variable), out-of-place
  natural call: f(x, p)
  uniform call: f(t, x, p, v)

julia> hvf = HamiltonianVectorField((t, x, p) -> (t .* x, -p); is_autonomous=false)
HamiltonianVectorField: non-autonomous, fixed (no variable), out-of-place
  natural call: f(t, x, p)
  uniform call: f(t, x, p, v)

julia> hvf = HamiltonianVectorField((x, p) -> (x, -p); is_inplace=true)  # Explicit in-place
HamiltonianVectorField: autonomous, fixed (no variable), in-place
  natural call: f(dx, dp, x, p)
  uniform call: f(dx, dp, t, x, p, v)
```

# Notes
- If `is_inplace` is `nothing` (default), the mutability is auto-detected from the function signature by checking the number of arguments.
- If the function has multiple methods, auto-detection will fail with a `PreconditionError`. In this case, specify `is_inplace` explicitly.

See also: [`CTBase.Data.HamiltonianVectorField`](@ref), [`CTBase.Traits.Autonomous`](@ref), [`CTBase.Traits.NonAutonomous`](@ref), [`CTBase.Traits.Fixed`](@ref), [`CTBase.Traits.NonFixed`](@ref), [`CTBase.Traits.InPlace`](@ref), [`CTBase.Traits.OutOfPlace`](@ref).
"""
function HamiltonianVectorField(
    f;
    is_autonomous::Bool=__is_autonomous(),
    is_variable::Bool=__is_variable(),
    is_inplace::Union{Bool,Nothing}=__is_inplace(),
)
    TD = is_autonomous ? Traits.Autonomous : Traits.NonAutonomous
    VD = is_variable ? Traits.NonFixed : Traits.Fixed
    MD = if is_inplace === nothing
        _detect_mutability_hvf(f, TD, VD)
    else
        is_inplace ? Traits.InPlace : Traits.OutOfPlace
    end
    return HamiltonianVectorField{typeof(f),TD,VD,MD}(f)
end

# =============================================================================
# Typed constructor — calls struct inner constructor directly
# =============================================================================

function HamiltonianVectorField(
    f, ::Type{TD}, ::Type{VD}, ::Type{MD}
) where {
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
}
    return HamiltonianVectorField{typeof(f),TD,VD,MD}(f)
end

# =============================================================================
# Natural call signatures - one per trait combination
# =============================================================================

# OutOfPlace signatures (existing)
function (H::HamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.Fixed,Traits.OutOfPlace
})(
    x, p
)
    return H.f(x, p)
end
function (H::HamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.Fixed,Traits.OutOfPlace
})(
    t, x, p
)
    return H.f(t, x, p)
end
function (H::HamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.NonFixed,Traits.OutOfPlace
})(
    x, p, v; variable_costate::Bool=false
)
    variable_costate || return H.f(x, p, v)
    hasmethod(H.f, Tuple{typeof(x),typeof(p),typeof(v)}, (:variable_costate,)) || throw(
        Exceptions.PreconditionError(
            "variable_costate=true is not supported by this HamiltonianVectorField's inner function";
            suggestion="Use hamiltonian_vector_field(h; ...) to obtain a HVF that supports variable_costate",
            context="HamiltonianVectorField Autonomous/NonFixed call",
        ),
    )
    return H.f(x, p, v; variable_costate=true)
end

function (H::HamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.NonFixed,Traits.OutOfPlace
})(
    t, x, p, v; variable_costate::Bool=false
)
    variable_costate || return H.f(t, x, p, v)
    hasmethod(H.f, Tuple{typeof(t),typeof(x),typeof(p),typeof(v)}, (:variable_costate,)) ||
        throw(
            Exceptions.PreconditionError(
                "variable_costate=true is not supported by this HamiltonianVectorField's inner function";
                suggestion="Use hamiltonian_vector_field(h; ...) to obtain a HVF that supports variable_costate",
                context="HamiltonianVectorField NonAutonomous/NonFixed call",
            ),
        )
    return H.f(t, x, p, v; variable_costate=true)
end

# InPlace signatures (new)
function (H::HamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.Fixed,Traits.InPlace
})(
    dx, dp, x, p
)
    return H.f(dx, dp, x, p)
end
function (H::HamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.Fixed,Traits.InPlace
})(
    dx, dp, t, x, p
)
    return H.f(dx, dp, t, x, p)
end
function (H::HamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.NonFixed,Traits.InPlace
})(
    dx, dp, x, p, v; dpv=nothing, variable_costate::Bool=false
)
    variable_costate || return H.f(dx, dp, x, p, v)
    hasmethod(
        H.f,
        Tuple{typeof(dx),typeof(dp),typeof(x),typeof(p),typeof(v)},
        (:variable_costate,),
    ) || throw(
        Exceptions.PreconditionError(
            "variable_costate=true is not supported by this HamiltonianVectorField's inner function";
            suggestion="Use hamiltonian_vector_field(h; inplace=true) to obtain a HVF that supports variable_costate",
            context="HamiltonianVectorField IP Autonomous/NonFixed call",
        ),
    )
    return H.f(dx, dp, x, p, v; dpv=dpv, variable_costate=true)
end

function (H::HamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.NonFixed,Traits.InPlace
})(
    dx, dp, t, x, p, v; dpv=nothing, variable_costate::Bool=false
)
    variable_costate || return H.f(dx, dp, t, x, p, v)
    hasmethod(
        H.f,
        Tuple{typeof(dx),typeof(dp),typeof(t),typeof(x),typeof(p),typeof(v)},
        (:variable_costate,),
    ) || throw(
        Exceptions.PreconditionError(
            "variable_costate=true is not supported by this HamiltonianVectorField's inner function";
            suggestion="Use hamiltonian_vector_field(h; inplace=true) to obtain a HVF that supports variable_costate",
            context="HamiltonianVectorField IP NonAutonomous/NonFixed call",
        ),
    )
    return H.f(dx, dp, t, x, p, v; dpv=dpv, variable_costate=true)
end

# =============================================================================
# Uniform (t, x, p, v) call - used by HamiltonianVectorFieldSystem.rhs
# Every combination forwards to its natural call, ignoring unused args.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
# =============================================================================

# OutOfPlace uniform signatures
function (H::HamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.Fixed,Traits.OutOfPlace
})(
    t, x, p, v; variable_costate::Bool=false
)
    return H.f(x, p)
end
function (H::HamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.Fixed,Traits.OutOfPlace
})(
    t, x, p, v; variable_costate::Bool=false
)
    return H.f(t, x, p)
end
function (H::HamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.NonFixed,Traits.OutOfPlace
})(
    t, x, p, v; variable_costate::Bool=false
)
    return H(x, p, v; variable_costate=variable_costate)
end # delegate to natural signature

# InPlace uniform signatures
function (H::HamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.Fixed,Traits.InPlace
})(
    dx, dp, t, x, p, v; variable_costate::Bool=false, dpv=nothing
)
    return H.f(dx, dp, x, p)
end
function (H::HamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.Fixed,Traits.InPlace
})(
    dx, dp, t, x, p, v; variable_costate::Bool=false, dpv=nothing
)
    return H.f(dx, dp, t, x, p)
end
function (H::HamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.NonFixed,Traits.InPlace
})(
    dx, dp, t, x, p, v; variable_costate::Bool=false, dpv=nothing
)
    return H(dx, dp, x, p, v; dpv=dpv, variable_costate=variable_costate)
end # delegate to natural signature

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a HamiltonianVectorField.

Shows the type name, time dependence, variable dependence, mutability, and function type.

# Arguments
- `io::IO`: The IO stream to write to.
- `hvf::HamiltonianVectorField`: The HamiltonianVectorField to display.

See also: [`CTBase.Data.HamiltonianVectorField`](@ref).
"""
function Base.show(
    io::IO, ::HamiltonianVectorField{F,TD,VD,MD}
) where {
    F<:Function,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
}
    header = "HamiltonianVectorField: $(_td_label(TD)), $(_vd_label(VD)), $(_md_label(MD))"
    natural = _natural_sig_hvf(TD, VD, MD)
    uniform = _uniform_sig_hvf(MD)
    println(io, header)
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: ", uniform)
end

"""
$(TYPEDSIGNATURES)

Display a HamiltonianVectorField in the REPL with text/plain MIME type.

Delegates to the compact show method.

# Arguments
- `io::IO`: The IO stream to write to.
- `::MIME"text/plain"`: The MIME type for REPL display.
- `hvf::HamiltonianVectorField`: The HamiltonianVectorField to display.

See also: [`CTBase.Data.HamiltonianVectorField`](@ref).
"""
function Base.show(
    io::IO, ::MIME"text/plain", hvf::HamiltonianVectorField{F,TD,VD,MD}
) where {
    F<:Function,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
}
    return show(io, hvf)
end
