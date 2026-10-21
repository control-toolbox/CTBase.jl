# =============================================================================
# Tag dispatch for backend-specific adjustments of the AD inputs
# =============================================================================

"""
$(TYPEDEF)

Tag of the `AutoMooncake` backend, used to dispatch backend-specific adjustments of the
AD inputs. The `CTBaseMooncake` extension overloads
[`CTBase.Differentiation._materialize`](@extref) for it.

See also: [`CTBase.Differentiation.GenericADTag`](@extref), [`CTBase.Differentiation._ad_tag`](@extref).
"""
struct MooncakeTag <: Core.AbstractTag end

"""
$(TYPEDEF)

Tag of every AD backend that needs no adjustment of its inputs.

See also: [`CTBase.Differentiation.MooncakeTag`](@extref), [`CTBase.Differentiation._ad_tag`](@extref).
"""
struct GenericADTag <: Core.AbstractTag end

"""
$(TYPEDSIGNATURES)

Tag of the ADTypes backend `ad`: [`CTBase.Differentiation.MooncakeTag`](@extref) for
`AutoMooncake`, [`CTBase.Differentiation.GenericADTag`](@extref) otherwise.

See also: [`CTBase.Differentiation._materialize`](@extref).
"""
_ad_tag(::ADTypes.AutoMooncake) = MooncakeTag
_ad_tag(::ADTypes.AbstractADType) = GenericADTag

"""
$(TYPEDSIGNATURES)

Return the AD input `x` in the form the backend of tag `T` differentiates correctly.

The default is `x` itself. Backend extensions overload it for the inputs their backend
mishandles: `CTBaseMooncake` replaces a view of a host array by a dense copy, because
Mooncake returns a structural tangent (not an array) for a `SubArray`.

See also: [`CTBase.Differentiation._ad_tag`](@extref).
"""
_materialize(::Type{<:Core.AbstractTag}, x) = x
