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
