# ---------------------------------------------------------------------------
# abstract type AbstractHamiltonian end

# ---------------------------------------------------------------------------
# HamiltonianLift
struct HamiltonianLift{time_dependence}  <: AbstractHamiltonian{time_dependence,Any}
    X::VectorField
    function HamiltonianLift(X::VectorField{time_dependence, state_dimension}) where {time_dependence, state_dimension}
        new{time_dependence}(X)
    end
end

# classical calls
#
# ctNumber
function (H::HamiltonianLift{NonAutonomous})(t::Time, x::ctNumber, p::ctNumber, args...; kwargs...)::ctNumber
    return p'*H.X(t, x, args...; kwargs...)
end
function (H::HamiltonianLift{Autonomous})(x::ctNumber, p::ctNumber, args...; kwargs...)::ctNumber
    return p'*H.X(x, args...; kwargs...)
end
# State, Costate
function (H::HamiltonianLift{NonAutonomous})(t::Time, x::State, p::Costate, args...; kwargs...)::ctNumber
    return p'*H.X(t, x, args...; kwargs...)
end
function (H::HamiltonianLift{Autonomous})(x::State, p::Costate, args...; kwargs...)::ctNumber
    return p'*H.X(x, args...; kwargs...)
end

# ---------------------------------------------------------------------------
# Lift

# single lift: from VectorField
function Lift(X::VectorField)::HamiltonianLift
    return HamiltonianLift(X)
end

# single lift: from Function
function Lift(X::Function; autonomous::Bool=true)::HamiltonianLift
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    return HamiltonianLift(VectorField(X, time_dependence))
end
function Lift(X::Function, time_dependence::DataType...)::HamiltonianLift
    @__check(time_dependence)
    time_dependence = NonAutonomous ∈ time_dependence ? NonAutonomous : Autonomous
    return HamiltonianLift(VectorField(X, time_dependence))
end

# multiple lifts: from VectorField
function Lift(Xs::VectorField...)::Tuple{Vararg{HamiltonianLift}}
    return Tuple(Lift(X) for X ∈ Xs)
end

# multiple lifts: from Function
function Lift(Xs::Function...; autonomous::Bool=true)::Tuple{Vararg{HamiltonianLift}}
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    return Tuple(Lift(X, time_dependence) for X ∈ Xs)
end
function Lift(args::Union{Function,DataType}...)::Tuple{Vararg{HamiltonianLift}}
    #Xs::Function..., dependences::DataType...
    time_dependence = args[findall(x -> (typeof(x) <: DataType),args)]
    Xs = args[findall(x -> (typeof(x) <: Function),args)]
    @__check(time_dependence)
    return Tuple(Lift(X, time_dependence) for X ∈ Xs)
end

# ---------------------------------------------------------------------------
# Directional derivative of a scalar function
function Der(X::VectorField{Autonomous, <: VariableDependence}, f::Function)::Function
   return x -> ctgradient(f, x)'*X(x)
end
function Der(X::VectorField{NonAutonomous, <: VariableDependence}, f::Function)::Function
    return (t, x) -> ctgradient(y -> f(t, y), x)'*X(t, x)
end
function ⋅(X::VectorField, f::Function)::Function
    return Der(X, f)
end

# ---------------------------------------------------------------------------
# Lie derivative of a scalar function = directional derivative
function Lie(X::VectorField, f::Function)::Function
    return Der(X, f)
end

# ---------------------------------------------------------------------------
# "Directional derivative" of a vector field: internal and only used to compute
# efficiently the Lie bracket of two vector fields
function ⅋(X::VectorField{Autonomous, T}, Y::VectorField{Autonomous, T})::VectorField{Autonomous, T} where T
    return VectorField(x -> ctgradient(Y, x)*X(x), 
        Autonomous, T)
end
function ⅋(X::VectorField{NonAutonomous, 1}, Y::VectorField{NonAutonomous, 1})::VectorField{NonAutonomous, 1}
    return VectorField((t, x) -> ctgradient(y -> Y(t, y), x)*X(t, x),
        NonAutonomous, T)
end
function ⅋(X::VectorField{Autonomous, T}, Y::VectorField{Autonomous, T})::VectorField{Autonomous, T} where {T}
    return VectorField(x -> x isa ctNumber ? ctgradient(Y, x)*X(x) : ctjacobian(Y, x)*X(x),
        Autonomous, T)
end
function ⅋(X::VectorField{NonAutonomous, T}, Y::VectorField{NonAutonomous, T})::VectorField{NonAutonomous, T} where {T}
    return VectorField((t, x) -> x isa ctNumber ? ctgradient(y -> Y(t, y), x)*X(t, x) : ctjacobian(y -> Y(t, y), x)*X(t, x),
        NonAutonomous, T)
