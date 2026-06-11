"""
$(TYPEDSIGNATURES)

Return the default dimension for matrix storage.
"""
__matrix_dimension_storage() = 1

"""
$(TYPEDSIGNATURES)

Transform a matrix into a vector of vectors along the specified dimension.

Each row or column of the matrix `A` is extracted and stored as an individual vector,
depending on `dim`.

# Arguments
- `A`: A matrix of elements of type `<:ctNumber`.
- `dim`: The dimension along which to split the matrix (`1` for rows, `2` for columns).
  Defaults to `1`.

# Returns
A `Vector` of `Vector`s extracted from the rows or columns of `A`.

# Note
This is useful when data needs to be represented as a sequence of state or control vectors
in optimal control problems.

# Example
```julia-repl
julia> A = [1 2 3; 4 5 6]
julia> matrix2vec(A, 1)  # splits into rows: [[1, 2, 3], [4, 5, 6]]
julia> matrix2vec(A, 2)  # splits into columns: [[1, 4], [2, 5], [3, 6]]
```
"""
function matrix2vec(
    A::Matrix{<:ctNumber}, dim::Int=__matrix_dimension_storage()
)::Vector{<:Vector{<:ctNumber}}
    return dim == 1 ? [A[i, :] for i in 1:size(A, 1)] : [A[:, i] for i in 1:size(A, 2)]
end
