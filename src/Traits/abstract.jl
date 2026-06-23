"""
$(TYPEDEF)

Abstract base type for trait markers in CTFlows.

Traits are empty marker types used as type parameters to encode configuration
properties at compile time. Unlike tags (which mark extension implementations),
traits encode semantic properties of the configuration itself (e.g., integration
mode, content type, mutability).

# Trait Pattern

Traits are used as type parameters in abstract configuration types to enable
compile-time dispatch without runtime type checks. For example, `AbstractConfig`
uses `EndPointMode` vs `TrajectoryMode` to distinguish integration modes, and
`StateDynamics` vs `HamiltonianDynamics` to distinguish dynamics types.

All concrete trait types are empty structs with no fields, making them zero-cost
at runtime.

# Interface Requirements

Concrete trait subtypes should:
- Be empty structs with no fields (pure markers)
- Subtype an intermediate abstract trait category (e.g., `AbstractModeTrait`)
- Be used as type parameters in configuration types

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> EndPointMode <: Traits.AbstractTrait
true

julia> EndPointMode <: Traits.AbstractModeTrait
true

julia> # Used as type parameters in configs:
julia> StateEndPointConfig <: CTFlows.Configs.AbstractConfig{<:Any, EndPointMode, StateDynamics}
true
\`\`\`

# Notes
- Traits are distinct from tags: tags mark extension implementations (e.g., `SciMLTag`),
  while traits encode configuration semantics (e.g., `EndPointMode`)
- All trait types have zero runtime overhead (empty structs)
- The trait pattern enables static dispatch on configuration properties

See also: [`CTBase.Traits.VariableDependence`](@ref), [`CTBase.Traits.AbstractModeTrait`](@ref), [`CTBase.Traits.AbstractDynamicsTrait`](@ref), [`CTBase.Traits.AbstractMutabilityTrait`](@ref).
"""
abstract type AbstractTrait end
