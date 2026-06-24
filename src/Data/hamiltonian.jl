# =============================================================================
# Concrete Hamiltonian type
# =============================================================================

"""
$(TYPEDEF)

Parametric container for a scalar Hamiltonian function together with its
time-dependence and variable-dependence traits.

The function returns a scalar value `H(t, x, p[, v]) → ℝ` representing the
Hamiltonian of the system.

# Type Parameters
- `F`: concrete type of the wrapped function.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Fields
- `f::F`: the Hamiltonian function.

# Construction

Use the keyword constructor:

```julia
Hamiltonian(f; is_autonomous = true, is_variable = false)        # default: h(x, p)
Hamiltonian((t, x, p) -> ...; is_autonomous = false)             # h(t, x, p)
Hamiltonian((x, p, v) -> ...; is_variable = true)                # h(x, p, v)
Hamiltonian((t, x, p, v) -> ...; is_autonomous = false, is_variable = true)
```

# Call Signatures

Every `Hamiltonian` is callable via its **natural** signature (matching the
traits), and via a **uniform** signature `(t, x, p, v)` that ignores the
unused arguments.

For Autonomous/Fixed: natural `h(x, p)`, uniform `h(t, x, p, v)`.
For NonAutonomous/Fixed: natural `h(t, x, p)`, uniform `h(t, x, p, v)`.
For Autonomous/NonFixed: natural `h(x, p, v)`, uniform `h(t, x, p, v)`.
For NonAutonomous/NonFixed: natural `h(t, x, p, v)`, uniform `h(t, x, p, v)`.

# Example
```julia-repl
julia> using CTBase.Data

julia> h = Hamiltonian((x, p) -> dot(x, p))  # Uses defaults: is_autonomous=true, is_variable=false
Hamiltonian: autonomous, fixed (no variable)
  natural call: h(x, p)
  uniform call: h(t, x, p, v)

julia> h = Hamiltonian((t, x, p) -> t * dot(x, p); is_autonomous=false)
Hamiltonian: non-autonomous, fixed (no variable)
  natural call: h(t, x, p)
  uniform call: h(t, x, p, v)
```

See also: [`CTBase.Data.AbstractHamiltonian`](@ref), [`CTBase.Traits.TimeDependence`](@ref), [`CTBase.Traits.VariableDependence`](@ref).
"""
struct Hamiltonian{F<:Function, TD, VD} <: AbstractHamiltonian{TD, VD}
    f::F
end

# =============================================================================
# Constructor
# =============================================================================

"""
$(TYPEDSIGNATURES)

Construct a `Hamiltonian` with trait flags.

# Arguments
- `f::Function`: The Hamiltonian function returning a scalar value.
- `is_autonomous::Bool`: If true, system is autonomous (default: `__is_autonomous()`).
- `is_variable::Bool`: If true, system depends on variable parameters (default: `__is_variable()`).

# Returns
- `Hamiltonian`: A Hamiltonian with appropriate traits.

# Example
```julia-repl
julia> using CTBase.Data

julia> h = Hamiltonian((x, p) -> dot(x, p))  # Uses defaults: is_autonomous=true, is_variable=false
Hamiltonian: autonomous, fixed (no variable)
  natural call: h(x, p)
  uniform call: h(t, x, p, v)

julia> h = Hamiltonian((t, x, p) -> t * dot(x, p); is_autonomous=false)
Hamiltonian: non-autonomous, fixed (no variable)
  natural call: h(t, x, p)
  uniform call: h(t, x, p, v)

julia> h = Hamiltonian((x, p, v) -> v * dot(x, p); is_variable=true)
Hamiltonian: autonomous, non-fixed (variable)
  natural call: h(x, p, v)
  uniform call: h(t, x, p, v)
```

# Notes
- The default values for `is_autonomous` and `is_variable` come from `__is_autonomous()` and `__is_variable()`.
- The function signature should match the specified traits (e.g., if `is_autonomous=true` and `is_variable=false`, the function should accept `(x, p)`).

See also: [`CTBase.Data.Hamiltonian`](@ref), [`CTBase.Traits.Autonomous`](@ref), [`CTBase.Traits.NonAutonomous`](@ref), [`CTBase.Traits.Fixed`](@ref), [`CTBase.Traits.NonFixed`](@ref).
"""
function Hamiltonian(f;
    is_autonomous::Bool = __is_autonomous(),
    is_variable::Bool   = __is_variable()
)
    TD = is_autonomous ? Traits.Autonomous : Traits.NonAutonomous
    VD = is_variable   ? Traits.NonFixed   : Traits.Fixed
    return Hamiltonian{typeof(f), TD, VD}(f)
