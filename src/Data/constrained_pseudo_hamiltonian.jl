# =============================================================================
# Concrete ConstrainedPseudoHamiltonian type, and freezing of its multiplier
# =============================================================================

"""
$(TYPEDEF)

Parametric container for a scalar constrained pseudo-Hamiltonian function together with
its time-dependence and variable-dependence traits:

```math
H(t, x, p, u, \\mu, v) = \\tilde H(t, x, p, u, v) + \\mu \\cdot g(t, x, u, v).
```

The multiplier `μ` is an explicit argument, like the control `u`: this is the
pseudo-Hamiltonian of the maximum principle for a problem with path constraints. How
the constraint term is written (sign of `p⁰`, normalisation of `g`) belongs to the
function `f`; this container only carries the traits and the call signatures.

# Type Parameters
- `F`: concrete type of the wrapped function.
- `TD <: TimeDependence`: `Autonomous` or `NonAutonomous`.
- `VD <: VariableDependence`: `Fixed` or `NonFixed`.

# Fields
- `f::F`: the constrained pseudo-Hamiltonian function, with its natural arity.

# Construction

```julia
ConstrainedPseudoHamiltonian(f; is_autonomous = true, is_variable = false)    # H(x, p, u, μ)
ConstrainedPseudoHamiltonian((t, x, p, u, μ) -> ...; is_autonomous = false)  # H(t, x, p, u, μ)
ConstrainedPseudoHamiltonian((x, p, u, μ, v) -> ...; is_variable = true)     # H(x, p, u, μ, v)
ConstrainedPseudoHamiltonian(f, TD, VD)                                      # typed traits
```

# Call Signatures

Every `ConstrainedPseudoHamiltonian` is callable via its **natural** signature (matching
the traits), and via a **uniform** signature `(t, x, p, u, μ, v)` that ignores unused
arguments.

| `TD` / `VD` | Natural | Uniform |
| :--- | :--- | :--- |
| `Autonomous` / `Fixed` | `H(x, p, u, μ)` | `H(t, x, p, u, μ, v)` |
| `NonAutonomous` / `Fixed` | `H(t, x, p, u, μ)` | `H(t, x, p, u, μ, v)` |
| `Autonomous` / `NonFixed` | `H(x, p, u, μ, v)` | `H(t, x, p, u, μ, v)` |
| `NonAutonomous` / `NonFixed` | `H(t, x, p, u, μ, v)` | `H(t, x, p, u, μ, v)` |

# Example

```julia-repl
julia> using CTBase: Data

julia> H = Data.ConstrainedPseudoHamiltonian((x, p, u, μ) -> p * u - x^2 + μ * (x - 0.1))
ConstrainedPseudoHamiltonian: autonomous, fixed (no variable)
  natural call: H(x, p, u, μ)
  uniform call: H(t, x, p, u, μ, v)

julia> H(1.0, 2.0, 0.5, 3.0)
2.7
```

See also: [`CTBase.Data.AbstractConstrainedPseudoHamiltonian`](@extref),
[`CTBase.Data.freeze_multiplier`](@extref),
[`CTBase.Data.ComposedConstrainedHamiltonian`](@extref),
[`CTBase.Data.PseudoHamiltonian`](@extref).
"""
struct ConstrainedPseudoHamiltonian{
    F<:Function,TD<:Traits.TimeDependence,VD<:Traits.VariableDependence
} <: AbstractConstrainedPseudoHamiltonian{TD,VD}
    f::F
end

# =============================================================================
# Constructors
# =============================================================================

"""
$(TYPEDSIGNATURES)

Construct a [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref) with trait flags.

# Arguments
- `f::Function`: the constrained pseudo-Hamiltonian, with the natural arity given by the
  flags.
- `is_autonomous::Bool`: if true, `f` does not take the time (default: `__is_autonomous()`).
- `is_variable::Bool`: if true, `f` takes the variable `v` (default: `__is_variable()`).

See also: [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref).
"""
function ConstrainedPseudoHamiltonian(
    f; is_autonomous::Bool=__is_autonomous(), is_variable::Bool=__is_variable()
)
    TD = is_autonomous ? Traits.Autonomous : Traits.NonAutonomous
    VD = is_variable ? Traits.NonFixed : Traits.Fixed
    return ConstrainedPseudoHamiltonian{typeof(f),TD,VD}(f)
end

"""
$(TYPEDSIGNATURES)

Typed constructor for [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref) with explicit
trait types.

See also: [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref).
"""
function ConstrainedPseudoHamiltonian(
    f, ::Type{TD}, ::Type{VD}
) where {TD<:Traits.TimeDependence,VD<:Traits.VariableDependence}
    return ConstrainedPseudoHamiltonian{typeof(f),TD,VD}(f)
end

# =============================================================================
# Natural call signatures — one per trait combination
# =============================================================================

function (h::ConstrainedPseudoHamiltonian{<:Function,Traits.Autonomous,Traits.Fixed})(
    x, p, u, μ
)
    return h.f(x, p, u, μ)
end
function (h::ConstrainedPseudoHamiltonian{<:Function,Traits.NonAutonomous,Traits.Fixed})(
    t, x, p, u, μ
)
    return h.f(t, x, p, u, μ)
end
function (h::ConstrainedPseudoHamiltonian{<:Function,Traits.Autonomous,Traits.NonFixed})(
    x, p, u, μ, v
)
    return h.f(x, p, u, μ, v)
end
function (h::ConstrainedPseudoHamiltonian{<:Function,Traits.NonAutonomous,Traits.NonFixed})(
    t, x, p, u, μ, v
)
    return h.f(t, x, p, u, μ, v)
