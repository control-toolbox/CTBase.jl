"""
$(TYPEDSIGNATURES)

Return the HamiltonianLift of a VectorField.

# Example
```@example
julia> HL = Lift(VectorField(x -> [x[1]^2,x[2]^2], autonomous=true, variable=false))
julia> HL([1, 0], [0, 1])
0
julia> HL = Lift(VectorField((t, x, v) -> [t+x[1]^2,x[2]^2+v], autonomous=false, variable=true))
julia> HL(1, [1, 0], [0, 1], 1)
1
julia> H = Lift(x -> 2x)
julia> H(1, 1)
2
julia> H = Lift((t, x, v) -> 2x + t - v, autonomous=false, variable=true)
julia> H(1, 1, 1, 1)
2
julia> H = Lift((t, x, v) -> 2x + t - v, NonAutonomous, NonFixed)
julia> H(1, 1, 1, 1)
2
```
"""
function Lift(X::VectorField)::HamiltonianLift
    return HamiltonianLift(X)
end

"""
$(TYPEDSIGNATURES)

Return the HamiltonianLift of a function.
Dependencies are specified with boolean : autonomous and variable.

# Example
```@example
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

Return the HamiltonianLift of a VectorField or a function.
Dependencies are specified with DataType : Autonomous, NonAutonomous and Fixed, NonFixed.

# Example
```@example
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

# (postulate)
# (X⋅f)(x)    = f'(x)⋅X(x)
# (X⋅f)(t, x) = ∂ₓf(t, x)⋅X(t, x)
# (g⋅f)(x) = f'(x)⋅G(x) with G the vector of g
"""
$(TYPEDSIGNATURES)

Lie derivative of a scalar function along a vector field : L_X(f) = X⋅f, in autonomous case

# Example
```@example
julia> φ = x -> [x[2], -x[1]]
julia> X = VectorField(φ)
julia> f = x -> x[1]^2 + x[2]^2
julia> (X⋅f)([1, 2])
0
```
"""
function ⋅(X::VectorField{Autonomous, <: VariableDependence}, f::Function)::Function
    return (x, args...) -> ctgradient(y -> f(y, args...), x)'*X(x, args...)
end

"""
$(TYPEDSIGNATURES)

Lie derivative of a scalar function along a vector field : L_X(f) = X⋅f, in nonautonomous case

# Example
```@example
julia> φ = (t, x, v) -> [t + x[2] + v[1], -x[1] + v[2]]
julia> X = VectorField(φ, NonAutonomous, NonFixed)
julia> f = (t, x, v) -> t + x[1]^2 + x[2]^2
julia> (X⋅f)(1, [1, 2], [2, 1])
10
```
"""
function ⋅(X::VectorField{NonAutonomous, <: VariableDependence}, f::Function)::Function
    return (t, x, args...) -> ctgradient(y -> f(t, y, args...), x)'*X(t, x, args...)
end

"""
$(TYPEDSIGNATURES)

Lie derivative of a scalar function along a function.
In this case both functions will be considered autonomous and non-variable.

# Example
```@example
julia> φ = x -> [x[2], -x[1]]
julia> f = x -> x[1]^2 + x[2]^2
julia> (φ⋅f)([1, 2])
0
julia> φ = (t, x, v) -> [t + x[2] + v[1], -x[1] + v[2]]
julia> f = (t, x, v) -> t + x[1]^2 + x[2]^2
julia> (φ⋅f)(1, [1, 2], [2, 1])
MethodError
```
"""
function ⋅(X::Function, f::Function)::Function
    return ⋅(VectorField(X, Autonomous, Fixed), f)
end

"""
$(TYPEDSIGNATURES)

Lie derivative of a scalar function along a vector field.

