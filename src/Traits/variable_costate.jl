"""
$(TYPEDEF)

Abstract base type for variable costate capability traits.

Variable costate capability traits encode whether a system or flow can integrate
augmented variables (e.g., parameters, controls) and compute their associated
costates. This capability is used for trait-based dispatch in augmented integration.

Common use cases include:
- Hamiltonian systems: computing the costate of an augmented variable (∂H/∂v integration)
- Optimal control: integrating control variables with their adjoint equations
- Parameter estimation: treating parameters as dynamic variables with derivatives

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> SupportsVariableCostate() isa Traits.AbstractVariableCostateCapability
true

julia> NoVariableCostate() isa Traits.AbstractVariableCostateCapability
true
\`\`\`

# Notes
- `SupportsVariableCostate` indicates the system can compute derivatives with respect to augmented variables
- `NoVariableCostate` indicates the system cannot compute such derivatives
- This trait is used for dispatch to determine whether augmented integration is possible
- The specific operations enabled depend on the system type and context

See also: [`CTBase.Traits.SupportsVariableCostate`](@ref), [`CTBase.Traits.NoVariableCostate`](@ref).
"""
abstract type AbstractVariableCostateCapability <: AbstractTrait end

"""
$(TYPEDEF)

Trait for systems/flows that support augmented variable integration.

Indicates that the system or flow can compute derivatives with respect to augmented
variables (e.g., parameters, controls) and integrate their associated costates.
This typically requires automatic differentiation support and variable dependence.

Common use cases include:
- Hamiltonian systems: computing ∂H/∂v via AD from a scalar Hamiltonian
- Optimal control: integrating control variables with their adjoint equations
- General systems: any system where augmented variables need derivative computation

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> svc = SupportsVariableCostate()
SupportsVariableCostate()

julia> svc isa Traits.AbstractVariableCostateCapability
true
\`\`\`

# Notes
- Used as a return value from `variable_costate_trait` for systems that support augmented variable integration
- Typically requires AD support and variable dependence in the system
- This trait enables augmented integration operations in flow calls
- The specific implementation depends on the system type and AD backend

See also: [`CTBase.Traits.AbstractVariableCostateCapability`](@ref), [`CTBase.Traits.NoVariableCostate`](@ref), [`CTBase.Traits.variable_costate_trait`](@ref).
"""
struct SupportsVariableCostate <: AbstractVariableCostateCapability end

"""
$(TYPEDEF)

Trait for systems/flows that do not support augmented variable integration.

Indicates that the system or flow cannot compute derivatives with respect to augmented
variables or integrate their associated costates. This is the default for most systems,
including those with pre-computed derivatives or fixed parameters.

Common use cases include:
- Hamiltonian systems: pre-computed Hamiltonian vector fields without AD
- Fixed systems: systems with parameters that are not treated as dynamic variables
- General systems: any system where augmented variable integration is not applicable

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> nvc = NoVariableCostate()
NoVariableCostate()

julia> nvc isa Traits.AbstractVariableCostateCapability
true
\`\`\`

# Notes
- Default return value from `variable_costate_trait` for most systems and flows
- Systems without AD support or with fixed variable dependence typically return this
- Attempting augmented integration operations on such systems will throw an error
- The specific constraints depend on the system type

See also: [`CTBase.Traits.AbstractVariableCostateCapability`](@ref), [`CTBase.Traits.SupportsVariableCostate`](@ref), [`CTBase.Traits.variable_costate_trait`](@ref).
"""
struct NoVariableCostate <: AbstractVariableCostateCapability end

"""
$(TYPEDSIGNATURES)

Return the augmented variable integration capability trait of a system or flow.

# Arguments
- `obj`: Any object (default implementation returns `NoVariableCostate`).

# Returns
- `Type{<:AbstractVariableCostateCapability}`: The capability trait, either
  `SupportsVariableCostate` or `NoVariableCostate`.

# Notes
- Default implementation returns `NoVariableCostate` for all objects
- Specialized implementations on system and flow types return the appropriate trait based on the system's capabilities
- Used for dispatch to determine if augmented integration operations are possible
- The specific operations enabled depend on the system type

See also: [`CTBase.Traits.SupportsVariableCostate`](@ref), [`CTBase.Traits.NoVariableCostate`](@ref).
"""
variable_costate_trait(::Any) = NoVariableCostate
