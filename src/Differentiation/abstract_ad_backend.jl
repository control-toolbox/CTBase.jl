# ==============================================================================
# AbstractADBackend — AD Backend Strategy Contract
# ==============================================================================

"""
$(TYPEDEF)

Abstract base type for automatic differentiation backends.

An `AbstractADBackend` is a strategy that defines how to compute gradients of a
scalar Hamiltonian function. Concrete backends (e.g., `DifferentiationInterface`)
implement the contract methods to provide actual gradient computation.

# Notes
 - `AbstractADBackend` subtypes `CTBase.Strategies.AbstractStrategy` — they are
   first-class strategies in the CTBase.Strategies ecosystem.
 - The contract comprises `ad_backend` (the wrapped ADTypes backend), the domain
   methods `hamiltonian_gradient`, `variable_gradient`, `pseudo_hamiltonian_gradient`,
   `pseudo_hamiltonian_control_gradient`, `pseudo_variable_gradient`, and the generic
   primitives `gradient`, `derivative`, `differentiate` and `pushforward`. All but
   `ad_backend` are supplied by the `CTBaseDifferentiationInterface` extension.
 - Gradient methods return **non-negated** partial derivatives; the RHS closures
   apply the signs (ṗ = -∂H/∂x, ṽ = -∂H/∂v).

See also: [`CTBase.Differentiation.DifferentiationInterface`](@ref),
[`CTBase.Differentiation.hamiltonian_gradient`](@ref),
[`CTBase.Differentiation.variable_gradient`](@ref).
"""
abstract type AbstractADBackend <: Strategies.AbstractStrategy end

# ==============================================================================
# Contract Methods
# ==============================================================================

