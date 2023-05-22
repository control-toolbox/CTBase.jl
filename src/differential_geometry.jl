# ---------------------------------------------------------------------------
# abstract type AbstractHamiltonian end

# ---------------------------------------------------------------------------
# HamiltonianLift
struct HamiltonianLift{time_dependence} <: AbstractHamiltonian
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

# ---------------------------------------------------------------------------
# Multiple lie brackets of any length

# type
const Sequence = Tuple{Vararg{Integer}}

# default value of a sequence of vector fields to compute one Lie bracket
__fun_sequence(Xs::VectorField...) = Tuple(1:length(Xs))

#
function _Lie_sequence(Xs::VectorField{T,V}...; sequence::Sequence=__fun_sequence(Xs...))::VectorField{T,V} where {T,V}

    # check length of Xs
    length(Xs) < 2 && throw(IncorrectArgument("Xs must have at least two elements"))

    # check length of sequence
    length(sequence) < 2 && throw(IncorrectArgument("sequence must have at least two elements"))
    
    # check if the elements of sequence are contained in 1:length(Xs)
    for o ∈ sequence
        o < 1 && throw(IncorrectArgument("sequence must contain only positive integers"))
        o > length(Xs) && throw(IncorrectArgument("sequence must contain only integers less than or equal to the length of Xs"))
    end

    # 
    if length(sequence) == 2
        return Lie(Xs[sequence[1]], Xs[sequence[2]])
    else
        return Lie(_Lie_sequence(Xs..., sequence=sequence[1:end-1]), Xs[sequence[end]])
    end

end

# ---------------------------------------------------------------------------
# Macro

# # @Lie F01
# macro Lie(expr::Symbol)

#     # split symbol into substrings
#     v = split(string(expr))[1]

#     # check if the first character is 'F'
#     @assert v[1] == 'F'

#     # get the unique numbers in the symbol
#     uni = sort(unique(v[2:end]))

#     # build the tuple of needed vector fields
#     vfs = Tuple([Symbol(:F, n) for n ∈ uni])

#     # build the sequence to compute the Lie bracket
#     user_sequence = [parse(Integer, c) for c ∈ v[2:end]] # conversion to integer
#     sequence = Tuple([findfirst(v->v==s, parse.(Integer, uni)) for s ∈ user_sequence])

#     # build the code
#     code = quote
#         $expr = _Lie_sequence($(vfs...), sequence=$sequence)
#     end

#     return esc(code)
# end

# @Lie [X, Y]
macro Lie(expr::Expr)
    @assert hasproperty(expr, :head)
    @assert expr.head == :vect
    @assert length(expr.args) == 2
    return esc(postwalk( x -> @capture(x, [a_, b_]) ? :(Lie($a, $b)) : x, expr))
end


function Poisson(f::AbstractHamiltonian, g::AbstractHamiltonian)
    function fg(x, p)
        n = size(x, 1)
        ff,gg = @match n begin
            1 => (z -> f(z[1], z[2]), z -> g(z[1], z[2]))
            _ => (z -> f(z[1:n], z[n+1:2n]), z -> g(z[1:n], z[n+1:2n]))
        end
        # ff = z -> f(z[1:n], z[n+1:2n])
        # gg = z -> g(z[1:n], z[n+1:2n])
        df = ctgradient(ff, [ x ; p ])
        dg = ctgradient(gg, [ x ; p ])
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n]
    end
    return fg
end