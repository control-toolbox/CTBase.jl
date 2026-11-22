# =============================================================================
# ComposedConstrainedHamiltonian — Hamiltonian obtained by composing a constrained
# pseudo-Hamiltonian with a dynamic closed-loop control law and a multiplier
# =============================================================================

"""
$(TYPEDEF)

Hamiltonian obtained by eliminating the control **and** the multiplier from a
[`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref), with a dynamic closed-loop
[`CTBase.Data.ControlLaw`](@extref) and a [`CTBase.Data.Multiplier`](@extref), both in
feedback form:

```math
h(t, x, p, v) = H(t, x, p, u(t, x, p, v), \\mu(t, x, p, v), v).
```

It is a **functor**, so automatic differentiation goes *through* the control law and the
multiplier: its gradient is the **total** derivative (the `:total` mode of a flow), which
differs from the partial derivatives of the maximum principle by the terms
`∂H/∂u · ∂u/∂x` and `∂H/∂μ · ∂μ/∂x`. On an optimal arc these terms vanish; for the partial
derivatives at any point, see [`CTBase.Data.freeze_multiplier`](@extref).

It subtypes [`CTBase.Data.AbstractHamiltonian`](@extref): all trait accessors are
inherited, and it can be used anywhere a Hamiltonian is expected.

# Type Parameters
- `TD <: TimeDependence`: the **join** of the time dependences of the three inputs
  (`NonAutonomous` if any of them depends on time).
- `VD <: VariableDependence`: the **join** of the three variable dependences (`NonFixed`
  if any of them depends on the variable).
- `PH <: ConstrainedPseudoHamiltonian`: concrete constrained pseudo-Hamiltonian type.
- `L <: ControlLaw`: concrete control-law type (must carry `DynClosedLoopFeedback`).
- `M <: Multiplier`: concrete multiplier type.

# Fields
- `h::PH`: the constrained pseudo-Hamiltonian `H(t, x, p, u, μ, v)`.
- `law::L`: the dynamic closed-loop control law `u(t, x, p, v)`.
- `μ::M`: the multiplier `μ(t, x, p, v)`.

# Construction

```julia
ComposedConstrainedHamiltonian(H, law, μ)   # law must carry DynClosedLoopFeedback
```

# Example

```julia-repl
julia> using CTBase: Data

julia> H = Data.ConstrainedPseudoHamiltonian((x, p, u, μ) -> p * u - x^2 + μ * (x - 0.1));

julia> h = Data.ComposedConstrainedHamiltonian(
           H, Data.DynClosedLoop((x, p) -> 0.0), Data.Multiplier((x, p) -> 2x)
       );

julia> h(1.0, 2.0) == H(1.0, 2.0, 0.0, 2.0)
true
```

See also: [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref),
[`CTBase.Data.ComposedHamiltonian`](@extref), [`CTBase.Data.DynClosedLoop`](@extref),
[`CTBase.Data.Multiplier`](@extref).
"""
struct ComposedConstrainedHamiltonian{
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    PH<:ConstrainedPseudoHamiltonian,
    L<:ControlLaw{<:Function,Traits.DynClosedLoopFeedback},
    M<:Multiplier,
} <: AbstractHamiltonian{TD,VD}
    h::PH
    law::L
    μ::M
end

# =============================================================================
# Constructor — computes the composed traits from the join of the three inputs
# =============================================================================

"""
$(TYPEDSIGNATURES)

Construct a [`CTBase.Data.ComposedConstrainedHamiltonian`](@extref) from a constrained
pseudo-Hamiltonian, a dynamic closed-loop control law and a multiplier, computing the
composed time/variable dependences as the join of the three inputs.

See also: [`CTBase.Data.ComposedConstrainedHamiltonian`](@extref).
"""
function ComposedConstrainedHamiltonian(
    h::ConstrainedPseudoHamiltonian,
    law::ControlLaw{<:Function,Traits.DynClosedLoopFeedback},
    μ::Multiplier,
)
    TD = _join_td(
        _join_td(Traits.time_dependence(h), Traits.time_dependence(law)),
        Traits.time_dependence(μ),
    )
    VD = _join_vd(
        _join_vd(Traits.variable_dependence(h), Traits.variable_dependence(law)),
        Traits.variable_dependence(μ),
    )
    return ComposedConstrainedHamiltonian{TD,VD,typeof(h),typeof(law),typeof(μ)}(h, law, μ)
end

