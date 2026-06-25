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

import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES
using CTBase.Data: Data
using CTBase.Differentiation: Differentiation
using DifferentiationInterface: DifferentiationInterface as DI

# ==============================================================================
# Differentiation.hamiltonian_gradient / variable_gradient
# ==============================================================================

"""
$(TYPEDSIGNATURES)

Return the scalar DI differentiation primitive for a `Number` active argument.

Dispatches to `DI.derivative`, which computes `df/dx` for scalar `x`.

See also: [`_derivator(::Type{<:AbstractArray})`](@ref)
"""
function _derivator(::Type{<:Number})
    return DI.derivative
end

"""
$(TYPEDSIGNATURES)

Return the array DI differentiation primitive for an `AbstractArray` active argument.

Dispatches to `DI.gradient`, which computes `∇f` for array `x`.

See also: [`_derivator(::Type{<:Number})`](@ref)
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
    t, x, p, v,
)
    di_backend = Differentiation.ad_backend(backend)
    h_x(x_) = h(t, x_, p, v)
    h_p(p_) = h(t, x, p_, v)
    grad_x = _derivator(typeof(x))(h_x, di_backend, x)
    grad_p = _derivator(typeof(p))(h_p, di_backend, p)
    return (grad_x, grad_p)
end

"""
$(TYPEDSIGNATURES)

Compute variable gradient ∂H/∂v via DifferentiationInterface.jl.

See the note in [`hamiltonian_gradient`](@ref) on why anonymous closures are used.

# Returns
- `grad_v` = ∂H/∂v.
"""
function Differentiation.variable_gradient(
    backend::Differentiation.DifferentiationInterface,
    h::Data.AbstractHamiltonian,
    t, x, p, v,
)
    di_backend = Differentiation.ad_backend(backend)
    h_v(v_) = h(t, x, p, v_)
    return _derivator(typeof(v))(h_v, di_backend, v)
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
- [`CTBase.Differentiation.derivative`](@ref)
"""
function Differentiation.gradient(
    backend::Differentiation.DifferentiationInterface,
    f::Function,
    x::AbstractArray,
)
    ad = Differentiation.ad_backend(backend)
    return DI.gradient(f, ad, x)
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
- [`CTBase.Differentiation.derivative`](@ref)
"""
function Differentiation.gradient(
    backend::Differentiation.DifferentiationInterface,
    f::Function,
    x::Real,
)
    ad = Differentiation.ad_backend(backend)
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
- [`CTBase.Differentiation.gradient`](@ref)
"""
function Differentiation.derivative(
    backend::Differentiation.DifferentiationInterface,
    g::Function,
    t::Real,
)
    ad = Differentiation.ad_backend(backend)
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
via `ntuple` — same rationale as [`hamiltonian_gradient`](@ref) (ForwardDiff tag ordering).
`_derivator` dispatches to `DI.gradient` for array `active` and `DI.derivative` for scalar.

See also: [`CTBase.Differentiation.pushforward`](@ref).
"""
function Differentiation.differentiate(
    backend::Differentiation.DifferentiationInterface,
    f,
    ::Val{Slot},
    active,
    consts::Vararg{Any, N},
) where {Slot, N}
    di = Differentiation.ad_backend(backend)
    f_active(active_) = f(ntuple(i -> i == Slot ? active_ : consts[i < Slot ? i : i - 1], Val(N + 1))...)
    return _derivator(typeof(active))(f_active, di, active)
end

"""
$(TYPEDSIGNATURES)

Compute the pushforward (Jacobian-vector product) of `f` at `x` in direction `dx`,
using DifferentiationInterface.jl.

An anonymous closure captures `consts` and reconstructs the full argument tuple via
`ntuple`, placing `x_` at slot `Slot`. The single tangent is extracted with `only`.

See also: [`CTBase.Differentiation.differentiate`](@ref).
"""
function Differentiation.pushforward(
    backend::Differentiation.DifferentiationInterface,
    f,
    ::Val{Slot},
    x,
    dx,
    consts::Vararg{Any, N},
) where {Slot, N}
    di = Differentiation.ad_backend(backend)
    f_slot(x_) = f(ntuple(i -> i == Slot ? x_ : consts[i < Slot ? i : i - 1], Val(N + 1))...)
    return only(DI.pushforward(f_slot, di, x, (dx,)))
end

end # module
