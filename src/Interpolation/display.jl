"""
$(TYPEDSIGNATURES)

Display a compact representation of an [`Interpolant`](@ref).

# Example
```julia-repl
julia> ctinterpolate([0.0, 1.0, 2.0], [0.0, 1.0, 0.0])
Interpolant (linear): 3 nodes
```
"""
function Base.show(io::IO, interp::Interpolant{M}) where {M}
    label = M === Linear ? "linear" : "piecewise-constant"
    return print(io, "Interpolant ($label): $(length(interp.x)) nodes")
end

"""
$(TYPEDSIGNATURES)

Display an [`Interpolant`](@ref) in the REPL with the same format as `Base.show(io, interp)`.
"""
function Base.show(io::IO, ::MIME"text/plain", interp::Interpolant)
    return show(io, interp)
end
