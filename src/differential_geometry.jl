
# ---------------------------------------------------------------------------
# HamiltonianLift

# State, Costate
function (H::HamiltonianLift{Autonomous, Fixed})(x::State, p::Costate)::ctNumber
    return p'*H.X(x)
end
function (H::HamiltonianLift{Autonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return p'*H.X(x)
end
function (H::HamiltonianLift{Autonomous, NonFixed})(x::State, p::Costate, v::Variable)::ctNumber
    return p'*H.X(x, v)
end
function (H::HamiltonianLift{Autonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return p'*H.X(x, v)
end
function (H::HamiltonianLift{NonAutonomous, Fixed})(t::Time, x::State, p::Costate)::ctNumber
    return p'*H.X(t, x)
end
function (H::HamiltonianLift{NonAutonomous, Fixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return p'*H.X(t, x)
end
function (H::HamiltonianLift{NonAutonomous, NonFixed})(t::Time, x::State, p::Costate, v::Variable)::ctNumber
    return p'*H.X(t, x, v)
end

# ---------------------------------------------------------------------------
# Lift

# single lift: from VectorField
function Lift(X::AbstractVectorField)::HamiltonianLift
    return HamiltonianLift(X)
end

# single lift: from Function
function Lift(X::Function; autonomous::Bool=true, variable::Bool=false)::HamiltonianLift
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    variable_dependence = variable ? NonFixed : Fixed
    return HamiltonianLift(VectorField(X, time_dependence, variable_dependence))
end
function Lift(X::Function, dependences::DataType...)::HamiltonianLift
    @__check(dependences)
    variable_dependence = NonFixed ∈ dependences ? NonFixed : Fixed
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    return HamiltonianLift(VectorField(X, time_dependence, variable_dependence))
end

# multiple lifts: from VectorField
function Lift(Xs::AbstractVectorField...)::Tuple{Vararg{HamiltonianLift}}
    return Tuple(Lift(X) for X ∈ Xs)
end

# multiple lifts: from Function
function Lift(Xs::Function...; autonomous::Bool=true, variable::Bool=false)::Tuple{Vararg{HamiltonianLift}}
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed
    return Tuple(Lift(X, time_dependence, variable_dependence) for X ∈ Xs)
end
function Lift(args::Union{Function,DataType}...)::Tuple{Vararg{HamiltonianLift}}
    #Xs::Function..., dependences::DataType...
    Xs = args[findall(x -> (typeof(x) <: Function),args)]
    dependences = args[findall(x -> (typeof(x) <: DataType),args)]
    @__check(dependences)
    variable_dependence = NonFixed ∈ dependences ? NonFixed : Fixed
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    return Tuple(Lift(X, time_dependence, variable_dependence) for X ∈ Xs)
end

# ---------------------------------------------------------------------------
# Directional derivative of a scalar function
function Der(X::AbstractVectorField{Autonomous, <: VariableDependence}, f::Function)::Function
   return (x, args...) -> ctgradient(y -> f(y, args...), x)'*X(x, args...)
end
function Der(X::AbstractVectorField{NonAutonomous, <: VariableDependence}, f::Function)::Function
    return (t, x, args...) -> ctgradient(y -> f(t, y, args...), x)'*X(t, x, args...) # + ctgradient(s -> f(s, x), t) ??
end
# (X⋅f)(x) = f'(x)⋅X(x)
# (X⋅f)(t, x) = ∂₁f(t, x) + ∂₂f(t, x)⋅X(t, x)
# (postulat)
function ⋅(X::AbstractVectorField, f::Function)::Function
    return Der(X, f)
end

# ---------------------------------------------------------------------------
# Lie derivative of a scalar function = directional derivative
function Lie(X::AbstractVectorField, f::Function)::Function
    return Der(X, f)
end

# ---------------------------------------------------------------------------
# "Directional derivative" of a vector field: internal and only used to compute
# efficiently the Lie bracket of two vector fields
function ⅋(X::AbstractVectorField{Autonomous, V}, Y::AbstractVectorField{Autonomous, V})::AbstractVectorField{Autonomous, V} where {V<:VariableDependence}
    return VectorField((x, args...) -> x isa ctNumber ? ctgradient(y -> Y(y, args...), x)*X(x, args...) : ctjacobian(y -> Y(y, args...), x)*X(x, args...),
        Autonomous, V)
end
function ⅋(X::AbstractVectorField{NonAutonomous, V}, Y::AbstractVectorField{NonAutonomous, V})::AbstractVectorField{NonAutonomous, V} where {V<:VariableDependence}
    return VectorField((t, x, args...) -> x isa ctNumber ? [ctgradient(s -> Y(s, x, args...), t); ctgradient(y -> Y(t, y, args...), x)]'*[1; X(t, x, args...)] : hcat(ctjacobian(s -> Y(s, x, args...), t), ctjacobian(y -> Y(t, y, args...), x))*[1; X(t, x, args...)],
        NonAutonomous, V)
end

# ---------------------------------------------------------------------------
# Lie bracket of two vector fields: [X, Y] = Lie(X, Y)= ad(X, Y)
## [X, Y]⋅f = (X∘Y - Y∘X)⋅f
# ⅋ = ? => (X⅋Y - Y⅋X)⋅f = (X∘Y - Y∘X)⋅f
function Lie(X::AbstractVectorField{Autonomous, V}, Y::AbstractVectorField{Autonomous, V})::AbstractVectorField{Autonomous, V} where {V<:VariableDependence}
    return VectorField((x, args...) -> (X⅋Y)(x, args...)-(Y⅋X)(x, args...), Autonomous, V)
end
function Lie(X::AbstractVectorField{NonAutonomous, V}, Y::AbstractVectorField{NonAutonomous, V})::AbstractVectorField{NonAutonomous, V} where {V<:VariableDependence}
    return VectorField((t, x, args...) -> (X⅋Y)(t, x, args...)-(Y⅋X)(t, x, args...), NonAutonomous, V)
end
function ad(X::AbstractVectorField, Y::AbstractVectorField)::AbstractVectorField
    return Lie(X, Y)
end
function Lie(X::Function, Y::Function; autonomous::Bool=true, variable::Bool=false)::AbstractVectorField
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    variable_dependence = variable ? NonFixed : Fixed
    return Lie(VectorField(X, time_dependence, variable_dependence), VectorField(Y, time_dependence, variable_dependence))
end
function Lie(X::Function, Y::Function, dependences::DataType...)::AbstractVectorField
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependences ? NonFixed : Fixed
    return Lie(VectorField(X, time_dependence, variable_dependence), VectorField(Y, time_dependence, variable_dependence))
end
function ad(X::Function, Y::Function; autonomous::Bool=true, variable::Bool=false)::AbstractVectorField
    time_dependence = autonomous ? Autonomous : NonAutonomous
    variable_dependence = variable ? NonFixed : Fixed 
    return Lie(X, Y, time_dependence, variable_dependence)
end
function ad(X::Function, Y::Function, dependences::DataType...)::AbstractVectorField
    @__check(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependences ? NonFixed : Fixed
    return Lie(X, Y, time_dependence, variable_dependence)
end
# f(z) = p⋅X(x), g(z) = p⋅Y(x), z = (x, p) => {f,g}(z) = p⋅[X,Y](x) 
# {f,g}(z) = g'(z)⋅f⃗(z)
function Poisson(f::AbstractHamiltonian{Autonomous, V}, g::AbstractHamiltonian{Autonomous, V})::AbstractHamiltonian{Autonomous, V} where {V <: VariableDependence}
    function fg(x, p, args...)
        n = size(x, 1)
        ff,gg = @match n begin
            1 => (z -> f(z[1], z[2], args...), z -> g(z[1], z[2], args...))
            _ => (z -> f(z[1:n], z[n+1:2n], args...), z -> g(z[1:n], z[n+1:2n], args...))
        end
        df = ctgradient(ff, [ x ; p ])
        dg = ctgradient(gg, [ x ; p ])
        return df[1:n]'*dg[n+1:2n] - df[n+1:2n]'*dg[1:n]
    end
    return Hamiltonian(fg, Autonomous, V)
end
# f(t, z) = p⋅X(x), g(t, z) = p⋅Y(x), z = (x, p) => {f,g}(t, z) = p⋅[X,Y](t, x) 
# {f,g}(t, z) = ∂₂g(t, z)⋅f⃗(t, z) + ∂₁g(t, z) ?? => {f,g}(t, z) = p⋅[X,Y](t, x) when f,g are Hamiltonian lifts
function Poisson(f::AbstractHamiltonian{NonAutonomous, V}, g::AbstractHamiltonian{NonAutonomous, V})::AbstractHamiltonian{NonAutonomous, V} where {V <: VariableDependence}
    function fg(t, x, p, args...)
        n = size(x, 1)
        ff,gg = @match n begin
            1 => (z -> f(t, z[1], z[2], args...), z -> g(t, z[1], z[2], args...))
            _ => (z -> f(t, z[1:n], z[n+1:2n], args...), z -> g(t, z[1:n], z[n+1:2n], args...))
        end
        df = ctgradient(ff, [ x ; p ])
        dg = ctgradient(gg, [ x ; p ])
        return df[1:n]'*dg[n+1:2n] - df[n+1:2n]'*dg[1:n]
    end
    return Hamiltonian(fg, NonAutonomous, V)
end
# function Poisson(f::AbstractHamiltonian{NonAutonomous, V}, g::AbstractHamiltonian{NonAutonomous, V})::AbstractHamiltonian{NonAutonomous, V} where {V <: VariableDependence}
#     function df(t,z,args...)
#         n = size(z,1)/2
#         if(n==1)
#             return([ctgradient(p -> f(t, z[1], p, args...),z[2]),ctgradient(x -> f(t, x, z[2], args...),z[1])])
#         else
#             return([ctgradient(p -> f(t, z[1:n], p, args...),z[n+1:2n]),ctgradient(x -> f(t, x, z[n+1,2n], args...),z[1:n])])
#         end
#     end
#     F =  HamiltonianVectorField(df, NonAutonomous, V)
#     fg  = Lie(F,g.f)
#     return Hamiltonian(fg, NonAutonomous, V)
# end


# ---------------------------------------------------------------------------
# Macros

# @Lie [X, Y]
macro Lie(expr::Expr)
    @assert hasproperty(expr, :head)
    @assert expr.head == :vect
    @assert size(expr.args,1) == 2
    return esc(postwalk( x -> @capture(x, [a_, b_]) ? :(Lie($a, $b)) : x, expr))
end

# @Poisson {X, Y}
macro Poisson(expr::Expr)
    @assert hasproperty(expr, :head)
    @assert expr.head == :braces
    @assert size(expr.args,1) == 2
    return esc(postwalk( x -> @capture(x, {a_, b_}) ? :(Poisson($a, $b)) : x, expr))
end