# Example
```@example
julia> φ = x -> [x[2], -x[1]]
julia> X = VectorField(φ)
julia> f = x -> x[1]^2 + x[2]^2
julia> Lie(X,f)([1, 2])
0
julia> φ = (t, x, v) -> [t + x[2] + v[1], -x[1] + v[2]]
julia> X = VectorField(φ, NonAutonomous, NonFixed)
julia> f = (t, x, v) -> t + x[1]^2 + x[2]^2
julia> Lie(X, f)(1, [1, 2], [2, 1])
10
```
"""
Lie(X::VectorField, f::Function)::Function = X⋅f

"""
$(TYPEDSIGNATURES)

Lie derivative of a scalar function along a function.
Dependencies are specified with boolean : autonomous and variable.

# Example
```@example
julia> φ = x -> [x[2], -x[1]]
julia> f = x -> x[1]^2 + x[2]^2
julia> Lie(φ,f)([1, 2])
0
julia> φ = (t, x, v) -> [t + x[2] + v[1], -x[1] + v[2]]
julia> f = (t, x, v) -> t + x[1]^2 + x[2]^2
julia> Lie(φ, f, autonomous=false, variable=true)(1, [1, 2], [2, 1])
10
```
"""
function Lie(X::Function, f::Function; autonomous::Bool=true, variable::Bool=false)::Function
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    variable_dependence = variable ? NonFixed : Fixed
    return Lie(VectorField(X, time_dependence, variable_dependence), f)
end

"""
$(TYPEDSIGNATURES)

Lie derivative of a scalar function along a vector field or a function.
Dependencies are specified with DataType : Autonomous, NonAutonomous and Fixed, NonFixed.

# Example
```@example
julia> φ = x -> [x[2], -x[1]]
julia> f = x -> x[1]^2 + x[2]^2
julia> Lie(φ,f)([1, 2])
0
julia> φ = (t, x, v) -> [t + x[2] + v[1], -x[1] + v[2]]
julia> f = (t, x, v) -> t + x[1]^2 + x[2]^2
julia> Lie(φ, f, NonAutonomous, NonFixed)(1, [1, 2], [2, 1])
10
```
"""
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

Partial derivative wrt time of a function.

# Example
```@example
julia> ∂ₜ((t,x) -> t*x)(0,8)
8
```
"""
∂ₜ(f) = (t, args...) -> ctgradient(y -> f(y, args...), t)

# ---------------------------------------------------------------------------
# "Directional derivative" of a vector field: internal and only used to compute
# efficiently the Lie bracket of two vector fields
"""
$(TYPEDSIGNATURES)

"Directional derivative" of a vector field: internal and only used to compute
efficiently the Lie bracket of two vector fields, autonomous case

# Example
```@example
julia> X = VectorField(x -> [x[2], -x[1]])
julia> Y = VectorField(x -> [x[1], x[2]])
julia> CTBase.:(⅋)(X, Y)([1, 2])
[2, -1]
```
"""
function ⅋(X::VectorField{Autonomous, V}, Y::VectorField{Autonomous, V})::VectorField{Autonomous, V} where {V<:VariableDependence}
    return VectorField((x, args...) -> x isa ctNumber ? 
        ctgradient(y -> Y(y, args...), x) * X(x, args...) : 
        ctjacobian(y -> Y(y, args...), x) * X(x, args...),
        Autonomous, V)
end

"""
$(TYPEDSIGNATURES)

"Directional derivative" of a vector field: internal and only used to compute
efficiently the Lie bracket of two vector fields, nonautonomous case

# Example
```@example
julia> X = VectorField((t, x, v) -> [t + v[1] + v[2] + x[2], -x[1]], NonFixed, NonAutonomous)
julia> Y = VectorField((t, x, v) ->  [v[1] + v[2] + x[1], x[2]], NonFixed, NonAutonomous)
julia> CTBase.:(⅋)(X, Y)(1, [1, 2], [2, 3])
[8, -1]
```
"""
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

Lie bracket of two vector fields: [X, Y] = Lie(X, Y), autonomous case

