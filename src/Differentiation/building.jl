# ==============================================================================
# build_ad_backend — Factory for AD Backends
# ==============================================================================

"""
$(TYPEDSIGNATURES)

Factory function to build an AD backend with default options.

# Arguments
- `kwargs...`: Options passed to `DifferentiationInterface` constructor.

# Returns
- `DifferentiationInterface`: A new AD backend strategy instance.

# Notes
 - This is a convenience factory that always returns a `DifferentiationInterface`
   instance with the provided options.

See also: [`CTBase.Differentiation.DifferentiationInterface`](@ref).
"""
function build_ad_backend(; kwargs...)
    return DifferentiationInterface(; kwargs...)
end
