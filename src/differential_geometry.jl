# ---------------------------------------------------------------------------
# Lift

# from VectorField
function Lift(X::VectorField)::HamiltonianLift
    return HamiltonianLift(X)
end

# from Function with keyword arguments
function Lift(X::Function; autonomous::Bool=true, variable::Bool=false)::HamiltonianLift
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    variable_dependence = variable ? NonFixed : Fixed
    return Lift(VectorField(X, time_dependence, variable_dependence))
end

# from Function with positional arguments
function Lift(X::Function, dependences::DataType...)::HamiltonianLift
    __check_dependencies(dependences)
    variable_dependence = NonFixed ∈ dependences ? NonFixed : Fixed
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    return Lift(VectorField(X, time_dependence, variable_dependence))
end

# ---------------------------------------------------------------------------
# Lie derivative of a scalar function along a vector field: L_X(f) = X⋅f

# (postulat)
# (X⋅f)(x)    = f'(x)⋅X(x)
# (X⋅f)(t, x) = ∂ₓf(t, x)⋅X(t, x)
function ⋅(X::VectorField{Autonomous, <: VariableDependence}, f::Function)::Function
    return (x, args...) -> ctgradient(y -> f(y, args...), x)'*X(x, args...)
end

function ⋅(X::VectorField{NonAutonomous, <: VariableDependence}, f::Function)::Function
    return (t, x, args...) -> ctgradient(y -> f(t, y, args...), x)'*X(t, x, args...)
end

Lie(X::VectorField, f::Function)::Function = X⋅f

function Lie(X::Function, f::Function; autonomous::Bool=true, variable::Bool=false)::Function
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    variable_dependence = variable ? NonFixed : Fixed
    return Lie(VectorField(X, time_dependence, variable_dependence), f)
end

function Lie(X::Function, f::Function, dependences::DataType...)::Function
    __check_dependencies(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependences ? NonFixed : Fixed
    return Lie(VectorField(X, time_dependence, variable_dependence), f)
end

# ---------------------------------------------------------------------------
# partial derivative wrt time
∂ₜ(f) = (t, args...) -> ctgradient(y -> f(y, args...), t)

# ---------------------------------------------------------------------------
# "Directional derivative" of a vector field: internal and only used to compute
# efficiently the Lie bracket of two vector fields

function ⅋(X::VectorField{Autonomous, V}, Y::VectorField{Autonomous, V})::VectorField{Autonomous, V} where {V<:VariableDependence}
    return VectorField((x, args...) -> x isa ctNumber ? 
        ctgradient(y -> Y(y, args...), x) * X(x, args...) : 
        ctjacobian(y -> Y(y, args...), x) * X(x, args...),
        Autonomous, V)
end

function ⅋(X::VectorField{NonAutonomous, V}, Y::VectorField{NonAutonomous, V})::VectorField{NonAutonomous, V} where {V<:VariableDependence}
    return VectorField((t, x, args...) -> x isa ctNumber ? 
        ctgradient(y -> Y(t, y, args...), x) * X(t, x, args...) : 
        ctjacobian(y -> Y(t, y, args...), x) * X(t, x, args...),
        NonAutonomous, V)
end

# ---------------------------------------------------------------------------
# Lie bracket of two vector fields: [X, Y] = Lie(X, Y)
# [X, Y]⋅f = (X∘Y - Y∘X)⋅f = (X⅋Y - Y⅋X)⋅f

function Lie(X::VectorField{Autonomous, V}, Y::VectorField{Autonomous, V})::VectorField{Autonomous, V} where {V<:VariableDependence}
    return VectorField((x, args...) -> (X⅋Y)(x, args...)-(Y⅋X)(x, args...), Autonomous, V)
end

function Lie(X::VectorField{NonAutonomous, V}, Y::VectorField{NonAutonomous, V})::VectorField{NonAutonomous, V} where {V<:VariableDependence}
    return VectorField((t, x, args...) -> (X⅋Y)(t, x, args...)-(Y⅋X)(t, x, args...), NonAutonomous, V)
end

# ---------------------------------------------------------------------------
# Poisson bracket of two Hamiltonian functions: {f, g} = Poisson(f, g)
# f(z) = p⋅X(x), g(z) = p⋅Y(x), z = (x, p) => {f,g}(z) = p⋅[X,Y](x) 
# {f, g}(z) = g'(z)⋅F(z), where F is the Hamiltonian vector field of f
# actually, z = (x, p)
function Poisson(f::AbstractHamiltonian{Autonomous, V}, g::AbstractHamiltonian{Autonomous, V})::Hamiltonian{Autonomous, V} where {V <: VariableDependence}
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

# f(t, z) = p⋅X(x), g(t, z) = p⋅Y(x), z = (x, p) => {f, g}(t, z) = p⋅[X,Y](t, x) 
# {f, g}(t, z) = ∂₂g(t, z)⋅F(t, z)
# actually, z = (x, p)
function Poisson(f::AbstractHamiltonian{NonAutonomous, V}, g::AbstractHamiltonian{NonAutonomous, V})::Hamiltonian{NonAutonomous, V} where {V <: VariableDependence}
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

function Poisson(f::HamiltonianLift{T, V}, g::HamiltonianLift{T, V})::HamiltonianLift{T, V} where {T <: TimeDependence, V <: VariableDependence}
    return HamiltonianLift(Lie(f.X, g.X))
end

function Poisson(f::Function, g::Function; autonomous::Bool=true, variable::Bool=false)::Hamiltonian
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    variable_dependence = variable ? NonFixed : Fixed
    return Poisson(Hamiltonian(f, time_dependence, variable_dependence), Hamiltonian(g, time_dependence, variable_dependence))
end

function Poisson(f::Function, g::AbstractHamiltonian{T, V})::Hamiltonian where {T<:TimeDependence, V<:VariableDependence}
    return Poisson(Hamiltonian(f, T, V), g)
end

function Poisson(f::AbstractHamiltonian{T, V}, g::Function)::Hamiltonian where {T<:TimeDependence, V<:VariableDependence}
    return Poisson(f, Hamiltonian(g, T, V))
end

# ---------------------------------------------------------------------------
# Macros

# @Lie [X, Y]
macro Lie(expr::Expr)
    @assert hasproperty(expr, :head)
    @assert expr.head == :vect
    @assert size(expr.args, 1) == 2
    return esc(postwalk( x -> @capture(x, [a_, b_]) ? :(Lie($a, $b)) : x, expr))
end

# @Poisson {X, Y}
macro Poisson(expr::Expr)
    @assert hasproperty(expr, :head)
    @assert expr.head == :braces
    @assert size(expr.args, 1) == 2
    return esc(postwalk( x -> @capture(x, {a_, b_}) ? :(Poisson($a, $b)) : x, expr))
end