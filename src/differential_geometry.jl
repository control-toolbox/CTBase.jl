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
#
# ctNumber
function (H::HamiltonianLift{:nonautonomous})(t::Time, x::ctNumber, p::ctNumber, args...; kwargs...)::ctNumber
    return p'*H.X(t, x, args...; kwargs...)
end
function (H::HamiltonianLift{:autonomous})(x::ctNumber, p::ctNumber, args...; kwargs...)::ctNumber
    return p'*H.X(x, args...; kwargs...)
end
# State, Adjoint
function (H::HamiltonianLift{:nonautonomous})(t::Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber
    return p'*H.X(t, x, args...; kwargs...)
end
function (H::HamiltonianLift{:autonomous})(x::State, p::Adjoint, args...; kwargs...)::ctNumber
    return p'*H.X(x, args...; kwargs...)
end

# ---------------------------------------------------------------------------
# Lift

# single lift: from VectorField
function Lift(X::VectorField)::HamiltonianLift
    return HamiltonianLift(X)
end

# single lift: from Function
function Lift(X::Function; time_dependence::Symbol=CTBase.__fun_time_dependence())::HamiltonianLift
    check_time_dependence(time_dependence)
    return HamiltonianLift(VectorField(X, time_dependence=time_dependence))
end

# multiple lifts: from VectorField
function Lift(Xs::VectorField...)::Tuple{Vararg{HamiltonianLift}}
    return Tuple(Lift(X) for X ∈ Xs)
end

# multiple lifts: from Function
function Lift(Xs::Function...; time_dependence::Symbol=CTBase.__fun_time_dependence())::Tuple{Vararg{HamiltonianLift}}
    check_time_dependence(time_dependence)
    return Tuple(Lift(X, time_dependence=time_dependence) for X ∈ Xs)
end

# ---------------------------------------------------------------------------
# Directional derivative of a scalar function
function Der(X::VectorField{:autonomous, sd}, f::Function)::Function where {sd}
   return x -> ctgradient(f, x)'*X(x)
end
function Der(X::VectorField{:nonautonomous, sd}, f::Function)::Function where {sd}
    return (t, x) -> ctgradient(y -> f(t, y), x)'*X(t, x)
end
function ⋅(X::VectorField{td, sd}, f::Function)::Function where {td, sd}
    return Der(X, f)
end

# ---------------------------------------------------------------------------
# Lie derivative of a scalar function = directional derivative
function Lie(X::VectorField{td, sd}, f::Function)::Function where {td, sd}
    return Der(X, f)
end

# ---------------------------------------------------------------------------
# "Directional derivative" of a vector field: internal and only used to compute
# efficiently the Lie bracket of two vector fields
function ⅋(X::VectorField{:autonomous, 1}, Y::VectorField{:autonomous, 1})::VectorField{:autonomous, 1}
    return VectorField(x -> ctgradient(Y, x)*X(x), 
        time_dependence=:autonomous, state_dimension=1)
end
function ⅋(X::VectorField{:nonautonomous, 1}, Y::VectorField{:nonautonomous, 1})::VectorField{:nonautonomous, 1}
    return VectorField((t, x) -> ctgradient(y -> Y(t, y), x)*X(t, x),
        time_dependence=:nonautonomous, state_dimension=1)
end
function ⅋(X::VectorField{:autonomous, sd}, Y::VectorField{:autonomous, sd})::VectorField{:autonomous, sd} where {sd}
    return VectorField(x -> x isa ctNumber ? ctgradient(Y, x)*X(x) : ctjacobian(Y, x)*X(x),
        time_dependence=:autonomous, state_dimension=sd)
end
function ⅋(X::VectorField{:nonautonomous, sd}, Y::VectorField{:nonautonomous, sd})::VectorField{:nonautonomous, sd} where {sd}
    return VectorField((t, x) -> x isa ctNumber ? ctgradient(y -> Y(t, y), x)*X(t, x) : ctjacobian(y -> Y(t, y), x)*X(t, x),
        time_dependence=:nonautonomous, state_dimension=sd)
end

# ---------------------------------------------------------------------------
# Lie bracket of two vector fields: [X, Y] = Lie(X, Y)= ad(X, Y)
function Lie(X::VectorField{:autonomous, sd}, Y::VectorField{:autonomous, sd})::VectorField{:autonomous, sd} where {sd}
    return VectorField(x -> (X⅋Y)(x)-(Y⅋X)(x), time_dependence=:autonomous, state_dimension=sd)
end
function Lie(X::VectorField{:nonautonomous, sd}, Y::VectorField{:nonautonomous, sd})::VectorField{:nonautonomous, sd} where {sd}
    return VectorField((t, x) -> (X⅋Y)(t, x)-(Y⅋X)(t, x), time_dependence=:nonautonomous, state_dimension=sd)
end
function ad(X::VectorField{td, sd}, Y::VectorField{td, sd})::VectorField{td, sd} where {td, sd}
    return Lie(X, Y)
end
function Lie(X::Function, Y::Function; time_dependence::Symbol=CTBase.__fun_time_dependence())::VectorField
    check_time_dependence(time_dependence)
    return Lie(VectorField(X, time_dependence=time_dependence), VectorField(Y, time_dependence=time_dependence))
end
function ad(X::Function, Y::Function; time_dependence::Symbol=CTBase.__fun_time_dependence())::VectorField
    return Lie(X, Y, time_dependence=time_dependence)
end

# ---------------------------------------------------------------------------
# Multiple lie brackets of any length

# type
const Sequence = Tuple{Vararg{Integer}}

# default value of a sequence of vector fields to compute one Lie bracket
__fun_sequence(Xs::VectorField...) = Tuple(1:length(Xs))

#
function _Lie_sequence(Xs::VectorField{td, sd}...; sequence::Sequence=__fun_sequence(Xs...))::VectorField{td, sd} where {td, sd}

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

# @Lie F01
macro Lie(expr::Symbol)

    # split symbol into substrings
    v = split(string(expr))[1]

    # check if the first character is 'F'
    @assert v[1] == 'F'

    # get the unique numbers in the symbol
    uni = sort(unique(v[2:end]))

    # build the tuple of needed vector fields
    vfs = Tuple([Symbol(:F, n) for n ∈ uni])

    # build the sequence to compute the Lie bracket
    user_sequence = [parse(Integer, c) for c ∈ v[2:end]] # conversion to integer
    sequence = Tuple([findfirst(v->v==s, parse.(Integer, uni)) for s ∈ user_sequence])

    # build the code
    code = quote
        $expr = _Lie_sequence($(vfs...), sequence=$sequence)
    end

    return esc(code)
end

# @Lie [X, Y]
macro Lie(expr::Expr)
    @assert hasproperty(expr, :head)
    @assert expr.head == :vect
    @assert length(expr.args) == 2
    return esc(postwalk( x -> @capture(x, [a_, b_]) ? :(Lie($a, $b)) : x, expr))
end
