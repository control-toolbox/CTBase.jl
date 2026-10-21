"""
    CTBaseDifferentiationInterface

Package extension providing DifferentiationInterface.jl backend implementations
for automatic differentiation in `CTBase.Differentiation`.

Activated automatically when `DifferentiationInterface` is loaded together with `CTBase`.

This extension provides:
- `Differentiation.hamiltonian_gradient` — Hamiltonian gradient (∂H/∂x, ∂H/∂p) via DI
- `Differentiation.variable_gradient` — variable gradient ∂H/∂v via DI
- `Differentiation.gradient` / `Differentiation.derivative` — general AD primitives
- `Differentiation.differentiate` / `Differentiation.pushforward` — partial derivative / JVP primitives
"""
module CTBaseDifferentiationInterface

using DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using ADTypes: ADTypes
using CTBase: Data
using CTBase: Differentiation
using CTBase: Exceptions
using DifferentiationInterface: DifferentiationInterface as DI

# ==============================================================================
# Availability of the AD backend package
# ==============================================================================

"""
$(TYPEDSIGNATURES)

Return the first leaf backend of `ad` whose package is not loaded, or `nothing` if all are.

`DI.check_available` is `false` until the extension of DifferentiationInterface.jl for the
backend package is loaded (e.g. `AutoMooncake()` without `using Mooncake`); the call
`DI.gradient(f, ad, x)` then fails with a raw `MethodError`. A `SecondOrder` backend is
checked on its outer then inner backends, a sparse backend on its dense one.

See also: [`CTBase.Differentiation.check_backend`](@extref).
"""
function _unavailable(ad::DI.SecondOrder)
    return something(_unavailable(DI.outer(ad)), _unavailable(DI.inner(ad)), Some(nothing))
end
function _unavailable(ad::ADTypes.AbstractADType)
    return DI.check_available(ad) ? nothing : ADTypes.dense_ad(ad)
end

"""
$(TYPEDSIGNATURES)

Name of the package providing the ADTypes backend `ad`: the name of its type without the
`Auto` prefix (`AutoMooncake` → `:Mooncake`, `AutoPolyesterForwardDiff` →
`:PolyesterForwardDiff`).
"""
function _backend_package(ad::ADTypes.AbstractADType)
    name = String(nameof(typeof(ad)))
    return Symbol(startswith(name, "Auto") ? name[5:end] : name)
end

