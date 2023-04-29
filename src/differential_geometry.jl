#=
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
=#

# ---------------------------------------------------------------------------
abstract type AbstractHamiltonian end

# ---------------------------------------------------------------------------
# HamiltonianLift
struct HamiltonianLift{time_dependence} <: AbstractHamiltonian
    X::VectorField
    function HamiltonianLift(X::VectorField{time_dependence, state_dimension}) where {time_dependence, state_dimension}
        new{time_dependence}(X)
    end
end

# classical calls
function (H::HamiltonianLift{:nonautonomous})(t::Time, x::ctNumber, p::ctNumber, args...; kwargs...)::ctNumber
    return p'*H.X(t, x, args...; kwargs...)
end
function (H::HamiltonianLift{:autonomous})(x::ctNumber, p::ctNumber, args...; kwargs...)::ctNumber
    return p'*H.X(x, args...; kwargs...)
end
function (H::HamiltonianLift{:nonautonomous})(t::Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber
    return p'*H.X(t, x, args...; kwargs...)
end
function (H::HamiltonianLift{:autonomous})(x::State, p::Adjoint, args...; kwargs...)::ctNumber
    return p'*H.X(x, args...; kwargs...)
end

# ---------------------------------------------------------------------------
# Lift
#
# single lift
function Lift(X::VectorField)::HamiltonianLift
    return HamiltonianLift(X)
end
function Lift(X::Function; time_dependence::Symbol=CTBase.__fun_time_dependence())::HamiltonianLift
    #
    check_time_dependence(time_dependence)
    #
    return HamiltonianLift(VectorField(X, time_dependence=time_dependence))
end
#
# multiple lifts
function Lift(Xs::VectorField...)::Tuple{Vararg{HamiltonianLift}}
    return Tuple(Lift(X) for X ∈ Xs)
end
function Lift(Xs::Function...; time_dependence::Symbol=CTBase.__fun_time_dependence())::Tuple{Vararg{HamiltonianLift}}
    #
    check_time_dependence(time_dependence)
    #
    return Tuple(Lift(X, time_dependence=time_dependence) for X ∈ Xs)
end

# ---------------------------------------------------------------------------
# Lie derivative
function Lie(X::VectorField{:autonomous, sd}, f::Function)::Function where {sd}
    return x -> ctgradient(f, x)'*X(x)
end
function Lie(X::VectorField{:nonautonomous, sd}, f::Function)::Function where {sd}
    return (t, x) -> ctgradient(y -> f(t, y), x)'*X(t, x)
end
function ⋅(X::VectorField{td, sd}, f::Function)::Function where {td, sd}
    return Lie(X, f)
end

# ---------------------------------------------------------------------------
# Lie bracket of order 1
function Lie(X::VectorField{:autonomous, sd}, Y::VectorField{:autonomous, sd})::VectorField{:autonomous, sd} where {sd}
    return VectorField(x -> (ctjacobian(Y, x)*X(x)-ctjacobian(X, x)*Y(x)), 
                time_dependence=:autonomous, state_dimension=sd, label=Symbol(X.label, Y.label))
end
function Lie(X::VectorField{:nonautonomous, sd}, Y::VectorField{:nonautonomous, sd})::VectorField{:nonautonomous, sd} where {sd}
    return VectorField((t, x) -> (ctjacobian(y -> Y(t, y), x)*X(t, x)-ctjacobian(y -> X(t, y), x)*Y(t, x)), 
                time_dependence=:nonautonomous, state_dimension=sd, label=Symbol(X.label, Y.label))
end
function ⋅(X::VectorField{td, sd}, Y::VectorField{td, sd})::VectorField{td, sd} where {td, sd}
    return Lie(X, Y)
end

# Multiple lie brackets of any order
const Order = Tuple{Vararg{Integer}}
const Orders = Tuple{Vararg{Order}}
const OrderLabels = Tuple{Vararg{Symbol}}
const OrdersLabels = Tuple{Vararg{OrderLabels}}

#
__fun_order(Xs::VectorField) = Tuple(1:length(Xs))

#
function Lie_order(Xs::VectorField{td, sd}...; order::Order=__fun_order(Xs))::VectorField{td, sd} where {td, sd}

    # check length of Xs
    length(Xs) < 2 && throw(IncorrectArgument("Xs must have at least two elements"))

    # check length of order
    length(order) < 2 && throw(IncorrectArgument("order must have at least two elements"))
    
    # check if the elements of order are contained in 1:length(Xs)
    for o ∈ order
        o < 1 && throw(IncorrectArgument("order must contain only positive integers"))
        o > length(Xs) && throw(IncorrectArgument("order must contain only integers less than or equal to the length of Xs"))
    end

    # 
    if length(order) == 2
        return Lie(Xs[order[1]], Xs[order[2]])
    else
        return Lie(Lie(Xs..., order=order[1:end-1]), Xs[order[end]])
    end

end

#
__fun_order_labels(Xs::VectorField...) = Tuple([X.label for X ∈ Xs])

#
function Lie_order_labels(Xs::VectorField{td, sd}...; order::OrderLabels=__fun_order_labels(Xs))::VectorField{td, sd} where {td, sd}

    # check length of Xs
    length(Xs) < 2 && throw(IncorrectArgument("Xs must have at least two elements"))

    # check length of order
    length(order) < 2 && throw(IncorrectArgument("order must have at least two elements"))
    
    # check if the elements of order are contained in the labels of Xs
    Xs_labels = [X.label for X ∈ Xs]
    for o ∈ order
        o ∉ Xs_labels && throw(IncorrectArgument("order must contain only labels of Xs"))
    end

    # check if the lables of Xs are unique
    length(Xs_labels) != length(unique(Xs_labels)) && throw(IncorrectArgument("the labels of Xs must be unique"))

    # 
    if length(order) == 2
        # get indices of order[1] and order[2] in Xs_labels
        i1 = findfirst(o -> o == order[1], Xs_labels)
        i2 = findfirst(o -> o == order[2], Xs_labels)
        # return Lie bracket
        return Lie(Xs[i1], Xs[i2])
    else
        # get indices of order[end] in Xs_labels
        iend = findfirst(o -> o == order[end], Xs_labels)
        # return Lie bracket
        return Lie(Lie(Xs..., order=order[1:end-1]), Xs[iend])
    end

end

#
function Lie_orders(Xs::VectorField{td, sd}...; orders::Orders=(__fun_order(Xs),))::Tuple{Vararg{VectorField{td, sd}}} where {td, sd}

    # check length of Xs
    length(Xs) < 2 && throw(IncorrectArgument("Xs must have at least two elements"))

    # 
    Ls = Vector{VectorField{td, sd}}()
    for order ∈ orders
        push!(Ls, Lie(Xs..., order=order))
    end
    return Tuple(Ls)
        
end

function Lie_orders_labels(Xs::VectorField{td, sd}...; orders::OrdersLabels=(__fun_order_labels(Xs),))::Tuple{Vararg{VectorField{td, sd}}} where {td, sd}

    # check length of Xs
    length(Xs) < 2 && throw(IncorrectArgument("Xs must have at least two elements"))

    # 
    Ls = Vector{VectorField{td, sd}}()
    for order ∈ orders
        push!(Ls, Lie(Xs..., order=order))
    end
    return Tuple(Ls)
        
end

#
function Lie(Xs::VectorField{td, sd}...; 
    orders::Union{Nothing, Orders, OrdersLabels}=nothing, 
    order::Union{Nothing, Order, OrderLabels}=nothing) where {td, sd}
    
    # check if only one of orders and order is specified
    (!isnothing(order) && !isnothing(orders)) && throw(IncorrectArgument("only one of orders and order can be specified"))

    if orders ≠ nothing # orders is specified
        if orders isa OrdersLabels # orders is a tuple of order labels
            return Lie_orders_labels(Xs..., orders=orders)
        else # orders is a tuple of orders
            return Lie_orders(Xs..., orders=orders)
        end
    elseif order ≠ nothing # order is specified
        if order isa OrderLabels # order is a tuple of order labels
            return Lie_order_labels(Xs..., order=order)
        else # order is a tuple of orders
            return Lie_order(Xs..., order=order)
        end
    else
        return Lie_order(Xs...)
    end
end
