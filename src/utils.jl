#
ctindice(i::Integer) = '\u2080' + i
function ctindices(i::Integer)
    s=""
    for d ∈ digits(i)
        s = ctindice(d) * s
    end
    return s
end

# method to compute gradient and Jacobian
ctgradient(f::Function, x) = ForwardDiff.gradient(f, x)
ctjacobian(f::Function, x) = ForwardDiff.jacobian(f, x)

# simple interpolation
function ctinterpolate(x, f) # default for interpolation of the initialization
    return Interpolations.linear_interpolation(x, f, extrapolation_bc=Interpolations.Line())
end

# transform a Vector{<:Vector{<:MyNumber}} to a Vector{<:MyNumber}
function vec2vec(x::Vector{<:Vector{<:MyNumber}})
    y = x[1]
    for i in range(2, length(x))
        y = vcat(y, x[i])
    end
    return y
end

# transform a Vector{<:MyNumber} to a Vector{<:Vector{<:MyNumber}}
function vec2vec(x::Vector{<:MyNumber}, n::Integer)
    y = [x[1:n]]
    for i in n+1:n:length(x)-n+1
        y = vcat(y, [x[i:i+n-1]])
    end
    return y
end

expand(x::Vector{<:Vector{<:MyNumber}}) = vec2vec(x)
expand(x::Vector{<:MyNumber}) = x
expand(x::Matrix{<:MyNumber}) = expand(matrix2vec(x, 1))

# transform a Matrix{<:MyNumber} to a Vector{<:Vector{<:MyNumber}}
function matrix2vec(x::Matrix{<:MyNumber}, dim::Integer=__matrix_dimension_stock())
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

#
function Ad(X, f)
    return x -> ctgradient(f, x)'*X(x)
end

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