"""
$(TYPEDSIGNATURES)

Throw an [`CTBase.Exceptions.ExtensionError`](@extref) if the package of the AD backend of
`backend` is not loaded (see [`CTBase.Differentiation.check_backend`](@extref)).
"""
function Differentiation.check_backend(backend::Differentiation.DifferentiationInterface)
    missing_ad = _unavailable(Differentiation.ad_backend(backend))
    missing_ad === nothing && return nothing
    return throw(
        Exceptions.ExtensionError(
            _backend_package(missing_ad);
            message="to use the $(nameof(typeof(missing_ad))) AD backend",
            feature="automatic differentiation with $(missing_ad)",
            context="CTBase.Differentiation",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

The ADTypes backend of `backend`, after checking that its package is loaded. The check is a
compile-time constant for a concrete backend type.
"""
function _checked_backend(backend::Differentiation.DifferentiationInterface)
    Differentiation.check_backend(backend)
    return Differentiation.ad_backend(backend)
end

"""
$(TYPEDSIGNATURES)

The AD inputs `args` in the form the backend `ad` differentiates correctly, through the
backend's tag (see [`CTBase.Differentiation._materialize`](@extref)). Applied before the
closures are built, so that they capture the adjusted inputs too.
"""
function _ad_inputs(ad::ADTypes.AbstractADType, args::Vararg{Any,N}) where {N}
    tag = Differentiation._ad_tag(ad)
    return map(a -> Differentiation._materialize(tag, a), args)
end

# ==============================================================================
# Differentiation.hamiltonian_gradient / variable_gradient
# ==============================================================================

"""
$(TYPEDSIGNATURES)

Return the scalar DI differentiation primitive for a `Number` active argument.

Dispatches to `DI.derivative`, which computes `df/dx` for scalar `x`.

See also: `_derivator`
"""
function _derivator(::Type{<:Number})
    return DI.derivative
end

"""
$(TYPEDSIGNATURES)

Return the array DI differentiation primitive for an `AbstractArray` active argument.

Dispatches to `DI.gradient`, which computes `∇f` for array `x`.

See also: `_derivator`
"""
function _derivator(::Type{<:AbstractArray})
    return DI.gradient
end

"""
$(TYPEDSIGNATURES)

Compute Hamiltonian gradients (∂H/∂x, ∂H/∂p) via DifferentiationInterface.jl.

Anonymous closures are used deliberately so that ForwardDiff `tagcount` values
are assigned at runtime in the correct left-to-right order inside `ForwardDiff.≺`,
avoiding silent zero-gradient bugs in nested-AD contexts (e.g. inside NonlinearSolve).

# Returns
- Tuple `(grad_x, grad_p)` where `grad_x` = ∂H/∂x, `grad_p` = ∂H/∂p.
"""
function Differentiation.hamiltonian_gradient(
    backend::Differentiation.DifferentiationInterface,
    h::Data.AbstractHamiltonian,
    t,
    x,
    p,
    v,
)
    di_backend = _checked_backend(backend)
    xm, pm, vm = _ad_inputs(di_backend, x, p, v)
    h_x(x_) = h(t, x_, pm, vm)
    h_p(p_) = h(t, xm, p_, vm)
    grad_x = _derivator(typeof(xm))(h_x, di_backend, xm)
    grad_p = _derivator(typeof(pm))(h_p, di_backend, pm)
    return (grad_x, grad_p)
end

"""
$(TYPEDSIGNATURES)

Compute variable gradient ∂H/∂v via DifferentiationInterface.jl.

See the note in [`CTBase.Differentiation.hamiltonian_gradient`](@extref) on why anonymous closures are used.

# Returns
- `grad_v` = ∂H/∂v.
"""
function Differentiation.variable_gradient(
    backend::Differentiation.DifferentiationInterface,
    h::Data.AbstractHamiltonian,
    t,
    x,
    p,
    v,
)
    di_backend = _checked_backend(backend)
    xm, pm, vm = _ad_inputs(di_backend, x, p, v)
    h_v(v_) = h(t, xm, pm, v_)
    return _derivator(typeof(vm))(h_v, di_backend, vm)
end

"""
$(TYPEDSIGNATURES)

Compute pseudo-Hamiltonian gradients (∂H̃/∂x, ∂H̃/∂p) via DifferentiationInterface.jl.

Along a PMP solution, the stationarity condition ∂H̃/∂u = 0 holds, so the
Hamiltonian flow only requires ∂H̃/∂x and ∂H̃/∂p. Use
[`CTBase.Differentiation.pseudo_hamiltonian_control_gradient`](@extref) for ∂H̃/∂u.

Anonymous closures are used deliberately so that ForwardDiff `tagcount` values
are assigned at runtime in the correct left-to-right order inside `ForwardDiff.≺`,
avoiding silent zero-gradient bugs in nested-AD contexts (e.g. inside NonlinearSolve).

# Arguments
- `backend::Differentiation.DifferentiationInterface`: The DI backend strategy.
- `h̃::Data.AbstractPseudoHamiltonian`: The pseudo-Hamiltonian.
- `t`: Time (scalar).
- `x`: State vector.
- `p`: Costate vector.
- `u`: Control (scalar or vector).
- `v`: Variable (scalar or `nothing` for Fixed problems).

# Returns
- Tuple `(grad_x, grad_p)` where `grad_x` = ∂H̃/∂x, `grad_p` = ∂H̃/∂p.

See also: [`CTBase.Differentiation.pseudo_hamiltonian_control_gradient`](@extref),
[`CTBase.Differentiation.hamiltonian_gradient`](@extref).
"""
function Differentiation.pseudo_hamiltonian_gradient(
    backend::Differentiation.DifferentiationInterface,
    h̃::Data.AbstractPseudoHamiltonian,
    t,
    x,
    p,
    u,
    v,
)
    di_backend = _checked_backend(backend)
    xm, pm, um, vm = _ad_inputs(di_backend, x, p, u, v)
    h̃_x(x_) = h̃(t, x_, pm, um, vm)
    h̃_p(p_) = h̃(t, xm, p_, um, vm)
    grad_x = _derivator(typeof(xm))(h̃_x, di_backend, xm)
    grad_p = _derivator(typeof(pm))(h̃_p, di_backend, pm)
    return (grad_x, grad_p)
end

"""
$(TYPEDSIGNATURES)

Compute the pseudo-Hamiltonian control gradient ∂H̃/∂u via DifferentiationInterface.jl.

This is typically used to check the PMP stationarity condition ∂H̃/∂u = 0,
not for the Hamiltonian flow itself.

# Arguments
- `backend::Differentiation.DifferentiationInterface`: The DI backend strategy.
- `h̃::Data.AbstractPseudoHamiltonian`: The pseudo-Hamiltonian.
- `t`: Time (scalar).
- `x`: State vector.
- `p`: Costate vector.
- `u`: Control (scalar or vector).
- `v`: Variable (scalar or `nothing` for Fixed problems).

# Returns
- `grad_u`: ∂H̃/∂u.

See also: [`CTBase.Differentiation.pseudo_hamiltonian_gradient`](@extref).
"""
function Differentiation.pseudo_hamiltonian_control_gradient(
    backend::Differentiation.DifferentiationInterface,
    h̃::Data.AbstractPseudoHamiltonian,
    t,
    x,
    p,
    u,
    v,
)
    di_backend = _checked_backend(backend)
    xm, pm, um, vm = _ad_inputs(di_backend, x, p, u, v)
    h̃_u(u_) = h̃(t, xm, pm, u_, vm)
    grad_u = _derivator(typeof(um))(h̃_u, di_backend, um)
    return grad_u
end

"""
$(TYPEDSIGNATURES)

Compute the pseudo-Hamiltonian variable gradient ∂H̃/∂v via DifferentiationInterface.jl,
with the control `u` held constant.

See the note in [`CTBase.Differentiation.hamiltonian_gradient`](@extref) on why anonymous
closures are used, and [`CTBase.Differentiation.pseudo_variable_gradient`](@extref) on the
partial-vs-total distinction.

# Returns
- `grad_v` = ∂H̃/∂v (with `u` fixed).
"""
function Differentiation.pseudo_variable_gradient(
    backend::Differentiation.DifferentiationInterface,
    h̃::Data.AbstractPseudoHamiltonian,
    t,
    x,
    p,
    u,
    v,
)
    di_backend = _checked_backend(backend)
    xm, pm, um, vm = _ad_inputs(di_backend, x, p, u, v)
    h̃_v(v_) = h̃(t, xm, pm, um, v_)
    return _derivator(typeof(vm))(h̃_v, di_backend, vm)
end

# =============================================================================
# Differentiation.gradient — extension contract methods
# =============================================================================

"""
$(TYPEDSIGNATURES)

Compute the gradient of a scalar function using DifferentiationInterface.jl.

# Arguments
- `backend::Differentiation.DifferentiationInterface`: The AD backend.
- `f::Function`: The scalar function to differentiate.
- `x::AbstractArray`: The input vector.

# Returns
- `∇f`: The gradient of `f` at `x`.

# See also
- [`CTBase.Differentiation.derivative`](@extref)
"""
function Differentiation.gradient(
    backend::Differentiation.DifferentiationInterface, f::Function, x::AbstractArray
)
    ad = _checked_backend(backend)
    (xm,) = _ad_inputs(ad, x)
    return DI.gradient(f, ad, xm)
end

"""
$(TYPEDSIGNATURES)

Compute the gradient of a scalar function using DifferentiationInterface.jl (scalar case).

# Arguments
- `backend::Differentiation.DifferentiationInterface`: The AD backend.
- `f::Function`: The scalar function to differentiate.
- `x::Real`: The input scalar.

# Returns
- `df/dx`: The derivative of `f` at `x`.

# See also
- [`CTBase.Differentiation.derivative`](@extref)
"""
function Differentiation.gradient(
    backend::Differentiation.DifferentiationInterface, f::Function, x::Real
)
    ad = _checked_backend(backend)
    return DI.derivative(f, ad, x)
end

"""
$(TYPEDSIGNATURES)

Compute the derivative of a scalar function using DifferentiationInterface.jl.

# Arguments
- `backend::Differentiation.DifferentiationInterface`: The AD backend.
- `g::Function`: The scalar function to differentiate.
- `t::Real`: The input scalar.

# Returns
- `dg/dt`: The derivative of `g` at `t`.

# See also
- [`CTBase.Differentiation.gradient`](@extref)
"""
function Differentiation.derivative(
    backend::Differentiation.DifferentiationInterface, g::Function, t::Real
)
    ad = _checked_backend(backend)
    return DI.derivative(g, ad, t)
end

# =============================================================================
# Differentiation.differentiate / pushforward — new primitives
# =============================================================================

"""
$(TYPEDSIGNATURES)

Compute the partial derivative or gradient of `f` with respect to the argument at
slot `Slot`, using DifferentiationInterface.jl.

An anonymous closure captures the constant arguments and places `active_` at `Slot`
via `ntuple` — same rationale as [`CTBase.Differentiation.hamiltonian_gradient`](@extref) (ForwardDiff tag ordering).
`_derivator` dispatches to `DI.gradient` for array `active` and `DI.derivative` for scalar.

See also: [`CTBase.Differentiation.pushforward`](@extref).
"""
function Differentiation.differentiate(
    backend::Differentiation.DifferentiationInterface,
    f,
    ::Val{Slot},
    active,
    consts::Vararg{Any,N},
) where {Slot,N}
    di = _checked_backend(backend)
    inputs = _ad_inputs(di, active, consts...)
    am, cm = first(inputs), Base.tail(inputs)
    f_active(active_) =
        f(ntuple(i -> i == Slot ? active_ : cm[i < Slot ? i : i - 1], Val(N + 1))...)
    return _derivator(typeof(am))(f_active, di, am)
end

"""
$(TYPEDSIGNATURES)

Compute the pushforward (Jacobian-vector product) of `f` at `x` in direction `dx`,
via DifferentiationInterface.jl.

An anonymous closure captures `consts` and reconstructs the full argument tuple via
`ntuple`, placing `x_` at slot `Slot`. The single tangent is extracted with `only`.

See also: [`CTBase.Differentiation.differentiate`](@extref).
"""
function Differentiation.pushforward(
    backend::Differentiation.DifferentiationInterface,
    f,
    ::Val{Slot},
    x,
    dx,
    consts::Vararg{Any,N},
) where {Slot,N}
    di = _checked_backend(backend)
    inputs = _ad_inputs(di, x, dx, consts...)
    xm, dxm, cm = inputs[1], inputs[2], Base.tail(Base.tail(inputs))
    f_slot(x_) = f(ntuple(i -> i == Slot ? x_ : cm[i < Slot ? i : i - 1], Val(N + 1))...)
    return only(DI.pushforward(f_slot, di, xm, (dxm,)))
end

end # module
