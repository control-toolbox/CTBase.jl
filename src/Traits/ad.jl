"""
$(TYPEDEF)

Abstract base type for automatic differentiation capability traits.

AD traits encode whether a system supports automatic differentiation for gradient
computation. This distinction enables compile-time dispatch for cache preparation,
derivative computation, and other AD-related operations.

Common use cases include:
- Hamiltonian systems: distinguishing between scalar Hamiltonians with AD backends
  and pre-computed Hamiltonian vector fields
- General optimization: marking systems that can compute gradients via AD vs. those
  with manual derivative implementations
- Cache preparation: enabling static dispatch for AD-specific cache initialization

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> WithAD() isa Traits.AbstractADTrait
true

julia> WithoutAD() isa Traits.AbstractADTrait
true
\`\`\`

# Notes
- AD traits are used as type parameters in system types to enable static dispatch
- `WithAD` indicates the system carries differentiable functions and an AD backend
- `WithoutAD` indicates the system uses pre-computed derivatives or manual implementations
- The specific meaning depends on the system type and context

See also: [`CTBase.Traits.WithAD`](@ref), [`CTBase.Traits.WithoutAD`](@ref), [`CTBase.Core.AbstractCache`](@ref).
"""
abstract type AbstractADTrait <: AbstractTrait end

"""
$(TYPEDEF)

Trait for systems with automatic differentiation support.

Indicates that a system carries differentiable functions and an AD backend,
enabling automatic computation of derivatives. Such systems typically require
cache preparation before operations that need gradients or Jacobians.

Common use cases include:
- Hamiltonian systems: scalar Hamiltonians where the vector field is computed via AD
- Optimization: objective functions where gradients are computed via AD
- General systems: any differentiable function that benefits from automatic gradient computation

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> with = WithAD()
WithAD()

julia> with isa Traits.AbstractADTrait
true
\`\`\`

# Notes
- Used as a type parameter in system types to enable AD-based derivative computation
- Systems with `WithAD` typically require cache preparation via the backend's `prepare_cache` method
- The cache is passed through parameters during integration or evaluation
- The specific operations enabled depend on the system type and AD backend

See also: [`CTBase.Traits.AbstractADTrait`](@ref), [`CTBase.Traits.WithoutAD`](@ref), [`CTBase.Core.AbstractCache`](@ref).
"""
struct WithAD <: AbstractADTrait end  # system carries H + AD backend

"""
$(TYPEDEF)

Trait for systems without automatic differentiation support.

Indicates that a system uses pre-computed derivatives or manual implementations,
without requiring AD or cache preparation. This is the traditional mode where
derivatives are provided explicitly by the user or computed offline.

Common use cases include:
- Hamiltonian systems: pre-computed Hamiltonian vector fields provided manually
- Optimization: manually implemented gradient functions
- General systems: any system where derivatives are known analytically or computed externally

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> without = WithoutAD()
WithoutAD()

julia> without isa Traits.AbstractADTrait
true
\`\`\`

# Notes
- Used as a type parameter in system types for derivative-based systems without AD
- No cache preparation is required for `WithoutAD` systems
- This is the default mode for systems with pre-computed derivatives
- The specific derivative implementations depend on the system type

See also: [`CTBase.Traits.AbstractADTrait`](@ref), [`CTBase.Traits.WithAD`](@ref).
"""
struct WithoutAD <: AbstractADTrait end  # system carries HVF directly

"""
$(TYPEDSIGNATURES)

Return the automatic differentiation capability trait of a system or flow.

# Arguments
- `obj`: Any object (default implementation returns `WithoutAD`).

# Returns
- `Type{<:AbstractADTrait}`: The AD capability trait, either `WithAD` or `WithoutAD`.

# Notes
- Default implementation returns `WithoutAD` for all objects
- Specialized implementations on system types return the appropriate trait based on the system's AD support
- Used for dispatch in cache preparation, derivative computation, and augmented integration
- The specific operations enabled by the trait depend on the system type

See also: [`CTBase.Traits.AbstractADTrait`](@ref), [`CTBase.Traits.WithAD`](@ref), [`CTBase.Traits.WithoutAD`](@ref).
"""
ad_trait(::Any) = WithoutAD
