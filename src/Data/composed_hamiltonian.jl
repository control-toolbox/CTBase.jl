# =============================================================================
# ComposedHamiltonian — Hamiltonian obtained by composing a pseudo-Hamiltonian
# with a dynamic closed-loop control law
# =============================================================================

"""
$(TYPEDEF)

Hamiltonian obtained by eliminating the control from a
[`CTBase.Data.PseudoHamiltonian`](@ref) with a dynamic closed-loop
[`CTBase.Data.ControlLaw`](@ref):

```math
H(t, x, p, v) = H̃(t, x, p, u(t, x, p, v), v).
```

It is a **functor** (a struct with call methods), not a closure, so it aligns with
the ecosystem philosophy and can be differentiated *through* the control law by
automatic differentiation (the total derivative, `:total` mode of the OCP flow).

Since it subtypes [`CTBase.Data.AbstractHamiltonian`](@ref), it *is* a Hamiltonian:
all trait accessors are inherited, and it can be stored anywhere an
`AbstractHamiltonian` is expected.

# Type Parameters
- `TD <: TimeDependence`: time dependence of the composed Hamiltonian — the **join**
  of the pseudo-Hamiltonian's and the control law's time dependences (`NonAutonomous`
  if either depends on time).
- `VD <: VariableDependence`: variable dependence — the **join** of the two variable
  dependences (`NonFixed` if either depends on the variable).
- `PH <: PseudoHamiltonian`: concrete pseudo-Hamiltonian type.
- `L <: ControlLaw`: concrete control-law type (must carry `DynClosedLoopFeedback`).

# Fields
- `h̃::PH`: the pseudo-Hamiltonian `H̃(t, x, p, u, v)`.
- `law::L`: the dynamic closed-loop control law `u(t, x, p, v)`.

# Construction
```julia
ComposedHamiltonian(h̃, law)   # law must carry DynClosedLoopFeedback
```

The composed time/variable dependences are the join of the two inputs, so a
time-varying feedback on an autonomous pseudo-Hamiltonian correctly yields a
`NonAutonomous` composed Hamiltonian.

See also: [`CTBase.Data.PseudoHamiltonian`](@ref), [`CTBase.Data.ControlLaw`](@ref),
[`CTBase.Data.DynClosedLoop`](@ref), [`CTBase.Data.AbstractHamiltonian`](@ref).
"""
struct ComposedHamiltonian{
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    PH<:PseudoHamiltonian,
    L<:ControlLaw{<:Function,Traits.DynClosedLoopFeedback},
} <: AbstractHamiltonian{TD,VD}
    h̃::PH
    law::L
end

# =============================================================================
# Trait joins — NonAutonomous / NonFixed win
# =============================================================================

_join_td(::Type{Traits.Autonomous}, ::Type{Traits.Autonomous}) = Traits.Autonomous
function _join_td(::Type{<:Traits.TimeDependence}, ::Type{<:Traits.TimeDependence})
    Traits.NonAutonomous
end

_join_vd(::Type{Traits.Fixed}, ::Type{Traits.Fixed}) = Traits.Fixed
function _join_vd(::Type{<:Traits.VariableDependence}, ::Type{<:Traits.VariableDependence})
    Traits.NonFixed
end

# =============================================================================
# Constructor — computes the composed traits from the join of the two inputs
# =============================================================================

"""
$(TYPEDSIGNATURES)

Construct a [`CTBase.Data.ComposedHamiltonian`](@ref) from a pseudo-Hamiltonian and a
dynamic closed-loop control law, computing the composed time/variable dependences as
the join of the two inputs.

See also: [`CTBase.Data.ComposedHamiltonian`](@ref).
"""
function ComposedHamiltonian(
    h̃::PseudoHamiltonian, law::ControlLaw{<:Function,Traits.DynClosedLoopFeedback}
)
    TD = _join_td(Traits.time_dependence(h̃), Traits.time_dependence(law))
    VD = _join_vd(Traits.variable_dependence(h̃), Traits.variable_dependence(law))
    return ComposedHamiltonian{TD,VD,typeof(h̃),typeof(law)}(h̃, law)
