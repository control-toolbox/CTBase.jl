using Test
using CTBase

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
    return VectorField(x -> (ctjacobian(Y, x)*X(x)-ctjacobian(X, x)*Y(x)), time_dependence=:autonomous, state_dimension=sd)
end
function Lie(X::VectorField{:nonautonomous, sd}, Y::VectorField{:nonautonomous, sd})::VectorField{:nonautonomous, sd} where {sd}
    return VectorField((t, x) -> (ctjacobian(y -> Y(t, y), x)*X(t, x)-ctjacobian(y -> X(t, y), x)*Y(t, x)), time_dependence=:nonautonomous, state_dimension=sd)
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

# ---------------------------------------------------------------------------
function test_differential_geometry()

    @testset "Lie derivative" begin
    
        # autonomous
        X = VectorField(x -> [x[2], -x[1]])
        f = x -> x[1]^2 + x[2]^2
        Test.@test Lie(X, f)([1, 2]) == 0
        Test.@test (X⋅f)([1, 2]) == Lie(X, f)([1, 2])
    
        # nonautonomous
        X = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
        f = (t, x) -> t + x[1]^2 + x[2]^2
        Test.@test Lie(X, f)(1, [1, 2]) == 2
        Test.@test (X⋅f)(1, [1, 2]) == Lie(X, f)(1, [1, 2])
    
    end

    @testset "Lifts" begin
        
        @testset "from VectorFields" begin
    
            # autonomous case
            X = VectorField(x -> 2x)
            H = Lift(X)
            Test.@test H(1, 1) == 2
            Test.@test H([1, 2], [3, 4]) == 22
    
            # multiple VectorFields
            X1 = VectorField(x -> 2x)
            X2 = VectorField(x -> 3x)
            H1, H2 = Lift(X1, X2)
            Test.@test H1(1, 1) == 2
            Test.@test H1([1, 2], [3, 4]) == 22
            Test.@test H2(1, 1) == 3
            Test.@test H2([1, 2], [3, 4]) == 33
    
            # nonautonomous case
            X = VectorField((t, x) -> 2x, time_dependence=:nonautonomous)
            H = Lift(X)
            Test.@test H(1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4]) == 22
    
            # multiple VectorFields
            X1 = VectorField((t, x) -> 2x, time_dependence=:nonautonomous)
            X2 = VectorField((t, x) -> 3x, time_dependence=:nonautonomous)
            H1, H2 = Lift(X1, X2)
            Test.@test H1(1, 1, 1) == 2
            Test.@test H1(1, [1, 2], [3, 4]) == 22
            Test.@test H2(1, 1, 1) == 3
            Test.@test H2(1, [1, 2], [3, 4]) == 33
    
        end
        
        @testset "from Function" begin
    
            # autonomous case
            X = x -> 2x
            H = Lift(X)
            Test.@test H(1, 1) == 2
            Test.@test H([1, 2], [3, 4]) == 22
    
            # multiple Functions
            X1 = x -> 2x
            X2 = x -> 3x
            H1, H2 = Lift(X1, X2)
            Test.@test H1(1, 1) == 2
            Test.@test H1([1, 2], [3, 4]) == 22
            Test.@test H2(1, 1) == 3
            Test.@test H2([1, 2], [3, 4]) == 33
    
            # nonautonomous case
            X = (t, x) -> 2x
            H = Lift(X, time_dependence=:nonautonomous)
            Test.@test H(1, 1, 1) == 2
            Test.@test H(1, [1, 2], [3, 4]) == 22
    
            # multiple Functions
            X1 = (t, x) -> 2x
            X2 = (t, x) -> 3x
            H1, H2 = Lift(X1, X2, time_dependence=:nonautonomous)
            Test.@test H1(1, 1, 1) == 2
            Test.@test H1(1, [1, 2], [3, 4]) == 22
            Test.@test H2(1, 1, 1) == 3
            Test.@test H2(1, [1, 2], [3, 4]) == 33
    
        end
    
    end # tests for Lift

    @testset "Lie bracket - order 1" begin
        
        @testset "autonomous case" begin
            X = VectorField(x -> [x[2], -x[1]])
            Y = VectorField(x -> [x[2], -x[1]])
            Test.@test Lie(X, Y)([1, 2]) == [0, 0]
            Test.@test (X⋅Y)([1, 2]) == Lie(X, Y)([1, 2])
        end

        @testset "nonautonomous case" begin
            X = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
            Y = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
            Test.@test Lie(X, Y)(1, [1, 2]) == [0, 0]
            Test.@test (X⋅Y)(1, [1, 2]) == Lie(X, Y)(1, [1, 2])
        end

        @testset "mri example" begin
            Γ = 2
            γ = 1
            δ = γ-Γ
            F0 = VectorField(x -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])])
            F1 = VectorField(x -> [0, -x[3], x[2]])
            F2 = VectorField(x -> [x[3], 0, -x[1]])
            F01 = Lie(F0, F1)
            F02 = Lie(F0, F2)
            F12 = Lie(F1, F2)
            x = [1, 2, 3]
            Test.@test F01(x) ≈ -[0, γ-δ*x[3], -δ*x[2]] atol=1e-6
            Test.@test F02(x) ≈ -[-γ+δ*x[3], 0, δ*x[1]] atol=1e-6
            Test.@test F12(x) ≈ -[-x[2], x[1], 0] atol=1e-6
        end

    end # tests for Lie bracket - order 1

    @testset "multiple Lie brackets of any order" begin

        x = [1, 2, 3]
        Γ = 2
        γ = 1
        δ = γ-Γ
        F0 = VectorField(x -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])])
        F1 = VectorField(x -> [0, -x[3], x[2]])
        F2 = VectorField(x -> [x[3], 0, -x[1]])

        # length 2
        F01_ = Lie(F0, F1)
        F02_ = Lie(F0, F2)
        F12_ = Lie(F1, F2)
        F01 = Lie(F0, F1, order=(1,2))
        F02 = Lie(F0, F2, order=(1,2))
        F12 = Lie(F1, F2, order=(1,2))
        Test.@test F01(x) ≈ F01_(x) atol=1e-6
        Test.@test F02(x) ≈ F02_(x) atol=1e-6
        Test.@test F12(x) ≈ F12_(x) atol=1e-6
        
        # length 3
        F120_ = Lie(F12, F0, order=(1,2))
        F121_ = Lie(F12, F1, order=(1,2))
        F122_ = Lie(F12, F2, order=(1,2))
        F011_ = Lie(F01, F1, order=(1,2))
        F012_ = Lie(F01, F2, order=(1,2))
        F022_ = Lie(F02, F2, order=(1,2))
        F010_ = Lie(F01, F0, order=(1,2))
        F020_ = Lie(F02, F0, order=(1,2))

        F120 = Lie(F0, F1, F2, order=(2,3,1))
        F121 = Lie(F1, F2, order=(1,2,1))
        F122 = Lie(F1, F2, order=(1,2,2))
        F011 = Lie(F0, F1, order=(1,2,2))
        F012 = Lie(F0, F1, F2, order=(1,2,3))
        F022 = Lie(F0, F2, order=(1,2,2))
        F010 = Lie(F0, F1, order=(1,2,1))
        F020 = Lie(F0, F2, order=(1,2,1))

        Test.@test F120(x) ≈ F120_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6
        Test.@test F011(x) ≈ F011_(x) atol=1e-6
        Test.@test F012(x) ≈ F012_(x) atol=1e-6
        Test.@test F022(x) ≈ F022_(x) atol=1e-6
        Test.@test F010(x) ≈ F010_(x) atol=1e-6
        Test.@test F020(x) ≈ F020_(x) atol=1e-6

        Test.@test F120_(x) ≈ [0, 0, 0] atol=1e-6
        Test.@test F121_(x) ≈ F2(x) atol=1e-6
        Test.@test F122_(x) ≈ -F1(x) atol=1e-6
        Test.@test F011_(x) ≈ [0, -2*δ*x[2], -γ+2*δ*x[3]] atol=1e-6
        Test.@test F012_(x) ≈ [δ*x[2], δ*x[1], 0] atol=1e-6
        Test.@test F022_(x) ≈ [-2*δ*x[1], 0, 2*δ*x[3]-γ] atol=1e-6
        Test.@test F010_(x) ≈ [0, -γ*(γ-2*Γ)+δ^2*x[3], -δ^2*x[2]] atol=1e-6
        Test.@test F020_(x) ≈ [γ*(γ-2*Γ)-δ^2*x[3], 0, δ^2*x[1]] atol=1e-6

        # length 3 with cdot
        F120 = ((F1 ⋅ F2) ⋅ F0)
        Test.@test F120(x) ≈ F120_(x) atol=1e-6

        # length 3 with cdot and no parenthesis
        F120 = F1 ⋅ F2 ⋅ F0
        Test.@test F120(x) ≈ F120_(x) atol=1e-6

        # multiple Lie brackets of any length
        F01, F02, F12 = Lie(F0, F1, F2, orders=((1,2), (1, 3), (2, 3)))
        Test.@test F01(x) ≈ F01_(x) atol=1e-6
        Test.@test F02(x) ≈ F02_(x) atol=1e-6
        Test.@test F12(x) ≈ F12_(x) atol=1e-6

        F12, F121, F122 = Lie(F1, F2, orders=((1,2), (1,2,1), (1, 2, 2)))
        Test.@test F12(x) ≈ F12_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6

    end

    @testset "multiple Lie brackets of any order - with labels" begin
        
        x = [1, 2, 3]
        Γ = 2
        γ = 1
        δ = γ-Γ
        F0 = VectorField(x -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])], label=:F0)
        F1 = VectorField(x -> [0, -x[3], x[2]], label=:F1)
        F2 = VectorField(x -> [x[3], 0, -x[1]], label=:F2)

        # length 2
        F01_ = Lie(F0, F1)
        F02_ = Lie(F0, F2)
        F12_ = Lie(F1, F2)
        F01 = Lie(F0, F1, order=(:F0, :F1))
        F02 = Lie(F0, F2, order=(:F0, :F2))
        F12 = Lie(F1, F2, order=(:F1, :F2))
        Test.@test F01(x) ≈ F01_(x) atol=1e-6
        Test.@test F02(x) ≈ F02_(x) atol=1e-6
        Test.@test F12(x) ≈ F12_(x) atol=1e-6

        # length 3
        F120_ = Lie(F12, F0, order=(1,2))
        F121_ = Lie(F12, F1, order=(1,2))
        F122_ = Lie(F12, F2, order=(1,2))
        F120 = Lie(F0, F1, F2, order=(:F1, :F2, :F0))
        F121 = Lie(F1, F2, order=(:F1, :F2, :F1))
        F122 = Lie(F1, F2, order=(:F1, :F2, :F2))
        Test.@test F120(x) ≈ F120_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6

        # multiple Lie brackets of any length
        F01, F02, F12 = Lie(F0, F1, F2, orders=((:F0, :F1), (:F0, :F2), (:F1, :F2)))
        Test.@test F01(x) ≈ F01_(x) atol=1e-6
        Test.@test F02(x) ≈ F02_(x) atol=1e-6
        Test.@test F12(x) ≈ F12_(x) atol=1e-6

        F12, F121, F122 = Lie(F1, F2, orders=((:F1, :F2), (:F1, :F2, :F1), (:F1, :F2, :F2)))
        Test.@test F12(x) ≈ F12_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6

    end

end # test_differential_geometry

@testset "differential geometry" begin
    test_differential_geometry()
end