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
    s = ""
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
    s = ""
    for d ∈ digits(i)
        s = ctupperscript(d) * s
    end
    return s
end

"""
$(TYPEDSIGNATURES)

Return the gradient of `f` at `x`.
"""
function ctgradient(f::Function, x::ctNumber; backend = __get_AD_backend())
    return derivative(f, backend, x)
end

function __ctgradient(f::Function, x::ctNumber)
    return ForwardDiff.derivative(x -> f(x), x)
end

"""
$(TYPEDSIGNATURES)

Return the gradient of `f` at `x`.
"""
function ctgradient(f::Function, x; backend = __get_AD_backend())
    return gradient(f, backend, x)
end

function __ctgradient(f::Function, x)
    return ForwardDiff.gradient(f, x)
end

"""
$(TYPEDSIGNATURES)

Return the gradient of `X` at `x`.
"""
ctgradient(X::VectorField, x) = ctgradient(X.f, x)

__ctgradient(X::VectorField, x) = __ctgradient(X.f, x)

"""
$(TYPEDSIGNATURES)

Return the Jacobian of `f` at `x`.
"""
function ctjacobian(f::Function, x::ctNumber; backend = __get_AD_backend())
    f_number_to_number = only ∘ f ∘ only
    der = derivative(f_number_to_number, backend, x)
    return [der;;]
end

function __ctjacobian(f::Function, x::ctNumber)
    return ForwardDiff.jacobian(x -> f(x[1]), [x])
end

"""
$(TYPEDSIGNATURES)

Return the Jacobian of `f` at `x`.
"""
function ctjacobian(f::Function, x; backend = __get_AD_backend())
    return jacobian(f, backend, x)
end

__ctjacobian(f::Function, x) = ForwardDiff.jacobian(f, x)

"""
$(TYPEDSIGNATURES)

Return the Jacobian of `X` at `x`.
"""
ctjacobian(X::VectorField, x) = ctjacobian(X.f, x)

__ctjacobian(X::VectorField, x) = __ctjacobian(X.f, x)

"""
$(TYPEDSIGNATURES)

Return the interpolation of `f` at `x`.
"""
function ctinterpolate(x, f) # default for interpolation of the initialization
    return Interpolations.linear_interpolation(x, f, extrapolation_bc = Interpolations.Line())
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
    for i = (n + 1):n:(length(x) - n + 1)
        y = vcat(y, [x[i:(i + n - 1)]])
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

"""
$(TYPEDSIGNATURES)

Transforms `x` to a Vector{<:Vector{<:ctNumber}}.

**Note.** `dim` ∈ {1, 2} is the dimension along which the matrix is transformed.
"""
function matrix2vec(
    x::Matrix{<:ctNumber},
    dim::Integer = __matrix_dimension_stock(),
)::Vector{<:Vector{<:ctNumber}}
    m, n = size(x)
    y = nothing
    if dim == 1
        y = [x[1, :]]
        for i = 2:m
            y = vcat(y, [x[i, :]])
        end
    else
        y = [x[:, 1]]
        for j = 2:n
            y = vcat(y, [x[:, j]])
        end
    end
    return y
end

"""
$(TYPEDSIGNATURES)

Tranform in place function to out of place. Pass the result size and type (default = `Float64`).
Return a scalar when the result has size one. If `f!` is `nothing`, return `nothing`.
"""
function to_out_of_place(f!, n; T = Float64)
    function f(args...; kwargs...)
        r = zeros(T, n)
        f!(r, args...; kwargs...)
        return n == 1 ? r[1] : r
    end
    return isnothing(f!) ? nothing : f
end

# Adapt getters to test in place
function __constraint(ocp, label)
    if is_in_place(ocp)
        n = length(constraints(ocp)[label][3]) # Size of lb 
        return to_out_of_place(constraint(ocp, label), n)
    else
        return constraint(ocp, label)
    end
end

__dynamics(ocp) =
    is_in_place(ocp) ? to_out_of_place(dynamics(ocp), state_dimension(ocp)) : dynamics(ocp)
__lagrange(ocp) = is_in_place(ocp) ? to_out_of_place(lagrange(ocp), 1) : lagrange(ocp)
__mayer(ocp) = is_in_place(ocp) ? to_out_of_place(mayer(ocp), 1) : mayer(ocp)
