"""
$(TYPEDSIGNATURES)

Return the HamiltonianLift of a VectorField.

# Example
```jldoctest
julia> HL = Lift(VectorField(x -> [x[1]^2,x[2]^2], autonomous=true, variable=false))
julia> HL([1, 0], [0, 1])
0
julia> HL = Lift(VectorField((t, x, v) -> [t+x[1]^2,x[2]^2+v], autonomous=false, variable=true))
julia> HL(1, [1, 0], [0, 1], 1)
1
```
"""
function Lift(X::VectorField)::HamiltonianLift
    return HamiltonianLift(X)
end

"""
$(TYPEDSIGNATURES)

Return the Lift of the VectorField of a function.
Uses Booleans for time and variable dependences.

# Example
```jldoctest
julia> H = Lift(x -> 2x)
julia> H(1, 1)
2
julia> H = Lift((t, x, v) -> 2x + t - v, autonomous=false, variable=true)
julia> H(1, 1, 1, 1)
2
```
"""
function Lift(X::Function; autonomous::Bool=true, variable::Bool=false)::HamiltonianLift
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    variable_dependence = variable ? NonFixed : Fixed
    return Lift(VectorField(X, time_dependence, variable_dependence))
end

"""
$(TYPEDSIGNATURES)

Return the Lift of the VectorField of a function.
Uses DataType for time and variable dependences.

# Example
```jldoctest
julia> H = Lift(x -> 2x)
julia> H(1, 1)
2
julia> H = Lift((t, x, v) -> 2x + t - v, NonAutonomous, NonFixed)
julia> H(1, 1, 1, 1)
2
```
"""
function Lift(X::Function, dependences::DataType...)::HamiltonianLift
    __check_dependencies(dependences)
    variable_dependence = NonFixed ∈ dependences ? NonFixed : Fixed
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    return Lift(VectorField(X, time_dependence, variable_dependence))
end

# ---------------------------------------------------------------------------
# Lie derivative of a scalar function along a vector field or a function: L_X(f) = X⋅f

# (postulat)
# (X⋅f)(x)    = f'(x)⋅X(x)
# (X⋅f)(t, x) = ∂ₓf(t, x)⋅X(t, x)
# (g⋅f)(x) = f'(x)⋅G(x) with G the vector of g
"""
$(TYPEDSIGNATURES)

Lie derivative of a scalar function along a vector field or a function : L_X(f) = X⋅f

# Example
```jldoctest
julia> φ = x -> [x[2], -x[1]]
julia> X = VectorField(φ)
julia> f = x -> x[1]^2 + x[2]^2
julia> (X⋅f)([1, 2])
0
julia> (φ⋅f)([1, 2])
0
```
"""
function ⋅(X::VectorField{Autonomous, <: VariableDependence}, f::Function)::Function
    return (x, args...) -> ctgradient(y -> f(y, args...), x)'*X(x, args...)
end

function ⋅(X::VectorField{NonAutonomous, <: VariableDependence}, f::Function)::Function
    return (t, x, args...) -> ctgradient(y -> f(t, y, args...), x)'*X(t, x, args...)
end

function ⋅(X::Function, f::Function)::Function
    return ⋅(VectorField(X, Autonomous, Fixed), f)
end

"""
$(TYPEDSIGNATURES)

Lie derivative of a scalar function along a vector field.

# Example
```jldoctest

```
"""
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
"""
$(TYPEDSIGNATURES)

# Example
```jldoctest

```
"""
∂ₜ(f) = (t, args...) -> ctgradient(y -> f(y, args...), t)

# ---------------------------------------------------------------------------
# "Directional derivative" of a vector field: internal and only used to compute
# efficiently the Lie bracket of two vector fields
"""
$(TYPEDSIGNATURES)

# Example
```jldoctest

```
"""
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

"""
$(TYPEDSIGNATURES)

# Example
```jldoctest

```
"""
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
"""
$(TYPEDSIGNATURES)


# Example
```jldoctest

```
"""
function Poisson(f::AbstractHamiltonian{Autonomous, V}, g::AbstractHamiltonian{Autonomous, V})::Hamiltonian{Autonomous, V} where {V <: VariableDependence}
    function fg(x, p, args...)
        n = size(x, 1)
        ff,gg = @match n begin
            1 => (z -> f(z[1], z[2], args...), z -> g(z[1], z[2], args...))
            _ => (z -> f(z[1:n], z[n+1:2n], args...), z -> g(z[1:n], z[n+1:2n], args...))
        end
        df = ctgradient(ff, [ x ; p ])
        dg = ctgradient(gg, [ x ; p ])
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n]
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
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n] 
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

function Poisson(f::Function, g::Function, dependences::DataType...)::Hamiltonian
    __check_dependencies(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependences ? NonFixed : Fixed
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

# @Lie [X, Y], for Lie brackets
# @Lie {X, Y}, for Poisson brackets
"""
$(TYPEDSIGNATURES)

Macros

# Example
```jldoctest

```
"""
macro Lie(expr::Expr)
    fun(x) = @match (@capture(x, [a_, b_]),@capture(x, {c_, d_})) begin
        (true, false) => :(Lie($a, $b))
        (false, true) => :(Poisson($c, $d))
        (false, false) => x
        _ => error("internal error")
    end
    return esc(postwalk(fun,expr))
end