end

# =============================================================================
# Uniform (t, x, p, u, μ, v) call — used by flows.
# (NonAutonomous, NonFixed) is already covered by the natural signature above.
# =============================================================================

function (h::ConstrainedPseudoHamiltonian{<:Function,Traits.Autonomous,Traits.Fixed})(
    t, x, p, u, μ, v
)
    return h.f(x, p, u, μ)
end
function (h::ConstrainedPseudoHamiltonian{<:Function,Traits.NonAutonomous,Traits.Fixed})(
    t, x, p, u, μ, v
)
    return h.f(t, x, p, u, μ)
end
function (h::ConstrainedPseudoHamiltonian{<:Function,Traits.Autonomous,Traits.NonFixed})(
    t, x, p, u, μ, v
)
    return h.f(x, p, u, μ, v)
end

# =============================================================================
# Freezing the multiplier — the pseudo-Hamiltonian at a fixed value of μ
# =============================================================================

"""
$(TYPEDEF)

Function `(…, u, …) ↦ H(…, u, μ, …)` of a constrained pseudo-Hamiltonian `H` at a fixed
value `μ` of the multiplier, with the natural arity of `H` minus the multiplier. Wrapped
in a [`CTBase.Data.PseudoHamiltonian`](@extref) by [`CTBase.Data.freeze_multiplier`](@extref).

# Fields
- `h::H`: the constrained pseudo-Hamiltonian.
- `μ::M`: the value of the multiplier (a number or a vector).

See also: [`CTBase.Data.freeze_multiplier`](@extref).
"""
struct _FrozenMultiplier{H<:ConstrainedPseudoHamiltonian,M} <: Function
    h::H
    μ::M
end

function (f::_FrozenMultiplier{
    <:ConstrainedPseudoHamiltonian{<:Function,Traits.Autonomous,Traits.Fixed}
})(
    x, p, u
)
    return f.h(x, p, u, f.μ)
end
function (f::_FrozenMultiplier{
    <:ConstrainedPseudoHamiltonian{<:Function,Traits.NonAutonomous,Traits.Fixed}
})(
    t, x, p, u
)
    return f.h(t, x, p, u, f.μ)
end
function (f::_FrozenMultiplier{
    <:ConstrainedPseudoHamiltonian{<:Function,Traits.Autonomous,Traits.NonFixed}
})(
    x, p, u, v
)
    return f.h(x, p, u, f.μ, v)
end
function (f::_FrozenMultiplier{
    <:ConstrainedPseudoHamiltonian{<:Function,Traits.NonAutonomous,Traits.NonFixed}
})(
    t, x, p, u, v
)
    return f.h(t, x, p, u, f.μ, v)
end

"""
$(TYPEDSIGNATURES)

Return the pseudo-Hamiltonian `H̃(t, x, p, u, v) = H(t, x, p, u, μ, v)` of the constrained
pseudo-Hamiltonian `H` at the fixed value `μ` of the multiplier, as a
[`CTBase.Data.PseudoHamiltonian`](@extref) with the traits of `H`.

The multiplier is a constant of the result: differentiating it with respect to `x` and
`p` gives the **partial** derivatives of the maximum principle, `∂H/∂x` and `∂H/∂p` at
fixed `u` and `μ` (the `:partial` mode of a flow). The gradient primitives of
[`CTBase.Differentiation`](@extref), such as
[`CTBase.Differentiation.pseudo_hamiltonian_gradient`](@extref), apply to it unchanged.

# Arguments
- `h::ConstrainedPseudoHamiltonian`: the constrained pseudo-Hamiltonian.
- `μ`: the value of the multiplier, a number or a vector.

# Returns
- `PseudoHamiltonian`: the pseudo-Hamiltonian at fixed `μ`.

# Example

```julia-repl
julia> using CTBase: Data

julia> H = Data.ConstrainedPseudoHamiltonian((x, p, u, μ) -> p * u - x^2 + μ * (x - 0.1));

julia> H̃ = Data.freeze_multiplier(H, 3.0);

julia> H̃(1.0, 2.0, 0.5) == H(1.0, 2.0, 0.5, 3.0)
true
```

See also: [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref),
[`CTBase.Data.ComposedConstrainedHamiltonian`](@extref).
"""
function freeze_multiplier(
    h::ConstrainedPseudoHamiltonian{<:Function,TD,VD}, μ
) where {TD<:Traits.TimeDependence,VD<:Traits.VariableDependence}
    return PseudoHamiltonian(_FrozenMultiplier(h, μ), TD, VD)
end

# =============================================================================
# Base.show
# =============================================================================

"""
$(TYPEDSIGNATURES)

Display a compact representation of a [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref)
showing its traits and call signatures.

See also: [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref).
"""
function Base.show(
    io::IO, ::ConstrainedPseudoHamiltonian{F,TD,VD}
) where {F<:Function,TD<:Traits.TimeDependence,VD<:Traits.VariableDependence}
    header = "ConstrainedPseudoHamiltonian: $(_td_label(TD)), $(_vd_label(VD))"
    println(io, header)
    println(io, "  natural call: ", _natural_sig_cph(TD, VD))
    return print(io, "  uniform call: ", _uniform_sig_cph())
end

"""
$(TYPEDSIGNATURES)

Display a [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref) in the REPL with the same
format as the compact `show`.

See also: [`CTBase.Data.ConstrainedPseudoHamiltonian`](@extref).
"""
function Base.show(io::IO, ::MIME"text/plain", h::ConstrainedPseudoHamiltonian)
    return show(io, h)
end