end

# =============================================================================
# Typed constructor — calls struct inner constructor directly
# =============================================================================

function Hamiltonian(
    f,
    ::Type{TD}, ::Type{VD},
) where {
    TD <: Traits.TimeDependence,
    VD <: Traits.VariableDependence,
}
    return Hamiltonian{typeof(f), TD, VD}(f)
end

# =============================================================================
# Natural call signatures - one per trait combination
# =============================================================================

(H::Hamiltonian{<:Function, Traits.Autonomous, Traits.Fixed})(x, p) = H.f(x, p)
(H::Hamiltonian{<:Function, Traits.NonAutonomous, Traits.Fixed})(t, x, p) = H.f(t, x, p)
(H::Hamiltonian{<:Function, Traits.Autonomous, Traits.NonFixed})(x, p, v) = H.f(x, p, v)
(H::Hamiltonian{<:Function, Traits.NonAutonomous, Traits.NonFixed})(t, x, p, v) = H.f(t, x, p, v)

# =============================================================================
# Uniform (t, x, p, v) call - used by future HamiltonianSystem.rhs
# Every combination forwards to its natural call, ignoring unused args.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
# =============================================================================

(H::Hamiltonian{<:Function, Traits.Autonomous, Traits.Fixed})(_, x, p, _) = H.f(x, p)
(H::Hamiltonian{<:Function, Traits.NonAutonomous, Traits.Fixed})(t, x, p, _) = H.f(t, x, p)
(H::Hamiltonian{<:Function, Traits.Autonomous, Traits.NonFixed})(_, x, p, v) = H.f(x, p, v)

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a Hamiltonian showing its traits and call signatures.

# Arguments
- `io::IO`: The IO stream.
- `h::Hamiltonian`: The Hamiltonian object.

# Output
Displays three lines:
- Header with time and variable dependence traits
- Natural call signature
- Uniform call signature

# Example
```julia-repl
julia> h = Hamiltonian((x, p) -> dot(x, p))
Hamiltonian: autonomous, fixed (no variable)
  natural call: h(x, p)
  uniform call: h(t, x, p, v)
```
"""
function Base.show(io::IO, ::Hamiltonian{F, TD, VD}) where {F, TD, VD}
    header = "Hamiltonian: $(_td_label(TD)), $(_vd_label(VD))"
    natural = _natural_sig_h(TD, VD)
    uniform = _uniform_sig_h()
    println(io, header)
    println(io, "  natural call: ", natural)
    print(io, "  uniform call: ", uniform)
end

"""
$(TYPEDSIGNATURES)

Display a Hamiltonian in the REPL with the same format as the compact `show`.

This method is called automatically when displaying a Hamiltonian in the Julia REPL.

# Arguments
- `io::IO`: The IO stream.
- `mime::MIME"text/plain"`: The MIME type.
- `h::Hamiltonian`: The Hamiltonian object.

See also: [`CTBase.Data.Hamiltonian`](@ref).
"""
function Base.show(io::IO, ::MIME"text/plain", h::Hamiltonian{F, TD, VD}) where {F, TD, VD}
    show(io, h)
end