# Example
```@example
julia> f = x -> [x[2], 2x[1]]
julia> g = x -> [3x[2], -x[1]]
julia> X = VectorField(f)
julia> Y = VectorField(g)
julia> Lie(X, Y)([1, 2])
[7, -14]
```
"""
function Lie(X::VectorField{Autonomous, V}, Y::VectorField{Autonomous, V})::VectorField{Autonomous, V} where {V<:VariableDependence}
    return VectorField((x, args...) -> (X⅋Y)(x, args...)-(Y⅋X)(x, args...), Autonomous, V)
end

"""
$(TYPEDSIGNATURES)

Lie bracket of two vector fields: [X, Y] = Lie(X, Y), nonautonomous case

# Example
```@example
julia> f = (t, x, v) -> [t + x[2] + v, -2x[1] - v]
julia> g = (t, x, v) -> [t + 3x[2] + v, -x[1] - v]
julia> X = VectorField(f, NonAutonomous, NonFixed)
julia> Y = VectorField(g, NonAutonomous, NonFixed)
julia> Lie(X, Y)(1, [1, 2], 1)
[-7,12]
```
"""
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

Poisson bracket of two Hamiltonian functions (subtype of AbstractHamiltonian) : {f, g} = Poisson(f, g), autonomous case

# Example
```@example
julia> f = (x, p) -> x[2]^2 + 2x[1]^2 + p[1]^2
julia> g = (x, p) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1]
julia> F = Hamiltonian(f)
julia> G = Hamiltonian(g)
julia> Poisson(f, g)([1, 2], [2, 1])
-20            
julia> Poisson(f, G)([1, 2], [2, 1])
-20
julia> Poisson(F, g)([1, 2], [2, 1])
-20
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
"""
$(TYPEDSIGNATURES)

Poisson bracket of two Hamiltonian functions (subtype of AbstractHamiltonian) : {f, g} = Poisson(f, g), non autonomous case

# Example
```@example
julia> f = (t, x, p, v) -> t*v[1]*x[2]^2 + 2x[1]^2 + p[1]^2 + v[2]
julia> g = (t, x, p, v) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] + t - v[2]
julia> F = Hamiltonian(f, autonomous=false, variable=true)
julia> G = Hamiltonian(g, autonomous=false, variable=true)
julia> Poisson(F, G)(2, [1, 2], [2, 1], [4, 4])
-76
julia> Poisson(f, g, NonAutonomous, NonFixed)(2, [1, 2], [2, 1], [4, 4])
-76
```
"""
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

"""
$(TYPEDSIGNATURES)

Poisson bracket of two HamiltonianLift functions : {f, g} = Poisson(f, g)

# Example
```@example
julia> f = x -> [x[1]^2+x[2]^2, 2x[1]^2]
julia> g = x -> [3x[2]^2, x[2]-x[1]^2]
julia> F = Lift(f)
julia> G = Lift(g)
julia> Poisson(F, G)([1, 2], [2, 1])
-64
julia> f = (t, x, v) -> [t*v[1]*x[2]^2, 2x[1]^2 + + v[2]]
julia> g = (t, x, v) -> [3x[2]^2 + -x[1]^2, t - v[2]]
julia> F = Lift(f, NonAutonomous, NonFixed)
julia> G = Lift(g, NonAutonomous, NonFixed)
julia> Poisson(F, G)(2, [1, 2], [2, 1], [4, 4])
100
```
"""
function Poisson(f::HamiltonianLift{T, V}, g::HamiltonianLift{T, V})::HamiltonianLift{T, V} where {T <: TimeDependence, V <: VariableDependence}
    return HamiltonianLift(Lie(f.X, g.X))
end

"""
$(TYPEDSIGNATURES)

Poisson bracket of two functions : {f, g} = Poisson(f, g)
Dependencies are specified with boolean : autonomous and variable.

