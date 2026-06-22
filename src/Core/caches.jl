"""
$(TYPEDEF)

Abstract base type for computation caches.

Caches store pre-allocated buffers and prepared plans (for example automatic
differentiation plans) so that repeated computations avoid reallocating on every
call. Concrete cache types are defined by the packages or extensions that provide
a specific backend.

# Interface Requirements

Concrete cache subtypes typically:
- Hold pre-allocated buffers and/or a prepared plan
- Are constructed once and reused across many calls
- Are backend- or extension-specific

# Example
```julia
struct MyCache <: AbstractCache
    buffer::Vector{Float64}
end
```

See also: [`AbstractTag`](@ref).
"""
abstract type AbstractCache end