"""
$(TYPEDSIGNATURES)

Compute the Hamiltonian gradient (∂H/∂x, ∂H/∂p) using the backend.

# Arguments
- `backend::AbstractADBackend`: The AD backend.
- `h`: The Hamiltonian function or type.
- `t`: Time (scalar).
- `x`: State vector.
- `p`: Costate vector.
- `v`: Variable (scalar or `nothing` for Fixed problems).

# Returns
- `(∂H_∂x, ∂H_∂p)`: Tuple of partial derivatives, **non-negated**. The RHS closure
  is responsible for applying the signs (ṗ = -∂H/∂x).

# Throws
- `CTBase.Exceptions.NotImplemented`: If the concrete backend does not implement this method.

See also: [`CTBase.Differentiation.variable_gradient`](@ref).
"""
function hamiltonian_gradient(
    backend::AbstractADBackend, h::Data.AbstractHamiltonian, t, x, p, v
)
    return throw(
        Exceptions.NotImplemented(
            "hamiltonian_gradient not implemented for $(typeof(backend))";
            required_method="hamiltonian_gradient(backend::$(typeof(backend)), h, t, x, p, v)",
            suggestion="Implement hamiltonian_gradient for $(typeof(backend)) or load an extension that provides gradient computation (e.g., CTBaseDifferentiationInterface)",
            context="AD backend contract",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Compute the variable gradient ∂H/∂v using the backend.

# Arguments
- `backend::AbstractADBackend`: The AD backend.
- `h`: The Hamiltonian function or type.
- `t`: Time (scalar).
- `x`: State vector.
- `p`: Costate vector.
- `v`: Variable (scalar or `nothing` for Fixed problems).

# Returns
- `∂H_∂v`: Partial derivative with respect to the variable, **non-negated**. The RHS
  closure is responsible for applying the sign (ṽ = -∂H/∂v).

# Throws
- `CTBase.Exceptions.NotImplemented`: If the concrete backend does not implement this method.

See also: [`CTBase.Differentiation.hamiltonian_gradient`](@ref).
"""
function variable_gradient(
    backend::AbstractADBackend, h::Data.AbstractHamiltonian, t, x, p, v
)
    return throw(
        Exceptions.NotImplemented(
            "variable_gradient not implemented for $(typeof(backend))";
            required_method="variable_gradient(backend::$(typeof(backend)), h, t, x, p, v)",
            suggestion="Implement variable_gradient for $(typeof(backend)) or load an extension that provides gradient computation (e.g., CTBaseDifferentiationInterface)",
            context="AD backend contract",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Compute the pseudo-Hamiltonian gradient (∂H̃/∂x, ∂H̃/∂p) using the backend.

Along a PMP solution, the stationarity condition ∂H̃/∂u = 0 holds, so the
Hamiltonian flow only requires ∂H̃/∂x and ∂H̃/∂p. Use
[`CTBase.Differentiation.pseudo_hamiltonian_control_gradient`](@ref) to compute ∂H̃/∂u separately
(e.g. for checking the stationarity condition).

# Arguments
- `backend::AbstractADBackend`: The AD backend.
- `h̃`: The pseudo-Hamiltonian function or type.
- `t`: Time (scalar).
- `x`: State vector.
- `p`: Costate vector.
- `u`: Control (scalar or vector).
- `v`: Variable (scalar or `nothing` for Fixed problems).

# Returns
- `(∂H̃_∂x, ∂H̃_∂p)`: Tuple of partial derivatives, **non-negated**. The RHS
  closure is responsible for applying the signs (ṗ = -∂H̃/∂x).

# Throws
- `CTBase.Exceptions.NotImplemented`: If the concrete backend does not implement this method.

See also: [`CTBase.Differentiation.pseudo_hamiltonian_control_gradient`](@ref),
[`CTBase.Differentiation.hamiltonian_gradient`](@ref),
[`CTBase.Differentiation.variable_gradient`](@ref).
"""
function pseudo_hamiltonian_gradient(
    backend::AbstractADBackend, h̃::Data.AbstractPseudoHamiltonian, t, x, p, u, v
)
    return throw(
        Exceptions.NotImplemented(
            "pseudo_hamiltonian_gradient not implemented for $(typeof(backend))";
            required_method="pseudo_hamiltonian_gradient(backend::$(typeof(backend)), h̃, t, x, p, u, v)",
            suggestion="Implement pseudo_hamiltonian_gradient for $(typeof(backend)) or load an extension that provides gradient computation (e.g., CTBaseDifferentiationInterface)",
            context="AD backend contract",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Compute the pseudo-Hamiltonian control gradient ∂H̃/∂u using the backend.

This is typically used to check the PMP stationarity condition ∂H̃/∂u = 0,
not for the Hamiltonian flow itself (which only needs ∂H̃/∂x and ∂H̃/∂p;
see [`CTBase.Differentiation.pseudo_hamiltonian_gradient`](@ref)).

# Arguments
- `backend::AbstractADBackend`: The AD backend.
- `h̃`: The pseudo-Hamiltonian function or type.
- `t`: Time (scalar).
- `x`: State vector.
- `p`: Costate vector.
- `u`: Control (scalar or vector).
- `v`: Variable (scalar or `nothing` for Fixed problems).

# Returns
- `∂H̃_∂u`: The partial derivative with respect to the control.

# Throws
- `CTBase.Exceptions.NotImplemented`: If the concrete backend does not implement this method.

See also: [`CTBase.Differentiation.pseudo_hamiltonian_gradient`](@ref),
[`CTBase.Differentiation.variable_gradient`](@ref).
"""
function pseudo_hamiltonian_control_gradient(
    backend::AbstractADBackend, h̃::Data.AbstractPseudoHamiltonian, t, x, p, u, v
)
    return throw(
        Exceptions.NotImplemented(
            "pseudo_hamiltonian_control_gradient not implemented for $(typeof(backend))";
            required_method="pseudo_hamiltonian_control_gradient(backend::$(typeof(backend)), h̃, t, x, p, u, v)",
            suggestion="Implement pseudo_hamiltonian_control_gradient for $(typeof(backend)) or load an extension that provides gradient computation (e.g., CTBaseDifferentiationInterface)",
            context="AD backend contract",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Compute the pseudo-Hamiltonian variable gradient ∂H̃/∂v using the backend, with the
control `u` held **constant**.

This is the pseudo-Hamiltonian analogue of [`CTBase.Differentiation.variable_gradient`](@ref),
used by the augmented (variable-costate) right-hand side of a `PseudoHamiltonianSystem`
where the control is fixed at the feedback value `u = u(t, x, p, v)`. Because `u` is
held constant, this is a **partial** derivative; it differs from the total derivative
`∂/∂v[H̃(t, x, p, u(t,x,p,v), v)]` whenever the feedback is not stationary (∂H̃/∂u ≠ 0).

# Arguments
- `backend::AbstractADBackend`: The AD backend.
- `h̃`: The pseudo-Hamiltonian function or type.
- `t`: Time (scalar).
- `x`: State vector.
- `p`: Costate vector.
- `u`: Control (scalar or vector), held constant during differentiation.
- `v`: Variable (scalar or `nothing` for Fixed problems).

# Returns
- `∂H̃_∂v`: Partial derivative with respect to the variable, **non-negated**. The RHS
  closure is responsible for applying the sign (ṗv = -∂H̃/∂v).

# Throws
- `CTBase.Exceptions.NotImplemented`: If the concrete backend does not implement this method.

See also: [`CTBase.Differentiation.variable_gradient`](@ref),
[`CTBase.Differentiation.pseudo_hamiltonian_gradient`](@ref).
"""
function pseudo_variable_gradient(
    backend::AbstractADBackend, h̃::Data.AbstractPseudoHamiltonian, t, x, p, u, v
)
    return throw(
        Exceptions.NotImplemented(
            "pseudo_variable_gradient not implemented for $(typeof(backend))";
            required_method="pseudo_variable_gradient(backend::$(typeof(backend)), h̃, t, x, p, u, v)",
            suggestion="Implement pseudo_variable_gradient for $(typeof(backend)) or load an extension that provides gradient computation (e.g., CTBaseDifferentiationInterface)",
            context="AD backend contract",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Extract the AD backend from a backend strategy.

# Arguments
- `backend::AbstractADBackend`: The AD backend.

# Returns
- `ADTypes.AbstractADType`: The concrete AD backend (e.g., `AutoForwardDiff()`).

# Throws
- `CTBase.Exceptions.NotImplemented`: If the concrete backend does not implement
  this method.

# Notes
 - This method is used by Hamiltonian vector-field getters to extract the AD backend
   from a Hamiltonian system's backend.
 - For `DifferentiationInterface`, this extracts the `:ad_backend` option.

See also: [`CTBase.Differentiation.DifferentiationInterface`](@ref).
"""
function ad_backend(backend::AbstractADBackend)
    return throw(
        Exceptions.NotImplemented(
            "ad_backend not implemented for $(typeof(backend))";
            required_method="ad_backend(backend::$(typeof(backend)))",
            suggestion="Implement ad_backend for $(typeof(backend))",
            context="AD backend contract",
        ),
    )
end

# =============================================================================
# Extension contract — gradient and derivative methods
# =============================================================================

"""
$(TYPEDSIGNATURES)

Compute the gradient of a scalar function using the backend.

# Arguments
- `backend::AbstractADBackend`: The AD backend.
- `f`: The scalar function to differentiate.
- `x`: The input vector.

# Returns
- `∇f`: The gradient of `f` at `x`.

# Throws
- `CTBase.Exceptions.NotImplemented`: If the concrete backend does not implement
  this method.

# Notes
 - This method is provided for extensions that implement gradient computation
   via DifferentiationInterface.jl.

See also: [`CTBase.Differentiation.derivative`](@ref),
[`CTBase.Differentiation.hamiltonian_gradient`](@ref).
"""
function gradient(backend::AbstractADBackend, f::Function, x)
    return throw(
        Exceptions.NotImplemented(
            "gradient not implemented for $(typeof(backend))";
            required_method="gradient(backend::$(typeof(backend)), f::Function, x)",
            suggestion="Load CTBaseDifferentiationInterface (load DifferentiationInterface)",
            context="AD backend contract",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Compute the derivative of a scalar function using the backend.

# Arguments
- `backend::AbstractADBackend`: The AD backend.
- `g`: The scalar function to differentiate.
- `t::Real`: The input scalar.

# Returns
- `dg/dt`: The derivative of `g` at `t`.

# Throws
- `CTBase.Exceptions.NotImplemented`: If the concrete backend does not implement
  this method.

# Notes
 - This method is provided for extensions that implement derivative computation
   via DifferentiationInterface.jl.

See also: [`CTBase.Differentiation.gradient`](@ref),
[`CTBase.Differentiation.variable_gradient`](@ref).
"""
function derivative(backend::AbstractADBackend, g::Function, t::Real)
    return throw(
        Exceptions.NotImplemented(
            "derivative not implemented for $(typeof(backend))";
            required_method="derivative(backend::$(typeof(backend)), g::Function, t::Real)",
            suggestion="Load CTBaseDifferentiationInterface (load DifferentiationInterface)",
            context="AD backend contract",
        ),
    )
end

# =============================================================================
# Partial differentiation and JVP primitives
# =============================================================================

"""
$(TYPEDSIGNATURES)

Compute the partial derivative or gradient of `f` with respect to the argument at
slot `Slot`, holding all other arguments fixed.

`f` is called as `f(arg₁, …, argₙ)`. The active argument is `active` (placed at
position `Slot`); the remaining `n-1` arguments are supplied as `consts...` in
slot order (skipping `Slot`).

# Arguments
- `backend::AbstractADBackend`: The AD backend.
- `f`: The function to differentiate (any callable).
- `::Val{Slot}`: Compile-time slot index of the active argument.
- `active`: The point at which to differentiate.
- `consts...`: The fixed arguments, in order of their slot positions (excluding `Slot`).

# Returns
- Gradient vector if `active isa AbstractArray`, scalar derivative if `active isa Real`.

# Throws
- `CTBase.Exceptions.NotImplemented`: If the concrete backend does not implement this method.

See also: [`CTBase.Differentiation.pushforward`](@ref).
"""
function differentiate(
    backend::AbstractADBackend, f, ::Val{Slot}, active, consts...
) where {Slot}
    return throw(
        Exceptions.NotImplemented(
            "differentiate not implemented for $(typeof(backend))";
            required_method="differentiate(backend::$(typeof(backend)), f, ::Val{Slot}, active, consts...)",
            suggestion="Load CTBaseDifferentiationInterface (load DifferentiationInterface)",
            context="AD backend contract",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Compute the pushforward (Jacobian-vector product) of `f` at `x` in direction `dx`,
holding fixed arguments `consts...` at the slots other than `Slot`.

Returns `d/ds f(x + s·dx, consts…)|_{s=0}` — the directional derivative of `f`
at `x` along `dx`, with all other arguments frozen.

# Arguments
- `backend::AbstractADBackend`: The AD backend.
- `f`: The function to differentiate (any callable).
- `::Val{Slot}`: Compile-time slot index of the active (differentiated) argument.
- `x`: The point at which to differentiate.
- `dx`: The direction (tangent vector, same shape as `x`).
- `consts...`: The fixed arguments, in slot order (excluding `Slot`).

# Returns
- The directional derivative `J_f(x) · dx`, same shape as `f(x, …)`.

# Throws
- `CTBase.Exceptions.NotImplemented`: If the concrete backend does not implement this method.

See also: [`CTBase.Differentiation.differentiate`](@ref).
"""
function pushforward(
    backend::AbstractADBackend, f, ::Val{Slot}, x, dx, consts...
) where {Slot}
    return throw(
        Exceptions.NotImplemented(
            "pushforward not implemented for $(typeof(backend))";
            required_method="pushforward(backend::$(typeof(backend)), f, ::Val{Slot}, x, dx, consts...)",
            suggestion="Load CTBaseDifferentiationInterface (load DifferentiationInterface)",
            context="AD backend contract",
        ),
    )
end