# Example
```@example
julia> f = (x, p) -> x[2]^2 + 2x[1]^2 + p[1]^2
julia> g = (x, p) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1]
julia> Poisson(f, g)([1, 2], [2, 1])
-20            
julia> f = (t, x, p, v) -> t*v[1]*x[2]^2 + 2x[1]^2 + p[1]^2 + v[2]
julia> g = (t, x, p, v) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] + t - v[2]
julia> Poisson(f, g, autonomous=false, variable=true)(2, [1, 2], [2, 1], [4, 4])
-76
```
"""
function Poisson(f::Function, g::Function; autonomous::Bool=true, variable::Bool=false)::Hamiltonian
    time_dependence = autonomous ? Autonomous : NonAutonomous 
    variable_dependence = variable ? NonFixed : Fixed
    return Poisson(Hamiltonian(f, time_dependence, variable_dependence), Hamiltonian(g, time_dependence, variable_dependence))
end

"""
$(TYPEDSIGNATURES)

Poisson bracket of two functions : {f, g} = Poisson(f, g)
Dependencies are specified with DataType : Autonomous, NonAutonomous and Fixed, NonFixed.

# Example
```@example
julia> f = (x, p) -> x[2]^2 + 2x[1]^2 + p[1]^2
julia> g = (x, p) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1]
julia> Poisson(f, g)([1, 2], [2, 1])
-20            
julia> f = (t, x, p, v) -> t*v[1]*x[2]^2 + 2x[1]^2 + p[1]^2 + v[2]
julia> g = (t, x, p, v) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] + t - v[2]
julia> Poisson(f, g, NonAutonomous, NonFixed)(2, [1, 2], [2, 1], [4, 4])
-76
```
"""
function Poisson(f::Function, g::Function, dependences::DataType...)::Hamiltonian
    __check_dependencies(dependences)
    time_dependence = NonAutonomous ∈ dependences ? NonAutonomous : Autonomous
    variable_dependence = NonFixed ∈ dependences ? NonFixed : Fixed
    return Poisson(Hamiltonian(f, time_dependence, variable_dependence), Hamiltonian(g, time_dependence, variable_dependence))
end

"""
$(TYPEDSIGNATURES)

Poisson bracket of a function and an Hamiltonian function (subtype of AbstractHamiltonian) : {f, g} = Poisson(f, g)

# Example
```@example
julia> f = (x, p) -> x[2]^2 + 2x[1]^2 + p[1]^2
julia> g = (x, p) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1]
julia> G = Hamiltonian(g)          
julia> Poisson(f, G)([1, 2], [2, 1])
-20
julia> f = (t, x, p, v) -> t*v[1]*x[2]^2 + 2x[1]^2 + p[1]^2 + v[2]
julia> g = (t, x, p, v) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] + t - v[2]
julia> G = Hamiltonian(g, autonomous=false, variable=true)
julia> Poisson(f, G)(2, [1, 2], [2, 1], [4, 4])
-76
```
"""
function Poisson(f::Function, g::AbstractHamiltonian{T, V})::Hamiltonian where {T<:TimeDependence, V<:VariableDependence}
    return Poisson(Hamiltonian(f, T, V), g)
end

"""
$(TYPEDSIGNATURES)

Poisson bracket of an Hamiltonian function (subtype of AbstractHamiltonian) and a function : {f, g} = Poisson(f, g), autonomous case

# Example
```@example
julia> f = (x, p) -> x[2]^2 + 2x[1]^2 + p[1]^2
julia> g = (x, p) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1]
julia> F = Hamiltonian(f)
julia> Poisson(F, g)([1, 2], [2, 1])
-20
julia> f = (t, x, p, v) -> t*v[1]*x[2]^2 + 2x[1]^2 + p[1]^2 + v[2]
julia> g = (t, x, p, v) -> 3x[2]^2 + -x[1]^2 + p[2]^2 + p[1] + t - v[2]
julia> F = Hamiltonian(f, autonomous=false, variable=true)
julia> Poisson(F, g)(2, [1, 2], [2, 1], [4, 4])
-76
```
"""
function Poisson(f::AbstractHamiltonian{T, V}, g::Function)::Hamiltonian where {T<:TimeDependence, V<:VariableDependence}
    return Poisson(f, Hamiltonian(g, T, V))
end

# ---------------------------------------------------------------------------
# Macros

# @Lie [X, Y], for Lie brackets
# @Lie {X, Y}, for Poisson brackets
"""
$(TYPEDSIGNATURES)