end

# =============================================================================
# Getters
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return the underlying pseudo-Hamiltonian `H̃` of a [`CTBase.Data.ComposedHamiltonian`](@ref).

See also: [`CTBase.Data.ComposedHamiltonian`](@ref), [`CTBase.Data.control_law`](@ref).
"""
pseudo_hamiltonian(h::ComposedHamiltonian) = h.h̃

"""
$(TYPEDSIGNATURES)

Return the control law `u(t, x, p, v)` of a [`CTBase.Data.ComposedHamiltonian`](@ref).

See also: [`CTBase.Data.ComposedHamiltonian`](@ref), [`CTBase.Data.pseudo_hamiltonian`](@ref).
"""
control_law(h::ComposedHamiltonian) = h.law

# =============================================================================
# Core computation and call signatures
# =============================================================================

"""
$(TYPEDSIGNATURES)

Core computation `H(t, x, p, v) = H̃(t, x, p, u(t, x, p, v), v)` using the uniform call
signatures of the control law and the pseudo-Hamiltonian. Unused arguments (`t`, `v`)
are ignored by the respective uniform calls.

See also: [`CTBase.Data.ComposedHamiltonian`](@ref).
"""
function _composed_H(h::ComposedHamiltonian, t, x, p, v)
    u = h.law(t, x, p, v)      # DynClosedLoop uniform call (t, x, p, v)
    return h.h̃(t, x, p, u, v)  # PseudoHamiltonian uniform call (t, x, p, u, v)
end

# Natural call signatures — one per composed (TD, VD) combination
function (h::ComposedHamiltonian{Traits.Autonomous,Traits.Fixed})(x, p)
    _composed_H(h, 0.0, x, p, nothing)
end
function (h::ComposedHamiltonian{Traits.NonAutonomous,Traits.Fixed})(t, x, p)
    _composed_H(h, t, x, p, nothing)
end
function (h::ComposedHamiltonian{Traits.Autonomous,Traits.NonFixed})(x, p, v)
    _composed_H(h, 0.0, x, p, v)
end
function (h::ComposedHamiltonian{Traits.NonAutonomous,Traits.NonFixed})(t, x, p, v)
    return _composed_H(h, t, x, p, v)
end

# Uniform (t, x, p, v) call — used by systems / integrators.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
function (h::ComposedHamiltonian{Traits.Autonomous,Traits.Fixed})(t, x, p, v)
    _composed_H(h, t, x, p, v)
end
function (h::ComposedHamiltonian{Traits.NonAutonomous,Traits.Fixed})(t, x, p, v)
    _composed_H(h, t, x, p, v)
end
function (h::ComposedHamiltonian{Traits.Autonomous,Traits.NonFixed})(t, x, p, v)
    _composed_H(h, t, x, p, v)
end

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a [`CTBase.Data.ComposedHamiltonian`](@ref) showing
its composed traits and call signatures.

See also: [`CTBase.Data.ComposedHamiltonian`](@ref).
"""
function Base.show(io::IO, ::ComposedHamiltonian{TD,VD}) where {TD,VD}
    header = "ComposedHamiltonian: $(_td_label(TD)), $(_vd_label(VD))"
    natural = _natural_sig_h(TD, VD)
    uniform = _uniform_sig_h()
    println(io, header)
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: ", uniform)
end

"""
$(TYPEDSIGNATURES)

Display a [`CTBase.Data.ComposedHamiltonian`](@ref) in the REPL with the same format as
the compact `show`.

See also: [`CTBase.Data.ComposedHamiltonian`](@ref).
"""
function Base.show(io::IO, ::MIME"text/plain", h::ComposedHamiltonian)
    return show(io, h)
end
