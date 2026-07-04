# =============================================================================
# Concrete PseudoHamiltonian type
# =============================================================================

"""
$(TYPEDEF)

Parametric container for a scalar pseudo-Hamiltonian function together with its
time-dependence and variable-dependence traits.

The function returns a scalar value `H̃(t, x, p, u[, v]) → ℝ` representing the
pseudo-Hamiltonian of the system, which extends the standard Hamiltonian with
an explicit control argument `u`.

# Type Parameters
- `F`: concrete type of the wrapped function.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Fields
- `f::F`: the pseudo-Hamiltonian function.

# Construction

Use the keyword constructor:

```julia
PseudoHamiltonian(f; is_autonomous = true, is_variable = false)        # default: h̃(x, p, u)
PseudoHamiltonian((t, x, p, u) -> ...; is_autonomous = false)          # h̃(t, x, p, u)
PseudoHamiltonian((x, p, u, v) -> ...; is_variable = true)             # h̃(x, p, u, v)
PseudoHamiltonian((t, x, p, u, v) -> ...; is_autonomous = false, is_variable = true)
```

# Call Signatures

Every `PseudoHamiltonian` is callable via its **natural** signature (matching
the traits), and via a **uniform** signature `(t, x, p, u, v)` that ignores
unused arguments.

For Autonomous/Fixed: natural `h̃(x, p, u)`, uniform `h̃(t, x, p, u, v)`.
For NonAutonomous/Fixed: natural `h̃(t, x, p, u)`, uniform `h̃(t, x, p, u, v)`.
For Autonomous/NonFixed: natural `h̃(x, p, u, v)`, uniform `h̃(t, x, p, u, v)`.
For NonAutonomous/NonFixed: natural `h̃(t, x, p, u, v)`, uniform `h̃(t, x, p, u, v)`.

See also: [`CTBase.Data.AbstractPseudoHamiltonian`](@ref), [`CTBase.Data.Hamiltonian`](@ref),
[`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
struct PseudoHamiltonian{F<:Function,TD,VD} <: AbstractPseudoHamiltonian{TD,VD}
    f::F
end

# =============================================================================
# Keyword constructor
# =============================================================================

"""
$(TYPEDSIGNATURES)

Construct a `PseudoHamiltonian` with trait flags.

# Arguments
- `f::Function`: The pseudo-Hamiltonian function returning a scalar value.
- `is_autonomous::Bool`: If true, system is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, system depends on variable parameters (default: `__is_variable()`).

# Example
```julia-repl
julia> using CTBase.Data

julia> h̃ = PseudoHamiltonian((x, p, u) -> sum(x .* p) + u^2)
PseudoHamiltonian: autonomous, fixed (no variable)
  natural call: h̃(x, p, u)
  uniform call: h̃(t, x, p, u, v)
```

See also: [`CTBase.Data.PseudoHamiltonian`](@ref), [`CTBase.Traits.Autonomous`](@ref),
[`CTBase.Traits.NonAutonomous`](@ref), [`CTBase.Traits.Fixed`](@ref), [`CTBase.Traits.NonFixed`](@ref).
"""
function PseudoHamiltonian(
    f; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
)
    TD = is_autonomous ? Traits.Autonomous : Traits.NonAutonomous
    VD = is_variable ? Traits.NonFixed : Traits.Fixed
    return PseudoHamiltonian{typeof(f),TD,VD}(f)
end

# =============================================================================
# Typed constructor
# =============================================================================

"""
$(TYPEDSIGNATURES)

Typed constructor for `PseudoHamiltonian` with explicit trait types.

# Arguments
- `f`: The pseudo-Hamiltonian function.
- `::Type{TD}`: The time-dependence trait type.
- `::Type{VD}`: The variable-dependence trait type.

# Returns
- `PseudoHamiltonian`: A pseudo-Hamiltonian with the specified traits.

See also: [`CTBase.Data.PseudoHamiltonian`](@ref).
"""
function PseudoHamiltonian(
    f, ::Type{TD}, ::Type{VD}
) where {TD<:Traits.TimeDependence,VD<:Traits.VariableDependence}
    return PseudoHamiltonian{typeof(f),TD,VD}(f)
end

# =============================================================================
# Natural call signatures — one per trait combination
# =============================================================================

(h̃::PseudoHamiltonian{<:Function,Traits.Autonomous,Traits.Fixed})(x, p, u) = h̃.f(x, p, u)
function (h̃::PseudoHamiltonian{<:Function,Traits.NonAutonomous,Traits.Fixed})(t, x, p, u)
    return h̃.f(t, x, p, u)
end
function (h̃::PseudoHamiltonian{<:Function,Traits.Autonomous,Traits.NonFixed})(x, p, u, v)
    return h̃.f(x, p, u, v)
end
function (h̃::PseudoHamiltonian{<:Function,Traits.NonAutonomous,Traits.NonFixed})(t, x, p, u, v)
    return h̃.f(t, x, p, u, v)
end

# =============================================================================
# Uniform (t, x, p, u, v) call — used by flow integrators
# Every combination forwards to its natural call, ignoring unused args.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
# =============================================================================

(h̃::PseudoHamiltonian{<:Function,Traits.Autonomous,Traits.Fixed})(t, x, p, u, v) = h̃.f(x, p, u)
function (h̃::PseudoHamiltonian{<:Function,Traits.NonAutonomous,Traits.Fixed})(t, x, p, u, v)
    return h̃.f(t, x, p, u)
end
function (h̃::PseudoHamiltonian{<:Function,Traits.Autonomous,Traits.NonFixed})(t, x, p, u, v)
    return h̃.f(x, p, u, v)
end
# NonAutonomous, NonFixed — already covered by natural 5-arg

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a `PseudoHamiltonian` showing its traits and call signatures.

# Arguments
- `io::IO`: The IO stream.
- `h̃::PseudoHamiltonian`: The pseudo-Hamiltonian object.

# Output
Displays three lines:
- Header with time and variable dependence traits
- Natural call signature
- Uniform call signature

See also: [`CTBase.Data.PseudoHamiltonian`](@ref).
"""
function Base.show(io::IO, ::PseudoHamiltonian{F,TD,VD}) where {F,TD,VD}
    header = "PseudoHamiltonian: $(_td_label(TD)), $(_vd_label(VD))"
    natural = _natural_sig_ph(TD, VD)
    uniform = _uniform_sig_ph()
    println(io, header)
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: ", uniform)
end

"""
$(TYPEDSIGNATURES)

Display a `PseudoHamiltonian` in the REPL with the same format as the compact `show`.

This method is called automatically when displaying a pseudo-Hamiltonian in the Julia REPL.

# Arguments
- `io::IO`: The IO stream.
- `mime::MIME"text/plain"`: The MIME type.
- `h̃::PseudoHamiltonian`: The pseudo-Hamiltonian object.

See also: [`CTBase.Data.PseudoHamiltonian`](@ref).
"""
function Base.show(io::IO, ::MIME"text/plain", h̃::PseudoHamiltonian{F,TD,VD}) where {F,TD,VD}
    return show(io, h̃)
end
