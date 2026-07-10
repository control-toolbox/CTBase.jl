"""
$(TYPEDSIGNATURES)

Promote the element type of the numeric arguments (scalars and arrays) so the
allocated buffer can hold e.g. `ForwardDiff.Dual` values during differentiation.

Falls back to `Union{}` for non-numeric arguments (e.g. `nothing`), which is neutral
under `promote_type`. Combined with the `T` floor in [`to_out_of_place`](@ref),
non-numeric-only calls keep `T`.

See also: [`CTBase.Core.to_out_of_place`](@ref).
"""
_promote_arg_eltype() = Union{}
function _promote_arg_eltype(x::Number, rest...)
    return promote_type(typeof(x), _promote_arg_eltype(rest...))
end
function _promote_arg_eltype(x::AbstractArray, rest...)
    return promote_type(eltype(x), _promote_arg_eltype(rest...))
end
_promote_arg_eltype(_, rest...) = _promote_arg_eltype(rest...)

"""
$(TYPEDSIGNATURES)

Convert an in-place function `f!` to an out-of-place function `f`.

The resulting function `f` returns a vector of type `T` and length `n` by first allocating
memory and then calling `f!` to fill it.

The buffer element type is widened from the call arguments (via
[`_promote_arg_eltype`](@ref)) so that `ForwardDiff.Dual` values are accommodated
during automatic differentiation. The `T` keyword acts as a floor, so plain
`Float64`/`Int` calls keep their previous behaviour.

# Arguments
- `f!`: An in-place function of the form `f!(result, args...)`.
- `n`: The length of the output vector.
- `T`: The element type of the output vector (default is `Float64`).

# Returns
An out-of-place function `f(args...; kwargs...)` that returns the result as a vector or
scalar, depending on `n`.

# Example
```julia-repl
julia> f!(r, x) = (r[1] = sin(x); r[2] = cos(x))
julia> f = to_out_of_place(f!, 2)
julia> f(π/4)  # returns approximately [0.707, 0.707]
```
"""
function to_out_of_place(f!, n; T=Float64)
    function f(args...; kwargs...)
        # Widen the floor type `T` with the arguments' element types so the buffer can
        # hold Dual numbers under AD; `promote_type(Float64, Int) == Float64` keeps the
        # existing behaviour for plain numeric calls.
        TT = promote_type(T, _promote_arg_eltype(args...))
        r = zeros(TT, n)
        f!(r, args...; kwargs...)
        return n == 1 ? r[1] : r
    end
    return isnothing(f!) ? nothing : f
end

"""
    make_coerce(x) -> coerce_fn

Return a coercion function matching the shape of `x`.

For scalars (`Number`), returns `only`, which extracts the single element from a
1-element vector. For arrays (`AbstractVector`, `AbstractMatrix`), returns
`identity` (a no-op). This is used to map a uniform vector-valued result back to
the natural shape of the original input.

# Arguments
- `x`: A value whose type determines the coercion strategy.

# Returns
- A coercion function with signature `(y) -> coerced_y`.

# Example
```julia-repl
julia> coerce_scalar = make_coerce(1.0);

julia> coerce_scalar([5.0])
5.0

julia> coerce_vector = make_coerce([1.0, 2.0]);

julia> coerce_vector([3.0, 4.0])
2-element Vector{Float64}:
 3.0
 4.0
```
"""
make_coerce(::Number) = only
make_coerce(::AbstractVector) = identity
make_coerce(::AbstractMatrix) = identity
