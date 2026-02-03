"""
$(TYPEDSIGNATURES)

Print a tuple of descriptions, one per line.

# Example

```julia-repl
julia> using CTBase

julia> display(((:a, :b), (:b, :c)))
(:a, :b)
(:b, :c)
```
"""
function Base.show(io::IO, ::MIME"text/plain", descriptions::Tuple{Vararg{Description}})
    N = length(descriptions)  # use length instead of size for 1D tuple
    for i in 1:N
        description = descriptions[i]
        # print with newline except for last
        if i < N
            print(io, "$description\n")
        else
            print(io, "$description")
        end
    end
    return nothing
end
