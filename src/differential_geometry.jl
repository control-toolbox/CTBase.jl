
# ---------------------------------------------------------------------------
# HamiltonianLift
struct HamiltonianLift{time_dependence,variable_dependence}  <: AbstractHamiltonian{time_dependence,variable_dependence}
    X::VectorField
    function HamiltonianLift(X::VectorField{time_dependence, variable_dependence}) where {time_dependence, variable_dependence}
        new{time_dependence, variable_dependence}(X)
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
    return (t, x) -> ctgradient(y -> f(t, y), x)'*X(t, x) # + ctgradient(s -> f(s, x), t) ??
end
# (X⋅f)(x) = f'(x)⋅X(x)
# (X⋅f)(t, x) = ∂₁f(t, x) + ∂₂f(t, x)⋅X(t, x)
# (postulat)
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
# function ⅋(X::VectorField{Autonomous, V}, Y::VectorField{Autonomous, V})::VectorField{Autonomous, V} where V
#     return VectorField(x -> ctgradient(Y, x)*X(x), 
#         Autonomous, V)
# end
# function ⅋(X::VectorField{NonAutonomous, V}, Y::VectorField{NonAutonomous, V})::VectorField{NonAutonomous, V} where V
#     return VectorField((t, x) -> ctgradient(y -> Y(t, y), x)*X(t, x),
#         NonAutonomous, V)
# end
function ⅋(X::VectorField{Autonomous, V}, Y::VectorField{Autonomous, V})::VectorField{Autonomous, V} where {V}
    return VectorField((x, args...) -> x isa ctNumber ? ctgradient(y -> Y(y, args...), x)*X(x, args...) : ctjacobian(y -> Y(y, args...), x)*X(x, args...),
        Autonomous, V)
end
function ⅋(X::VectorField{NonAutonomous, V}, Y::VectorField{NonAutonomous, V})::VectorField{NonAutonomous, V} where {V}
    return VectorField((t, x, args...) -> x isa ctNumber ? ctgradient(y -> Y(t, y, args...), x)*X(t, x, args...) : ctjacobian(y -> Y(t, y, args...), x)*X(t, x, args...),
        NonAutonomous, V)
end
# function ⅋(X::VectorField{NonAutonomous, NonFixed}, Y::VectorField{NonAutonomous, NonFixed})::VectorField{NonAutonomous, NonFixed}
#     return VectorField((t, x, v) -> x isa ctNumber ? ctgradient(y -> Y(t, y, v), x)*X(t, x, v) : ctjacobian(y -> Y(t, y, v), x)*X(t, x, v),
#         NonAutonomous, NonFixed)
# end
# ---------------------------------------------------------------------------
# Lie bracket of two vector fields: [X, Y] = Lie(X, Y)= ad(X, Y)
## [X, Y]⋅f = (X∘Y - Y∘X)⋅f
# ⅋ = ? => (X⅋Y - Y⅋X)⋅f = (X∘Y - Y∘X)⋅f
function Lie(X::VectorField{Autonomous, V}, Y::VectorField{Autonomous, V})::VectorField{Autonomous, V} where {V}
    return VectorField(x -> (X⅋Y)(x)-(Y⅋X)(x), Autonomous, V)
end
function Lie(X::VectorField{NonAutonomous, V}, Y::VectorField{NonAutonomous, V})::VectorField{NonAutonomous, V} where {V}
    return VectorField((t, x) -> (X⅋Y)(t, x)-(Y⅋X)(t, x), NonAutonomous, V)
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
# f(z) = p⋅X(x), g(z) = p⋅Y(x), z = (x, p) => {f,g}(z) = p⋅[X,Y](x) 
# {f,g}(z) = g'(z)⋅f⃗(z)
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
# f(t, z) = p⋅X(x), g(t, z) = p⋅Y(x), z = (x, p) => {f,g}(t, z) = p⋅[X,Y](t, x) 
# {f,g}(t, z) = ∂₂g(t, z)⋅f⃗(t, z) + ∂₁g(t, z) ?? => {f,g}(t, z) = p⋅[X,Y](t, x) when f,g are Hamiltonian lifts
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