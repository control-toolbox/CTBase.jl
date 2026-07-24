# =============================================================================
# Concrete PseudoHamiltonianVectorField type
# =============================================================================

"""
$(TYPEDEF)

Parametric container for a pseudo-Hamiltonian vector field function together with its
time-dependence, variable-dependence, and mutability traits.

The function returns a tuple `(dx, dp)` representing the already-differentiated
derivatives of state `x` and costate `p`, with an explicit control argument `u` — the
vector-field analogue of [`CTBase.Data.PseudoHamiltonian`](@ref), just as
[`CTBase.Data.HamiltonianVectorField`](@ref) is the vector-field analogue of
[`CTBase.Data.Hamiltonian`](@ref).

# Type Parameters
- `F`: concrete type of the wrapped function.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.
- `MD <: AbstractMutabilityTrait`: `InPlace` or `OutOfPlace`.

# Fields
- `f::F`: the pseudo-Hamiltonian vector field function.

# Construction

Use the keyword constructor:

```julia
PseudoHamiltonianVectorField(f; is_autonomous = true, is_variable = false)        # default: f(x, p, u)
PseudoHamiltonianVectorField((t, x, p, u) -> ...; is_autonomous = false)          # f(t, x, p, u)
PseudoHamiltonianVectorField((x, p, u, v) -> ...; is_variable = true)            # f(x, p, u, v)
PseudoHamiltonianVectorField((t, x, p, u, v) -> ...; is_autonomous = false, is_variable = true)
```

The mutability trait (InPlace/OutOfPlace) is auto-detected from the function signature.

# Call Signatures

Every `PseudoHamiltonianVectorField` is callable via its **natural** signature (matching
the traits), and via a **uniform** signature `(t, x, p, u, v)` that ignores the
unused arguments.

For InPlace pseudo-Hamiltonian vector fields, the natural signature includes the
derivative buffers as the first two arguments (e.g., `(dx, dp, x, p, u)` for
Autonomous/Fixed).

See also: [`CTBase.Data.AbstractPseudoHamiltonianVectorField`](@ref),
[`CTBase.Data.PseudoHamiltonian`](@ref), [`CTBase.Data.HamiltonianVectorField`](@ref),
[`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
struct PseudoHamiltonianVectorField{
    F<:Function,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
} <: AbstractPseudoHamiltonianVectorField{TD,VD,MD}
    f::F
end

# =============================================================================
# Internal helpers for mutability detection
# =============================================================================

"""
    _oop_arity_phvf(::Type{Traits.Autonomous}, ::Type{Traits.Fixed}) -> Int

Return the out-of-place arity for Autonomous/Fixed pseudo-Hamiltonian vector fields
(3: x, p, u).
"""
_oop_arity_phvf(::Type{Traits.Autonomous}, ::Type{Traits.Fixed}) = 3

"""
    _oop_arity_phvf(::Type{Traits.NonAutonomous}, ::Type{Traits.Fixed}) -> Int

Return the out-of-place arity for NonAutonomous/Fixed pseudo-Hamiltonian vector fields
(4: t, x, p, u).
"""
_oop_arity_phvf(::Type{Traits.NonAutonomous}, ::Type{Traits.Fixed}) = 4

"""
    _oop_arity_phvf(::Type{Traits.Autonomous}, ::Type{Traits.NonFixed}) -> Int

Return the out-of-place arity for Autonomous/NonFixed pseudo-Hamiltonian vector fields
(4: x, p, u, v).
"""
_oop_arity_phvf(::Type{Traits.Autonomous}, ::Type{Traits.NonFixed}) = 4

"""
    _oop_arity_phvf(::Type{Traits.NonAutonomous}, ::Type{Traits.NonFixed}) -> Int

Return the out-of-place arity for NonAutonomous/NonFixed pseudo-Hamiltonian vector
fields (5: t, x, p, u, v).
"""
_oop_arity_phvf(::Type{Traits.NonAutonomous}, ::Type{Traits.NonFixed}) = 5

"""
    _detect_mutability_phvf(f::Function, TD, VD) -> Type{<:AbstractMutabilityTrait}

Detect the mutability trait from the pseudo-Hamiltonian vector field function
signature.