Macros for Lie and Poisson brackets

# Example
```@example
julia> F0 = VectorField(x -> [x[1], x[2], (1-x[3])])
julia> F1 = VectorField(x -> [0, -x[3], x[2]])
julia> @Lie [F0, F1]([1, 2, 3])
[0, 5, 4]
#
julia> F0 = VectorField((t, x) -> [t+x[1], x[2], (1-x[3])], autonomous=false)
julia> F1 = VectorField((t, x) -> [t, -x[3], x[2]], autonomous=false)
julia> @Lie [F0, F1](1, [1, 2, 3])
#
julia> F0 = VectorField((x, v) -> [x[1]+v, x[2], (1-x[3])], variable=true)
julia> F1 = VectorField((x, v) -> [0, -x[3]-v, x[2]], variable=true)
julia> @Lie [F0, F1]([1, 2, 3], 2)
#
julia> F0 = VectorField((t, x, v) -> [t+x[1]+v, x[2], (1-x[3])], autonomous=false, variable=true)
julia> F1 = VectorField((t, x, v) -> [t, -x[3]-v, x[2]], autonomous=false, variable=true)
julia> @Lie [F0, F1](1, [1, 2, 3], 2)
#
julia> H0 = Hamiltonian((x, p) -> 0.5*(2x[1]^2+x[2]^2+p[1]^2))
julia> H1 = Hamiltonian((x, p) -> 0.5*(3x[1]^2+x[2]^2+p[2]^2))
julia> @Lie {H0, H1}([1, 2, 3], [1, 0, 7])
3.0
#
julia> H0 = Hamiltonian((t, x, p) -> 0.5*(x[1]^2+x[2]^2+p[1]^2), autonomous=false)
julia> H1 = Hamiltonian((t, x, p) -> 0.5*(x[1]^2+x[2]^2+p[2]^2), autonomous=false)
julia> @Lie {H0, H1}(1, [1, 2, 3], [1, 0, 7])
#
julia> H0 = Hamiltonian((x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[1]^2+v), variable=true)
julia> H1 = Hamiltonian((x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[2]^2+v), variable=true)
julia> @Lie {H0, H1}([1, 2, 3], [1, 0, 7], 2)
#
julia> H0 = Hamiltonian((t, x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[1]^2+v), autonomous=false, variable=true)
julia> H1 = Hamiltonian((t, x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[2]^2+v), autonomous=false, variable=true)
julia> @Lie {H0, H1}(1, [1, 2, 3], [1, 0, 7], 2)
#
```
"""
macro Lie(expr::Expr)

    fun(x) = @match (@capture(x, [a_, b_]),@capture(x, {c_, d_})) begin
        (true, false) => :(    Lie($a, $b))
        (false, true) => :(Poisson($c, $d))
        (false, false) => x
        _ => error("internal error")
    end

    return esc(postwalk(fun,expr))

end

"""
$(TYPEDSIGNATURES)

Macros for Poisson brackets