# =============================================================================
# Getters
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return the constrained pseudo-Hamiltonian `H(t, x, p, u, μ, v)` of a
[`CTBase.Data.ComposedConstrainedHamiltonian`](@extref).

See also: [`CTBase.Data.control_law`](@extref), [`CTBase.Data.multiplier`](@extref).
"""
pseudo_hamiltonian(h::ComposedConstrainedHamiltonian) = h.h

"""
$(TYPEDSIGNATURES)

Return the control law `u(t, x, p, v)` of a
[`CTBase.Data.ComposedConstrainedHamiltonian`](@extref).

See also: [`CTBase.Data.pseudo_hamiltonian`](@extref), [`CTBase.Data.multiplier`](@extref).
"""
control_law(h::ComposedConstrainedHamiltonian) = h.law

"""
$(TYPEDSIGNATURES)

Return the multiplier `μ(t, x, p, v)` of a
[`CTBase.Data.ComposedConstrainedHamiltonian`](@extref).

See also: [`CTBase.Data.pseudo_hamiltonian`](@extref), [`CTBase.Data.control_law`](@extref).
"""
multiplier(h::ComposedConstrainedHamiltonian) = h.μ

# =============================================================================
# Core computation and call signatures
# =============================================================================

"""
$(TYPEDSIGNATURES)

Core computation `h(t, x, p, v) = H(t, x, p, u(t, x, p, v), μ(t, x, p, v), v)` using the
uniform call signatures of the control law, the multiplier and the constrained
pseudo-Hamiltonian, which ignore the arguments their traits do not use.

See also: [`CTBase.Data.ComposedConstrainedHamiltonian`](@extref).
"""
function _composed_constrained_H(h::ComposedConstrainedHamiltonian, t, x, p, v)
    u = h.law(t, x, p, v)          # DynClosedLoop uniform call (t, x, p, v)
    μ = h.μ(t, x, p, v)            # Multiplier uniform call (t, x, p, v)
    return h.h(t, x, p, u, μ, v)   # ConstrainedPseudoHamiltonian uniform call
end

# Natural call signatures — one per composed (TD, VD) combination
function (h::ComposedConstrainedHamiltonian{Traits.Autonomous,Traits.Fixed})(x, p)
    return _composed_constrained_H(h, 0.0, x, p, nothing)
end
function (h::ComposedConstrainedHamiltonian{Traits.NonAutonomous,Traits.Fixed})(t, x, p)
    return _composed_constrained_H(h, t, x, p, nothing)
end
function (h::ComposedConstrainedHamiltonian{Traits.Autonomous,Traits.NonFixed})(x, p, v)
    return _composed_constrained_H(h, 0.0, x, p, v)
end
function (h::ComposedConstrainedHamiltonian{Traits.NonAutonomous,Traits.NonFixed})(
    t, x, p, v
)
    return _composed_constrained_H(h, t, x, p, v)
end

# Uniform (t, x, p, v) call — used by systems / integrators.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
function (h::ComposedConstrainedHamiltonian{Traits.Autonomous,Traits.Fixed})(t, x, p, v)
    return _composed_constrained_H(h, t, x, p, v)
end
function (h::ComposedConstrainedHamiltonian{Traits.NonAutonomous,Traits.Fixed})(t, x, p, v)
    return _composed_constrained_H(h, t, x, p, v)
end
function (h::ComposedConstrainedHamiltonian{Traits.Autonomous,Traits.NonFixed})(t, x, p, v)
    return _composed_constrained_H(h, t, x, p, v)
end

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a
[`CTBase.Data.ComposedConstrainedHamiltonian`](@extref) showing its composed traits and
call signatures.

See also: [`CTBase.Data.ComposedConstrainedHamiltonian`](@extref).
"""
function Base.show(
    io::IO, ::ComposedConstrainedHamiltonian{TD,VD}
) where {TD<:Traits.TimeDependence,VD<:Traits.VariableDependence}
    println(io, "ComposedConstrainedHamiltonian: $(_td_label(TD)), $(_vd_label(VD))")
    println(io, "  natural call: ", _natural_sig_h(TD, VD))
    return print(io, "  uniform call: ", _uniform_sig_h())
end

"""
$(TYPEDSIGNATURES)

Display a [`CTBase.Data.ComposedConstrainedHamiltonian`](@extref) in the REPL with the same
format as the compact `show`.

See also: [`CTBase.Data.ComposedConstrainedHamiltonian`](@extref).
"""
function Base.show(io::IO, ::MIME"text/plain", h::ComposedConstrainedHamiltonian)
    return show(io, h)
end