Compares the function arity to the expected out-of-place arity and in-place arity
(arity + 2 for `PseudoHamiltonianVectorField`, which has two output buffers). Returns
`InPlace` or `OutOfPlace` accordingly.

If the function has multiple methods, throws a `PreconditionError` indicating that
auto-detection is ambiguous and the user should specify `is_inplace` explicitly.

# Arguments
- `f::Function`: The pseudo-Hamiltonian vector-field function.
- `TD`: Time dependence trait type.
- `VD`: Variable dependence trait type.

# Returns
- `Type{InPlace}` or `Type{OutOfPlace}`.

# Throws
- `Exceptions.PreconditionError`: If the function has multiple methods, making
  automatic arity detection ambiguous.
- `Exceptions.IncorrectArgument`: If the arity is invalid (does not match expected
  out-of-place or in-place arity).

# Notes
- This function is called automatically by the `PseudoHamiltonianVectorField`
  constructor when `is_inplace` is `nothing`.
- Users can bypass auto-detection by specifying `is_inplace=true` or `is_inplace=false`
  explicitly in the constructor.

See also: [`CTBase.Data.PseudoHamiltonianVectorField`](@ref), [`CTBase.Traits.InPlace`](@ref),
[`CTBase.Traits.OutOfPlace`](@ref).
"""
function _detect_mutability_phvf(f::Function, TD, VD)
    method_count = length(methods(f))
    if method_count > 1
        throw(
            Exceptions.PreconditionError(
                "Cannot auto-detect mutability: function has multiple methods";
                reason="The function has $method_count methods, making automatic arity detection ambiguous",
                suggestion="Specify `is_inplace=true` or `is_inplace=false` explicitly in the constructor",
                context="PseudoHamiltonianVectorField mutability detection",
            ),
        )
    end

    arity = first(methods(f)).nargs - 1
    oop_arity = _oop_arity_phvf(TD, VD)
    ip_arity = oop_arity + 2  # PseudoHamiltonianVectorField has two output buffers (dx, dp)

    if arity == oop_arity
        return Traits.OutOfPlace
    elseif arity == ip_arity
        return Traits.InPlace
    else
        throw(
            Exceptions.IncorrectArgument(
                "Invalid function arity: expected $oop_arity (out-of-place) or $ip_arity (in-place), got $arity";
                suggestion="Ensure your function signature matches the expected pattern for the given traits.",
                context="PseudoHamiltonianVectorField mutability detection",
            ),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Construct a `PseudoHamiltonianVectorField` with trait flags.

# Arguments
- `f::Function`: The pseudo-Hamiltonian vector field function returning `(dx, dp)`
  (or `(dx, dp, dpv)` when called with `variable_costate=true`).
- `is_autonomous::Bool`: If true, system is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, system depends on variable parameters (default:
  `__is_variable()`).
- `is_inplace::Union{Bool, Nothing}`: If true, function is in-place; if false,
  function is out-of-place; if `nothing`, mutability is auto-detected from function
  signature (default: `__is_inplace()`).

# Returns
- `PseudoHamiltonianVectorField`: A `PseudoHamiltonianVectorField` with appropriate
  traits.

# Example
```julia-repl
julia> using CTBase.Data

julia> h̃vf = PseudoHamiltonianVectorField((x, p, u) -> (u, -p))
PseudoHamiltonianVectorField: autonomous, fixed (no variable), out-of-place
  natural call: f(x, p, u)
  uniform call: f(t, x, p, u, v)
```

# Notes
- If `is_inplace` is `nothing` (default), the mutability is auto-detected from the
  function signature by checking the number of arguments.
- If the function has multiple methods, auto-detection will fail with a
  `PreconditionError`. In this case, specify `is_inplace` explicitly.

See also: [`CTBase.Data.PseudoHamiltonianVectorField`](@ref), [`CTBase.Traits.Autonomous`](@ref),
[`CTBase.Traits.NonAutonomous`](@ref), [`CTBase.Traits.Fixed`](@ref), [`CTBase.Traits.NonFixed`](@ref),
[`CTBase.Traits.InPlace`](@ref), [`CTBase.Traits.OutOfPlace`](@ref).
"""
function PseudoHamiltonianVectorField(
    f;
    is_autonomous::Bool=__is_autonomous(),
    is_variable::Bool=__is_variable(),
    is_inplace::Union{Bool,Nothing}=__is_inplace(),
)
    TD = is_autonomous ? Traits.Autonomous : Traits.NonAutonomous
    VD = is_variable ? Traits.NonFixed : Traits.Fixed
    MD = if is_inplace === nothing
        _detect_mutability_phvf(f, TD, VD)
    else
        is_inplace ? Traits.InPlace : Traits.OutOfPlace
    end
    return PseudoHamiltonianVectorField{typeof(f),TD,VD,MD}(f)
