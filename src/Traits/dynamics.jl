"""
$(TYPEDEF)

Abstract base type for dynamics traits (State vs Hamiltonian).

Dynamics traits encode the dynamics type in configuration types, distinguishing
between state-only configurations (no costate) and Hamiltonian configurations
(state + costate).

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> StateDynamics <: Traits.AbstractDynamicsTrait
true

julia> HamiltonianDynamics <: Traits.AbstractDynamicsTrait
true

julia> # Used in configuration type parameters:
julia> StateEndPointConfig <: CTFlows.Configs.AbstractConfig{<:Any, <:Traits.AbstractModeTrait, StateDynamics}
true
\`\`\`

# Notes
- Dynamics traits are used as the third type parameter in `AbstractConfigWithMaC`
- State dynamics indicates configurations with only state variables (no costate)
- Hamiltonian dynamics indicates configurations with both state and costate variables

See also: [`CTBase.Traits.StateDynamics`](@ref), [`CTBase.Traits.HamiltonianDynamics`](@ref), [`CTFlows.Configs.AbstractConfig`](@ref).
"""
abstract type AbstractDynamicsTrait <: AbstractTrait end

"""
$(TYPEDEF)

Trait for state dynamics (no costate).

Used as a type parameter in `AbstractConfig` to indicate state-only configurations,
which contain only state variables without associated costate variables.

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> st = StateDynamics()
StateDynamics()

julia> st isa Traits.AbstractDynamicsTrait
true

julia> # Used in state-only configurations:
julia> StateEndPointConfig <: CTFlows.Configs.AbstractConfig{<:Any, <:Traits.AbstractModeTrait, StateDynamics}
true
\`\`\`

# Notes
- State configurations store only `x0` (initial state)
- The `initial_costate` accessor throws a `PreconditionError` for state configurations
- This mode is suitable for standard ODE integration without adjoint variables

See also: [`CTBase.Traits.HamiltonianDynamics`](@ref), [`CTBase.Traits.AbstractDynamicsTrait`](@ref), [`CTFlows.Configs.StateEndPointConfig`](@ref).
"""
struct StateDynamics <: AbstractDynamicsTrait end

"""
$(TYPEDEF)

Trait for Hamiltonian dynamics (state + costate).

Used as a type parameter in `AbstractConfig` to indicate Hamiltonian configurations,
which contain both state variables and associated costate (adjoint) variables.

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> ham = HamiltonianDynamics()
HamiltonianDynamics()

julia> ham isa Traits.AbstractDynamicsTrait
true

julia> # Used in Hamiltonian configurations:
julia> HamiltonianEndPointConfig <: CTFlows.Configs.AbstractConfig{<:Any, <:Traits.AbstractModeTrait, HamiltonianDynamics}
true
\`\`\`

# Notes
- Hamiltonian configurations store both `x0` (initial state) and `p0` (initial costate)
- The `initial_condition` accessor returns `vcat(x0, p0)` for Hamiltonian configurations
- This mode is suitable for optimal control problems with Pontryagin's maximum principle

See also: [`CTBase.Traits.StateDynamics`](@ref), [`CTBase.Traits.AbstractDynamicsTrait`](@ref), [`CTFlows.Configs.HamiltonianEndPointConfig`](@ref).
"""
struct HamiltonianDynamics <: AbstractDynamicsTrait end

"""
$(TYPEDEF)

Trait marker for augmented Hamiltonian dynamics, where the Hamiltonian includes an augmented variable (e.g., a parameter or control variable) in addition to state and costate variables.

# Notes
- Used in conjunction with [`CTFlows.Configs.AbstractAugmentedHamiltonianConfig`](@ref) to specify that a configuration is for an augmented Hamiltonian system.
- Subtypes [`CTBase.Traits.AbstractDynamicsTrait`](@ref).
- Used to distinguish augmented Hamiltonian systems from standard Hamiltonian systems in trait-based dispatch.

See also: [`CTBase.Traits.HamiltonianDynamics`](@ref), [`CTFlows.Configs.AbstractAugmentedHamiltonianConfig`](@ref), [`CTBase.Traits.AbstractDynamicsTrait`](@ref).
"""
struct AugmentedHamiltonianDynamics <: AbstractDynamicsTrait end

"""
    dynamics_trait(x)

Return the dynamics trait of `x`.

Methods are defined on concrete types in `Systems` and `Configs`.

See also: [`CTBase.Traits.AbstractDynamicsTrait`](@ref), [`CTBase.Traits.StateDynamics`](@ref), [`CTBase.Traits.HamiltonianDynamics`](@ref).
"""
function dynamics_trait end
