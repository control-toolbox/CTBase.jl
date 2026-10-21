"""
    CTBaseMooncake

Package extension adjusting the AD inputs of `CTBase.Differentiation` for the
`AutoMooncake` backend.

Activated automatically when `Mooncake` is loaded together with `CTBase`.

This extension provides:
- `Differentiation._materialize(::Type{MooncakeTag}, x::SubArray)` — a dense copy of a view
  of a host array. Mooncake returns a structural `Mooncake.Tangent` (fields `parent`,
  `indices`, …) for a `SubArray` instead of an array, even with `friendly_tangents=true`
  (chalk-lab/Mooncake.jl#1294), so a gradient taken at a view cannot be used as an array.
  Device arrays are left alone: Mooncake's CUDA rules handle them.
"""
module CTBaseMooncake

using DocStringExtensions: TYPEDSIGNATURES
using CTBase: Differentiation
using Mooncake: Mooncake

"""
$(TYPEDSIGNATURES)

Dense copy of the view `x` of a host array, so that Mooncake differentiates (and the
closures of `CTBase.Differentiation` capture) an `Array` rather than a `SubArray`.

See also: [`CTBase.Differentiation._materialize`](@extref).
"""
function Differentiation._materialize(
    ::Type{Differentiation.MooncakeTag}, x::SubArray{<:Any,<:Any,<:Array}
)
    return copy(x)
end

end # module