end

# ---------------------------------------------------------------------------
# Lie bracket of two vector fields: [X, Y] = Lie(X, Y)= ad(X, Y)
function Lie(X::VectorField{Autonomous, T}, Y::VectorField{Autonomous, T})::VectorField{Autonomous, T} where {T}
    return VectorField(x -> (X⅋Y)(x)-(Y⅋X)(x), Autonomous, T)
end
function Lie(X::VectorField{NonAutonomous, T}, Y::VectorField{NonAutonomous, T})::VectorField{NonAutonomous, T} where {T}
    return VectorField((t, x) -> (X⅋Y)(t, x)-(Y⅋X)(t, x), NonAutonomous, T)
end
function ad(X::VectorField{T,V}, Y::VectorField{T,V})::VectorField{T,V} where {T,V}
    return Lie(X, Y)
end
function Lie(X::Function, Y::Function; autonomous::Bool=true)::VectorField
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    return Lie(VectorField(X, time_dependence), VectorField(Y, time_dependence))
end
function Lie(X::Function, Y::Function, time_dependence::DataType...)::VectorField
    @__check(time_dependence)
    time_dependence = NonAutonomous ∈ time_dependence ? NonAutonomous : Autonomous
    return Lie(VectorField(X, time_dependence), VectorField(Y, time_dependence))
end
function ad(X::Function, Y::Function; autonomous::Bool=true)::VectorField
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    return Lie(X, Y, time_dependence)
end
function ad(X::Function, Y::Function, time_dependence::DataType...)::VectorField
    @__check(time_dependence)
    time_dependence = NonAutonomous ∈ time_dependence ? NonAutonomous : Autonomous
    return Lie(X, Y, time_dependence)
end
function Poisson(f::AbstractHamiltonian{Autonomous, T}, g::AbstractHamiltonian{Autonomous, T})::AbstractHamiltonian{Autonomous, T} where {T <: VariableDependence}
    function fg(x, p)
        n = size(x, 1)
        ff,gg = @match n begin
            1 => (z -> f(z[1], z[2]), z -> g(z[1], z[2]))
            _ => (z -> f(z[1:n], z[n+1:2n]), z -> g(z[1:n], z[n+1:2n]))
        end
        df = ctgradient(ff, [ x ; p ])
        dg = ctgradient(gg, [ x ; p ])
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n]
    end
    return Hamiltonian(fg, Autonomous, T)
end
function Poisson(f::AbstractHamiltonian{NonAutonomous, T}, g::AbstractHamiltonian{NonAutonomous, T})::AbstractHamiltonian{NonAutonomous, T} where {T <: VariableDependence}
    function fg(t, x, p)
        n = size(x, 1)
        ff,gg = @match n begin
            1 => (z -> f(t, z[1], z[2]), z -> g(t, z[1], z[2]))
            _ => (z -> f(t, z[1:n], z[n+1:2n]), z -> g(t, z[1:n], z[n+1:2n]))
        end
        df = ctgradient(ff, [ x ; p ])
        dg = ctgradient(gg, [ x ; p ])
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n]
    end
    return Hamiltonian(fg, NonAutonomous, T)
end
function Poisson(f::AbstractHamiltonian, g::AbstractHamiltonian)::AbstractHamiltonian
    function fg(x, p)
        n = size(x, 1)
        ff,gg = @match n begin
            1 => (z -> f(z[1], z[2]), z -> g(z[1], z[2]))
            _ => (z -> f(z[1:n], z[n+1:2n]), z -> g(z[1:n], z[n+1:2n]))
        end
        df = ctgradient(ff, [ x ; p ])
        dg = ctgradient(gg, [ x ; p ])
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n]
    end
    return Hamiltonian(fg)
end

# ---------------------------------------------------------------------------
# Macros

# @Lie [X, Y]
macro Lie(expr::Expr)
    @assert hasproperty(expr, :head)
    @assert expr.head == :vect
    @assert length(expr.args) == 2
    return esc(postwalk( x -> @capture(x, [a_, b_]) ? :(Lie($a, $b)) : x, expr))
end

# @Poisson {X, Y}
macro Poisson(expr::Expr)
    @assert hasproperty(expr, :head)
    @assert expr.head == :braces
    @assert length(expr.args) == 2
    return esc(postwalk( x -> @capture(x, {a_, b_}) ? :(Poisson($a, $b)) : x, expr))
end