# Example
```@example
julia> H0 = (x, p) -> 0.5*(x[1]^2+x[2]^2+p[1]^2)
julia> H1 = (x, p) -> 0.5*(x[1]^2+x[2]^2+p[2]^2)
julia> @Lie {H0, H1}([1, 2, 3], [1, 0, 7]) autonomous=true variable=false
#
julia> H0 = (t, x, p) -> 0.5*(x[1]^2+x[2]^2+p[1]^2)
julia> H1 = (t, x, p) -> 0.5*(x[1]^2+x[2]^2+p[2]^2)
julia> @Lie {H0, H1}(1, [1, 2, 3], [1, 0, 7]) autonomous=false variable=false
#
julia> H0 = (x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[1]^2+v)
julia> H1 = (x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[2]^2+v)
julia> @Lie {H0, H1}([1, 2, 3], [1, 0, 7], 2) autonomous=true variable=true
#
julia> H0 = (t, x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[1]^2+v)
julia> H1 = (t, x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[2]^2+v)
julia> @Lie {H0, H1}(1, [1, 2, 3], [1, 0, 7], 2) autonomous=false variable=true
```
"""
macro Lie(expr::Expr, arg1, arg2)

    local autonomous=true
    local variable=false

    @match arg1 begin
        :( Autonomous      ) => begin autonomous=true end
        :( NonAutonomous   ) => begin autonomous=false end
        :( autonomous = $a ) => begin autonomous=a end
        :( NonFixed        ) => begin variable=true end
        :( Fixed           ) => begin variable=false end
        :( variable   = $a ) => begin variable=a end
        _ => throw(IncorrectArgument("Invalid argument: " * string(arg1)))
    end

    @match arg2 begin
        :( Autonomous      ) => begin autonomous=true end
        :( NonAutonomous   ) => begin autonomous=false end
        :( autonomous = $a ) => begin autonomous=a end
        :( NonFixed        ) => begin variable=true end
        :( Fixed           ) => begin variable=false end
        :( variable   = $a ) => begin variable=a end
        _ => throw(IncorrectArgument("Invalid argument: " * string(arg2)))
    end
    
    fun(x) = @match (@capture(x, [a_, b_]),@capture(x, {c_, d_})) begin
        #(true, false) => :(    Lie($a, $b; autonomous=$autonomous, variable=$variable))
        (false, true) => quote 
            ($c isa Function && $d isa Function) ? 
            Poisson($c, $d; autonomous=$autonomous, variable=$variable) : Poisson($c, $d)
        end
        (false, false) => x
        _ => error("internal error")
    end

    return esc(postwalk(fun,expr))

end

"""
$(TYPEDSIGNATURES)

Macros for Lie and Poisson brackets

# Example
```@example
julia> H0 = (t, x, p) -> 0.5*(x[1]^2+x[2]^2+p[1]^2)
julia> H1 = (t, x, p) -> 0.5*(x[1]^2+x[2]^2+p[2]^2)
julia> @Lie {H0, H1}(1, [1, 2, 3], [1, 0, 7]) autonomous=false
#
julia> H0 = (x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[1]^2+v)
julia> H1 = (x, p, v) -> 0.5*(x[1]^2+x[2]^2+p[2]^2+v)
julia> @Lie {H0, H1}([1, 2, 3], [1, 0, 7], 2) variable=true
#
```
"""
macro Lie(expr::Expr, arg)

    local autonomous=true
    local variable=false

    @match arg begin
        :( Autonomous      ) => begin autonomous=true end
        :( NonAutonomous   ) => begin autonomous=false end
        :( autonomous = $a ) => begin autonomous=a end
        :( NonFixed        ) => begin variable=true end
        :( Fixed           ) => begin variable=false end
        :( variable   = $a ) => begin variable=a end
        _ => throw(IncorrectArgument("Invalid argument: " * string(arg)))
    end

    fun(x) = @match (@capture(x, [a_, b_]),@capture(x, {c_, d_})) begin
        #(true, false) => :(    Lie($a, $b; autonomous=$autonomous, variable=$variable))
        (false, true) => quote 
            ($c isa Function && $d isa Function) ? 
            Poisson($c, $d; autonomous=$autonomous, variable=$variable) : Poisson($c, $d)
        end
        (false, false) => x
        _ => error("internal error")
    end

    return esc(postwalk(fun,expr))

end