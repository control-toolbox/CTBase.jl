"""
$(TYPEDEF)

Abstract base type for all trait markers.

Traits are empty marker types used as type parameters to encode properties at
compile time. Unlike tags (which mark extension implementations), traits encode
semantic properties of an object (e.g., integration mode, dynamics type,
mutability). All concrete trait types are empty structs with no fields, making
them zero-cost at runtime.

# Interface Requirements

Concrete trait subtypes should:
- Be empty structs with no fields (pure markers)
- Subtype an intermediate abstract trait category (e.g., `AbstractModeTrait`)
- Be used as type parameters or returned by accessor functions

# Example
\`\`\`julia-repl
julia> using CTBase.Traits

julia> EndPointMode <: Traits.AbstractTrait
true

julia> EndPointMode <: Traits.AbstractModeTrait
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