end

# =============================================================================
# Typed constructor — calls struct inner constructor directly
# =============================================================================

"""
$(TYPEDSIGNATURES)

Typed constructor for `PseudoHamiltonianVectorField` with explicit trait types.

# Arguments
- `f`: The pseudo-Hamiltonian vector field function.
- `::Type{TD}`: The time-dependence trait type.
- `::Type{VD}`: The variable-dependence trait type.
- `::Type{MD}`: The mutability trait type.

# Returns
- `PseudoHamiltonianVectorField`: A pseudo-Hamiltonian vector field with the specified
  traits.

See also: [`CTBase.Data.PseudoHamiltonianVectorField`](@ref).
"""
function PseudoHamiltonianVectorField(
    f, ::Type{TD}, ::Type{VD}, ::Type{MD}
) where {
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
}
    return PseudoHamiltonianVectorField{typeof(f),TD,VD,MD}(f)
end

# =============================================================================
# Natural call signatures - one per trait combination
# =============================================================================

# OutOfPlace signatures (natural call, one per TD/VD combination)
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.Fixed,Traits.OutOfPlace
})(
    x, p, u
)
    return H.f(x, p, u)
end
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.Fixed,Traits.OutOfPlace
})(
    t, x, p, u
)
    return H.f(t, x, p, u)
end
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.NonFixed,Traits.OutOfPlace
})(
    x, p, u, v; variable_costate::Bool=false
)
    variable_costate || return H.f(x, p, u, v)
    hasmethod(
        H.f, Tuple{typeof(x),typeof(p),typeof(u),typeof(v)}, (:variable_costate,)
    ) || throw(
        Exceptions.PreconditionError(
            "variable_costate=true is not supported by this PseudoHamiltonianVectorField's inner function";
            suggestion="Provide an inner function accepting a `variable_costate::Bool` keyword and returning `(dx, dp, dpv)` when true",
            context="PseudoHamiltonianVectorField Autonomous/NonFixed call",
        ),
    )
    return H.f(x, p, u, v; variable_costate=true)
end

function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.NonFixed,Traits.OutOfPlace
})(
    t, x, p, u, v; variable_costate::Bool=false
)
    variable_costate || return H.f(t, x, p, u, v)
    hasmethod(
        H.f,
        Tuple{typeof(t),typeof(x),typeof(p),typeof(u),typeof(v)},
        (:variable_costate,),
    ) || throw(
        Exceptions.PreconditionError(
            "variable_costate=true is not supported by this PseudoHamiltonianVectorField's inner function";
            suggestion="Provide an inner function accepting a `variable_costate::Bool` keyword and returning `(dx, dp, dpv)` when true",
            context="PseudoHamiltonianVectorField NonAutonomous/NonFixed call",
        ),
    )
    return H.f(t, x, p, u, v; variable_costate=true)
end

# InPlace signatures (natural call, one per TD/VD combination)
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.Fixed,Traits.InPlace
})(
    dx, dp, x, p, u
)
    return H.f(dx, dp, x, p, u)
end
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.Fixed,Traits.InPlace
})(
    dx, dp, t, x, p, u
)
    return H.f(dx, dp, t, x, p, u)
end
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.NonFixed,Traits.InPlace
})(
    dx, dp, x, p, u, v; dpv=nothing, variable_costate::Bool=false
)
    variable_costate || return H.f(dx, dp, x, p, u, v)
    hasmethod(
        H.f,
        Tuple{typeof(dx),typeof(dp),typeof(x),typeof(p),typeof(u),typeof(v)},
        (:variable_costate,),
    ) || throw(
        Exceptions.PreconditionError(
            "variable_costate=true is not supported by this PseudoHamiltonianVectorField's inner function";
            suggestion="Provide an inner function accepting a `variable_costate::Bool` keyword and filling `dpv` when true",
            context="PseudoHamiltonianVectorField IP Autonomous/NonFixed call",
        ),
    )
    return H.f(dx, dp, x, p, u, v; dpv=dpv, variable_costate=true)
