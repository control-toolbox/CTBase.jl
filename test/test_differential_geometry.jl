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
function (H::HamiltonianLift{:nonautonomous})(t::Time, x::Union{ctNumber, State}, 
    p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctNumber
    return p'*H.X(t, x, args...; kwargs...)
end
function (H::HamiltonianLift{:autonomous})(x::Union{ctNumber, State},
    p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctNumber
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
    if time_dependence ∉ [:autonomous, :nonautonomous]
        throw(InconsistentArgument("time_dependence must be either :autonomous or :nonautonomous"))
    end
    return HamiltonianLift(VectorField(X, time_dependence=time_dependence))
end
#
# multiple lifts
function Lift(Xs::VectorField...)::Tuple{Vararg{HamiltonianLift}}
    return Tuple(Lift(X) for X ∈ Xs)
end
function Lift(Xs::Function...; time_dependence::Symbol=CTBase.__fun_time_dependence())::Tuple{Vararg{HamiltonianLift}}
    if time_dependence ∉ [:autonomous, :nonautonomous]
        throw(InconsistentArgument("time_dependence must be either :autonomous or :nonautonomous"))
    end
    return Tuple(Lift(X, time_dependence=time_dependence) for X ∈ Xs)
end

# ---------------------------------------------------------------------------
# Lie derivative
function Lie(X::VectorField{:autonomous, state_dimension}, f::Function)::Function where {state_dimension}
    return x -> ctgradient(f, x)'*X(x)
end
function Lie(X::VectorField{:nonautonomous, state_dimension}, f::Function)::Function where {state_dimension}
    return (t, x) -> ctgradient(y -> f(t, y), x)'*X(t, x)
end

# ---------------------------------------------------------------------------
# Lie bracket of order 1
function Lie(X::VectorField{:autonomous, state_dimension}, Y::VectorField{:autonomous, state_dimension})::VectorField where {state_dimension}
    return VectorField(x -> (ctjacobian(Y, x)*X(x)-ctjacobian(X, x)*Y(x)), time_dependence=:autonomous)
end
function Lie(X::VectorField{:nonautonomous, state_dimension}, Y::VectorField{:nonautonomous, state_dimension})::VectorField where {state_dimension}
    return VectorField((t, x) -> (ctjacobian(y -> Y(t, y), x)*X(t, x)-ctjacobian(y -> X(t, y), x)*Y(t, x)), time_dependence=:nonautonomous)
end

# Multiple lie brackets of any order
struct Order 
    o::Vector{Integer}
    function Order(o1::Integer, o2::Integer, os::Integer...)
        new([o1, o2, os...])
    end
end
Base.isequal(o1::Order, o2::Order) = o1.o == o2.o
Base.:(==)(o1::Order, o2::Order) = isequal(o1, o2)
Base.length(o::Order) = length(o.o)

function Lie(X::VectorField{td, sd}, Y::VectorField{td, sd}, o::Order)::VectorField{td, sd} where {td, sd}
    if length(o) == 2
        o == Order(0, 0) && return Lie(X, X)
        o == Order(0, 1) && return Lie(X, Y)
        o == Order(1, 0) && return Lie(Y, X)
        o == Order(1, 1) && return Lie(Y, Y)
    else
        o.o[end] == 0 && return  Lie(Lie(X, Y, Order(o.o[1:end-1]...)), X)
        o.o[end] == 1 && return  Lie(Lie(X, Y, Order(o.o[1:end-1]...)), Y)
    end
end

function Lie(X::VectorField{td, sd}, Y::VectorField{td, sd}, os::Order...) where {td, sd}
    if length(os) == 0
        return Lie(X, Y)
    else
        Ls = Vector{VectorField{td, sd}}()
        for o ∈ os
            push!(Ls, Lie(X, Y, o))
        end
        return Tuple(Ls)
    end
end

# ---------------------------------------------------------------------------
function test_differential_geometry()

    @testset "Lie derivative" begin
    
        # autonomous
        X = VectorField(x -> [x[2], -x[1]])
        f = x -> x[1]^2 + x[2]^2
        Test.@test Lie(X, f)([1, 2]) == 0
    
        # nonautonomous
        X = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
        f = (t, x) -> t + x[1]^2 + x[2]^2
        Test.@test Lie(X, f)(1, [1, 2]) == 2
    
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
        end

        @testset "nonautonomous case" begin
            X = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
            Y = VectorField((t, x) -> [t + x[2], -x[1]], time_dependence=:nonautonomous)
            Test.@test Lie(X, Y)(1, [1, 2]) == [0, 0]
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

        Γ = 2
        γ = 1
        δ = γ-Γ
        F0 = VectorField(x -> [-Γ*x[1], -Γ*x[2], γ*(1-x[3])])
        F1 = VectorField(x -> [0, -x[3], x[2]])
        F2 = VectorField(x -> [x[3], 0, -x[1]])
        #
        x = [1, 2, 3]

        # length 2
        F01_ = Lie(F0, F1)
        F02_ = Lie(F0, F2)
        F12_ = Lie(F1, F2)
        F01 = Lie(F0, F1, Order(0, 1))
        F02 = Lie(F0, F2, Order(0, 1))
        F12 = Lie(F1, F2, Order(0, 1))
        Test.@test F01(x) ≈ F01_(x) atol=1e-6
        Test.@test F02(x) ≈ F02_(x) atol=1e-6
        Test.@test F12(x) ≈ F12_(x) atol=1e-6
        
        # length 3
        F120_ = Lie(F12, F0, Order(0, 1))
        F121_ = Lie(F12, F1, Order(0, 1))
        F122_ = Lie(F12, F2, Order(0, 1))
        F011_ = Lie(F01, F1, Order(0, 1))
        F012_ = Lie(F01, F2, Order(0, 1))
        F022_ = Lie(F02, F2, Order(0, 1))
        F010_ = Lie(F01, F0, Order(0, 1))
        F020_ = Lie(F02, F0, Order(0, 1))

        # F120 = ...
        F121 = Lie(F1, F2, Order(0, 1, 0))
        F122 = Lie(F1, F2, Order(0, 1, 1))
        F011 = Lie(F0, F1, Order(0, 1, 1))
        # F012 = ...
        F022 = Lie(F0, F2, Order(0, 1, 1))
        F010 = Lie(F0, F1, Order(0, 1, 0))
        F020 = Lie(F0, F2, Order(0, 1, 0))

        #Test.@test F120(x) ≈ F120_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6
        Test.@test F011(x) ≈ F011_(x) atol=1e-6
        #Test.@test F012(x) ≈ F012_(x) atol=1e-6
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

        # multiple Lie brackets of any order
        #F01, F02, F12 = Lie(F0, F1, F2, Order(0, 1), Order(0, 2), Order(1, 2))
        F12, F121, F122 = Lie(F1, F2, Order(0, 1), Order(0, 1, 0), Order(0, 1, 1))

        Test.@test F12(x) ≈ F12_(x) atol=1e-6
        Test.@test F121(x) ≈ F121_(x) atol=1e-6
        Test.@test F122(x) ≈ F122_(x) atol=1e-6

    end
 
end # test_differential_geometry

@testset "differential geometry" begin
    test_differential_geometry()
end