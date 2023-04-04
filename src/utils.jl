"""
$(TYPEDSIGNATURES)

Returns `i` ∈ [0, 9] as a subscript.
"""
function ctindice(i::Integer)::Char
    if i < 0 || i > 9
        throw(IncorrectArgument("the indice must be between 0 and 9"))
    end
    return '\u2080' + i
end

"""
$(TYPEDSIGNATURES)

Returns `i` > 0 as a subscript.
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

Returns `i` ∈ [0, 9] as an upperscript.
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

Returns `i` > 0 as an upperscript.
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

Returns the gradient of `f` at `x`.
"""
ctgradient(f::Function, x) = ForwardDiff.gradient(f, x)

"""
$(TYPEDSIGNATURES)

Returns the Jacobian of `f` at `x`.
"""
ctjacobian(f::Function, x) = ForwardDiff.jacobian(f, x)

"""
$(TYPEDSIGNATURES)

Returns the interpolation of `f` at `x`.
"""
function ctinterpolate(x, f) # default for interpolation of the initialization
    return Interpolations.linear_interpolation(x, f, extrapolation_bc=Interpolations.Line())
end

"""
$(TYPEDSIGNATURES)

Transforms `x` to a Vector{<:MyNumber}.
"""
function vec2vec(x::Vector{<:Vector{<:MyNumber}})::Vector{<:MyNumber}
    y = x[1]
    for i in range(2, length(x))
        y = vcat(y, x[i])
    end
    return y
end

"""
$(TYPEDSIGNATURES)

Transforms `x` to a Vector{<:Vector{<:MyNumber}}.
"""
function vec2vec(x::Vector{<:MyNumber}, n::Integer)::Vector{<:Vector{<:MyNumber}}
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
expand(x::Vector{<:Vector{<:MyNumber}}) = vec2vec(x)

"""
$(TYPEDSIGNATURES)

Returns `x`.
"""
expand(x::Vector{<:MyNumber}) = x

"""
$(TYPEDSIGNATURES)

Returns `expand(matrix2vec(x, 1))`
"""
expand(x::Matrix{<:MyNumber}) = expand(matrix2vec(x, 1))

# transform a Matrix{<:MyNumber} to a Vector{<:Vector{<:MyNumber}}
"""
$(TYPEDSIGNATURES)

Transforms `x` to a Vector{<:Vector{<:MyNumber}}.

**Note.** `dim` ∈ {1, 2} is the dimension along which the matrix is transformed.
"""
function matrix2vec(x::Matrix{<:MyNumber}, dim::Integer=__matrix_dimension_stock())::Vector{<:Vector{<:MyNumber}}
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

"""
$(TYPEDSIGNATURES)

Lie derivative of `f` along `X`.
"""
function Ad(X, f)
    return x -> ctgradient(f, x)'*X(x)
end

"""
$(TYPEDSIGNATURES)

Returns the Poisson bracket of `f` and `g`.
"""
function Poisson(f, g)
    function fg(x, p)
        n = size(x, 1)
        ff = z -> f(z[1:n], z[n+1:2n])
        gg = z -> g(z[1:n], z[n+1:2n])
        df = ctgradient(ff, [ x ; p ])
        dg = ctgradient(gg, [ x ; p ])
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n]
    end
    return fg
end