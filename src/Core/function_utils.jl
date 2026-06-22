"""
$(TYPEDSIGNATURES)

Convert an in-place function `f!` to an out-of-place function `f`.

The resulting function `f` returns a vector of type `T` and length `n` by first allocating
memory and then calling `f!` to fill it.

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
        r = zeros(T, n)
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
