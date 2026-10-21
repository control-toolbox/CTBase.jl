# =============================================================================
# Backend-specific adjustment of the AD inputs, dispatched on the ADTypes backend
# =============================================================================

"""
$(TYPEDSIGNATURES)

Return the AD input `x` in the form the ADTypes backend `ad` differentiates correctly.

The default is `x` itself. Backend extensions overload it for the inputs their backend
mishandles: `CTBaseMooncake` replaces, for `AutoMooncake`, a view of a host array by a
dense copy, because Mooncake returns a structural tangent (not an array) for a `SubArray`.
"""
_materialize(::ADTypes.AbstractADType, x) = x
