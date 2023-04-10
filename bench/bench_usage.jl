using BenchmarkTools

# fun with dimension usage handled at each call
struct Fun_dim_usage_each_call
    f::Function
end

function (F::Fun_dim_usage_each_call)(t::Real, 
    x::Vector{<:Real}, u::Vector{<:Real}, args...; kwargs...)
    x_ = length(x)==1 ? (x[1],) : (x,)
    u_ = length(u)==1 ? (u[1],) : (u,)
    y = F.f(t, x_..., u_..., args...; kwargs...)
    return y isa Real ? [y] : y
end

#
t = 1
x = [10]
u = [100]

# bench fun with dimension usage handled at each call

# x, u scalar
F = Fun_dim_usage_each_call((t, x, u) -> x + u)
be = @benchmark y = F(t, x, u)
display(be)

# x scalar, u vector
F = Fun_dim_usage_each_call((t, x, u) -> x + u[1])
be = @benchmark y = F(t, x, u)
display(be)

# func with dimension usage handled a priori
struct Fun_dim_usage_a_priori
    f::Function
    dim_x::Int
    dim_u::Int
end

function (F::Fun_dim_usage_a_priori)(t::Real, 
    x::Vector{<:Real}, u::Vector{<:Real}, args...; kwargs...)
    x_ = F.dim_x==1 ? (x[1],) : (x,)
    u_ = F.dim_u==1 ? (u[1],) : (u,)
    y = F.f(t, x_..., u_..., args...; kwargs...)
    return y isa Real ? [y] : y
end

# bench func with dimension usage handled a priori

# x, u scalar
F = Fun_dim_usage_a_priori((t, x, u) -> x + u, 1, 1)
be = @benchmark y = F(t, x, u)
display(be)

# x scalar, u vector
F = Fun_dim_usage_a_priori((t, x, u) -> x + u[1], 1, 1)
be = @benchmark y = F(t, x, u)
display(be)

# fun with dimension usage handled by parameterization
struct Fun_dim_usage_parametrization{dim_x, dim_u}
    f::Function
end

function (F::Fun_dim_usage_parametrization{1, 1})(t::Real, 
    x::Vector{<:Real}, u::Vector{<:Real}, args...; kwargs...)
    return [F.f(t, x[1], u[1], args...; kwargs...)]
end

# bench fun with dimension usage handled by parameterization

# x, u scalar
F = Fun_dim_usage_parametrization{1, 1}((t, x, u) -> x + u)
be = @benchmark y = F(t, x, u)
display(be)

# x scalar, u vector
F = Fun_dim_usage_parametrization{1, 1}((t, x, u) -> x + u[1])
be = @benchmark y = F(t, x, u)
display(be)