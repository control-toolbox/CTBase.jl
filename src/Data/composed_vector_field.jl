# =============================================================================
# ComposedVectorField — vector field obtained by composing a controlled vector
# field with an open-loop or closed-loop control law
# =============================================================================

"""
$(TYPEDEF)

Vector field obtained by eliminating the control from a
[`CTBase.Data.ControlledVectorField`](@ref) with an **open-loop** or **closed-loop**
[`CTBase.Data.ControlLaw`](@ref):

```math
g(t, x, v) = fc(t, x, u(...), v),
```

where the control is `u(t, v)` for an open-loop law and `u(t, x, v)` for a closed-loop
law. It is the state-space analogue of [`CTBase.Data.ComposedHamiltonian`](@ref).

It is a **functor** (not a closure), out-of-place, and subtypes
[`CTBase.Data.AbstractVectorField`](@ref) with `OutOfPlace` mutability — so it *is* a
vector field usable anywhere one is expected.

# Type Parameters
- `TD <: TimeDependence`, `VD <: VariableDependence`: the **join** of the controlled
  vector field's and the control law's dependences.
- `CVF <: ControlledVectorField`: concrete controlled vector-field type.
- `L <: ControlLaw`: concrete control-law type (must carry `OpenLoopFeedback` or
  `ClosedLoopFeedback`).

# Fields
- `fc::CVF`: the controlled vector field `fc(t, x, u, v)`.
- `law::L`: the open-loop or closed-loop control law.

See also: [`CTBase.Data.ControlledVectorField`](@ref), [`CTBase.Data.ControlLaw`](@ref),
[`CTBase.Data.OpenLoop`](@ref), [`CTBase.Data.ClosedLoop`](@ref),
[`CTBase.Data.ComposedHamiltonian`](@ref).
"""
struct ComposedVectorField{
    TD<:Traits.TimeDependence,
    VD<:Traits.VariableDependence,
    CVF<:ControlledVectorField,
    L<:ControlLaw{<:Function,<:Union{Traits.OpenLoopFeedback,Traits.ClosedLoopFeedback}},
} <: AbstractVectorField{TD,VD,Traits.OutOfPlace}
    fc::CVF
    law::L
end

# =============================================================================
# Constructor — composed traits are the join of the two inputs
# =============================================================================

"""
$(TYPEDSIGNATURES)

Construct a [`CTBase.Data.ComposedVectorField`](@ref) from a controlled vector field and
an open-loop or closed-loop control law, computing the composed time/variable
dependences as the join of the two inputs.

See also: [`CTBase.Data.ComposedVectorField`](@ref).
"""
function ComposedVectorField(
    fc::ControlledVectorField,
    law::ControlLaw{<:Function,<:Union{Traits.OpenLoopFeedback,Traits.ClosedLoopFeedback}},
)
    TD = _join_td(Traits.time_dependence(fc), Traits.time_dependence(law))
    VD = _join_vd(Traits.variable_dependence(fc), Traits.variable_dependence(law))
    return ComposedVectorField{TD,VD,typeof(fc),typeof(law)}(fc, law)
end

# =============================================================================
# Getters
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return the underlying controlled vector field of a [`CTBase.Data.ComposedVectorField`](@ref).

See also: [`CTBase.Data.ComposedVectorField`](@ref), [`CTBase.Data.control_law`](@ref).
"""
controlled_vector_field(g::ComposedVectorField) = g.fc

"""
$(TYPEDSIGNATURES)

Return the control law of a [`CTBase.Data.ComposedVectorField`](@ref).

See also: [`CTBase.Data.ComposedVectorField`](@ref), [`CTBase.Data.controlled_vector_field`](@ref).
"""
control_law(g::ComposedVectorField) = g.law

# =============================================================================
# Core computation and call signatures
# =============================================================================

"""
Evaluate the control from a [`CTBase.Data.ControlLaw`](@ref) with the appropriate
call arity for its feedback trait: `u(t, v)` for open-loop, `u(t, x, v)` for
closed-loop. The state `x` is ignored by open-loop laws.

See also: [`CTBase.Data.ComposedVectorField`](@ref), [`CTBase.Data.ControlLaw`](@ref).
"""
_law_control(law::ControlLaw{<:Function,Traits.OpenLoopFeedback}, t, x, v) = law(t, v)
_law_control(law::ControlLaw{<:Function,Traits.ClosedLoopFeedback}, t, x, v) = law(t, x, v)

"""
$(TYPEDSIGNATURES)

Core computation `g(t, x, v) = fc(t, x, u(...), v)` using the uniform call signatures of
the controlled vector field and the control law (open-loop `u(t,v)` or closed-loop
`u(t,x,v)`).

See also: [`CTBase.Data.ComposedVectorField`](@ref).
"""
function _composed_vf(g::ComposedVectorField, t, x, v)
    u = _law_control(g.law, t, x, v)
    return g.fc(t, x, u, v)   # ControlledVectorField uniform call (t, x, u, v)
end

# Natural call signatures (OutOfPlace) — one per composed (TD, VD)
function (g::ComposedVectorField{Traits.Autonomous,Traits.Fixed})(x)
    _composed_vf(g, 0.0, x, nothing)
end
function (g::ComposedVectorField{Traits.NonAutonomous,Traits.Fixed})(t, x)
    _composed_vf(g, t, x, nothing)
end
function (g::ComposedVectorField{Traits.Autonomous,Traits.NonFixed})(x, v)
    _composed_vf(g, 0.0, x, v)
end
function (g::ComposedVectorField{Traits.NonAutonomous,Traits.NonFixed})(t, x, v)
    return _composed_vf(g, t, x, v)
end

# Uniform (t, x, v) call — used by VectorFieldSystem.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
(g::ComposedVectorField{Traits.Autonomous,Traits.Fixed})(t, x, v) = _composed_vf(g, t, x, v)
function (g::ComposedVectorField{Traits.NonAutonomous,Traits.Fixed})(t, x, v)
    _composed_vf(g, t, x, v)
end
function (g::ComposedVectorField{Traits.Autonomous,Traits.NonFixed})(t, x, v)
    _composed_vf(g, t, x, v)
end

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a [`CTBase.Data.ComposedVectorField`](@ref).

See also: [`CTBase.Data.ComposedVectorField`](@ref).
"""
function Base.show(io::IO, ::ComposedVectorField{TD,VD}) where {TD,VD}
    natural = _natural_sig_vf(TD, VD, Traits.OutOfPlace)
    uniform = _uniform_sig_vf(Traits.OutOfPlace)
    println(io, "ComposedVectorField: $(_td_label(TD)), $(_vd_label(VD)), out-of-place")
    println(io, "  natural call: ", natural)
    return print(io, "  uniform call: ", uniform)
end

function Base.show(io::IO, ::MIME"text/plain", g::ComposedVectorField)
    return show(io, g)
end
