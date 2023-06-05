"""
$(TYPEDSIGNATURES)

Return `i` ∈ [0, 9] as a subscript.
"""
function ctindice(i::Integer)::Char
    if i < 0 || i > 9
        throw(IncorrectArgument("the indice must be between 0 and 9"))
    end
    return '\u2080' + i
end

"""
$(TYPEDSIGNATURES)

Return `i` > 0 as a subscript.
"""
function ctindices(i::Integer)::String
    if i < 0
        throw(IncorrectArgument("the indice must be positive"))
    end
    s=""
    for d ∈ digits(i)
        s = ctindice(d) * s
    end
    return s
end

"""
$(TYPEDSIGNATURES)

Return `i` ∈ [0, 9] as an upperscript.
"""
function ctupperscript(i::Integer)::Char
    if i < 0 || i > 9
        throw(IncorrectArgument("the upperscript must be between 0 and 9"))
    end
    if i == 0
        return '\u2070'
    end
    if i == 1
        return '\u00B9'
    end
    if i == 2
        return '\u00B2'
    end
    if i == 3
        return '\u00B3'
    end
    if i ≥ 4
        return '\u2074' + i - 4
    end
end

"""
$(TYPEDSIGNATURES)

Return `i` > 0 as an upperscript.
"""
function ctupperscripts(i::Integer)::String
    if i < 0
        throw(IncorrectArgument("the upperscript must be positive"))
    end
    s=""
    for d ∈ digits(i)
        s = ctupperscript(d) * s
    end
    return s
end

"""
$(TYPEDSIGNATURES)

Return the gradient of `f` at `x`.
"""
function ctgradient(f::Function, x::ctNumber)
    return ForwardDiff.derivative(x -> f(x), x)
end

"""
$(TYPEDSIGNATURES)

Return the gradient of `f` at `x`.
"""
function ctgradient(f::Function, x)
    return ForwardDiff.gradient(f, x)
end

"""
$(TYPEDSIGNATURES)

Return the gradient of `X` at `x`.
"""
ctgradient(X::VectorField, x) = ctgradient(X.f, x)

"""
$(TYPEDSIGNATURES)

Return the Jacobian of `f` at `x`.
"""
function ctjacobian(f::Function, x::ctNumber) 
    return ForwardDiff.jacobian(x -> f(x[1]), [x])
end

"""
$(TYPEDSIGNATURES)

Return the Jacobian of `f` at `x`.
"""
ctjacobian(f::Function, x) = ForwardDiff.jacobian(f, x)

"""
$(TYPEDSIGNATURES)

Return the Jacobian of `X` at `x`.
"""
ctjacobian(X::VectorField, x) = ctjacobian(X.f, x)

"""
$(TYPEDSIGNATURES)

Return the interpolation of `f` at `x`.
"""
function ctinterpolate(x, f) # default for interpolation of the initialization
    return Interpolations.linear_interpolation(x, f, extrapolation_bc=Interpolations.Line())
end

"""
$(TYPEDSIGNATURES)

Transforms `x` to a Vector{<:ctNumber}.
"""
function vec2vec(x::Vector{<:Vector{<:ctNumber}})::Vector{<:ctNumber}
    y = x[1]
    for i in range(2, length(x))
        y = vcat(y, x[i])
    end
    return y
end

"""
$(TYPEDSIGNATURES)

Transforms `x` to a Vector{<:Vector{<:ctNumber}}.
"""
function vec2vec(x::Vector{<:ctNumber}, n::Integer)::Vector{<:Vector{<:ctNumber}}
    y = [x[1:n]]
    for i in n+1:n:length(x)-n+1
        y = vcat(y, [x[i:i+n-1]])
    end
    return y
end

"""
$(TYPEDSIGNATURES)

Equivalent to `vec2vec(x)`
"""
expand(x::Vector{<:Vector{<:ctNumber}}) = vec2vec(x)

"""
$(TYPEDSIGNATURES)

Return `x`.
"""
expand(x::Vector{<:ctNumber}) = x

"""
$(TYPEDSIGNATURES)

Return `expand(matrix2vec(x, 1))`
"""
expand(x::Matrix{<:ctNumber}) = expand(matrix2vec(x, 1))

# transform a Matrix{<:ctNumber} to a Vector{<:Vector{<:ctNumber}}
"""
$(TYPEDSIGNATURES)

Transforms `x` to a Vector{<:Vector{<:ctNumber}}.

**Note.** `dim` ∈ {1, 2} is the dimension along which the matrix is transformed.
"""
function matrix2vec(x::Matrix{<:ctNumber}, dim::Integer=__matrix_dimension_stock())::Vector{<:Vector{<:ctNumber}}
    m, n = size(x)
    y = nothing
    if dim==1
        y = [x[1,:]]
        for i in 2:m
            y = vcat(y, [x[i,:]])
        end
    else
        y = [x[:,1]]
        for j in 2:n
            y = vcat(y, [x[:,j]])
        end
    end
    return y
end