end

function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.NonFixed,Traits.InPlace
})(
    dx, dp, t, x, p, u, v; dpv=nothing, variable_costate::Bool=false
)
    variable_costate || return H.f(dx, dp, t, x, p, u, v)
    hasmethod(
        H.f,
        Tuple{typeof(dx),typeof(dp),typeof(t),typeof(x),typeof(p),typeof(u),typeof(v)},
        (:variable_costate,),
    ) || throw(
        Exceptions.PreconditionError(
            "variable_costate=true is not supported by this PseudoHamiltonianVectorField's inner function";
            suggestion="Provide an inner function accepting a `variable_costate::Bool` keyword and filling `dpv` when true",
            context="PseudoHamiltonianVectorField IP NonAutonomous/NonFixed call",
        ),
    )
    return H.f(dx, dp, t, x, p, u, v; dpv=dpv, variable_costate=true)
end

# =============================================================================
# Uniform (t, x, p, u, v) call - used by PseudoHamiltonianVectorFieldSystem.rhs
# Every combination forwards to its natural call, ignoring unused args.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
# =============================================================================

# OutOfPlace uniform signatures
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.Fixed,Traits.OutOfPlace
})(
    t, x, p, u, v; variable_costate::Bool=false
)
    return H.f(x, p, u)
end
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.Fixed,Traits.OutOfPlace
})(
    t, x, p, u, v; variable_costate::Bool=false
)
    return H.f(t, x, p, u)
end
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.NonFixed,Traits.OutOfPlace
})(
    t, x, p, u, v; variable_costate::Bool=false
)
    return H(x, p, u, v; variable_costate=variable_costate)
end # delegate to natural signature

# InPlace uniform signatures
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.Fixed,Traits.InPlace
})(
    dx, dp, t, x, p, u, v; variable_costate::Bool=false, dpv=nothing
)
    return H.f(dx, dp, x, p, u)
end
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.NonAutonomous,Traits.Fixed,Traits.InPlace
})(
    dx, dp, t, x, p, u, v; variable_costate::Bool=false, dpv=nothing
)
    return H.f(dx, dp, t, x, p, u)
end
function (H::PseudoHamiltonianVectorField{
    <:Function,Traits.Autonomous,Traits.NonFixed,Traits.InPlace
})(
    dx, dp, t, x, p, u, v; variable_costate::Bool=false, dpv=nothing
)
    return H(dx, dp, x, p, u, v; dpv=dpv, variable_costate=variable_costate)
end # delegate to natural signature

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a `PseudoHamiltonianVectorField`.

Shows the type name, time dependence, variable dependence, mutability, and the
natural/uniform call signatures.

# Arguments
- `io::IO`: The IO stream to write to.
- `h̃vf::PseudoHamiltonianVectorField`: The pseudo-Hamiltonian vector field to display.

See also: [`CTBase.Data.PseudoHamiltonianVectorField`](@ref).
"""
function Base.show(
    io::IO, ::PseudoHamiltonianVectorField{F,TD,VD,MD}
) where {
    F<:Function,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
}
    header = "PseudoHamiltonianVectorField: $(_td_label(TD)), $(_vd_label(VD)), $(_md_label(MD))"
    natural = _natural_sig_phvf(TD, VD, MD)
    uniform = _uniform_sig_phvf(MD)
    println(io, header)
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: ", uniform)
end

"""
$(TYPEDSIGNATURES)

Display a `PseudoHamiltonianVectorField` in the REPL with text/plain MIME type.

Delegates to the compact `show` method.

# Arguments
- `io::IO`: The IO stream to write to.
- `::MIME"text/plain"`: The MIME type for REPL display.
- `h̃vf::PseudoHamiltonianVectorField`: The pseudo-Hamiltonian vector field to display.

See also: [`CTBase.Data.PseudoHamiltonianVectorField`](@ref).
"""
function Base.show(
    io::IO, ::MIME"text/plain", hvf::PseudoHamiltonianVectorField{F,TD,VD,MD}
) where {
    F<:Function,
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    MD<:Traits.AbstractMutabilityTrait,
}
    return show(io, hvf)
end
