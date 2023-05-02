#=
"""
$(TYPEDSIGNATURES)

Lie derivative of `f` along `X`.
"""
function Ad(X, f)
    return x -> ctgradient(f, x)'*X(x)
end

"""
$(TYPEDSIGNATURES)

Returns the Poisson bracket of `f` and `g`.
"""
function Poisson(f, g)
    function fg(x, p)
        n = size(x, 1)
        ff = z -> f(z[1:n], z[n+1:2n])
        gg = z -> g(z[1:n], z[n+1:2n])
        df = ctgradient(ff, [ x ; p ])
        dg = ctgradient(gg, [ x ; p ])
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n]
    end
    return fg
end
=#

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
# Directional derivative of a vector field
function Der(X::VectorField{:autonomous, 1}, Y::VectorField{:autonomous, 1})::VectorField{:autonomous, 1}
    return VectorField(x -> ctgradient(Y, x)*X(x), 
        time_dependence=:autonomous, state_dimension=1, label=Symbol(:Ad, :(_), X.label, :(_), Y.label))
end
function Der(X::VectorField{:nonautonomous, 1}, Y::VectorField{:nonautonomous, 1})::VectorField{:nonautonomous, 1}
    return VectorField((t, x) -> ctgradient(y -> Y(t, y), x)*X(t, x),
        time_dependence=:nonautonomous, state_dimension=1, label=Symbol(:Ad, :(_), X.label, :(_), Y.label))
end
function Der(X::VectorField{:autonomous, sd}, Y::VectorField{:autonomous, sd})::VectorField{:autonomous, sd} where {sd}
    return VectorField(x -> x isa ctNumber ? ctgradient(Y, x)*X(x) : ctjacobian(Y, x)*X(x),
        time_dependence=:autonomous, state_dimension=sd, label=Symbol(:Ad, :(_), X.label, :(_), Y.label))
end
function Der(X::VectorField{:nonautonomous, sd}, Y::VectorField{:nonautonomous, sd})::VectorField{:nonautonomous, sd} where {sd}
    return VectorField((t, x) -> x isa ctNumber ? ctgradient(y -> Y(t, y), x)*X(t, x) : ctjacobian(y -> Y(t, y), x)*X(t, x),
        time_dependence=:nonautonomous, state_dimension=sd, label=Symbol(:Ad, :(_), X.label, :(_), Y.label))
end
function ⋅(X::VectorField{td, sd}, Y::VectorField{td, sd})::VectorField{td, sd} where {td, sd}
    return Der(X, Y)
end

# ---------------------------------------------------------------------------
# Lie bracket of two vector fields: [X, Y] = Lie(X, Y)= ad(X, Y)
function Lie(X::VectorField{:autonomous, sd}, Y::VectorField{:autonomous, sd})::VectorField{:autonomous, sd} where {sd}
    return VectorField(x -> (X⋅Y)(x)-(Y⋅X)(x), time_dependence=:autonomous, state_dimension=sd, label=Symbol(X.label, Y.label))
end
function Lie(X::VectorField{:nonautonomous, sd}, Y::VectorField{:nonautonomous, sd})::VectorField{:nonautonomous, sd} where {sd}
    return VectorField((t, x) -> (X⋅Y)(t, x)-(Y⋅X)(t, x), time_dependence=:nonautonomous, state_dimension=sd, label=Symbol(X.label, Y.label))
end
function ad(X::VectorField{td, sd}, Y::VectorField{td, sd})::VectorField{td, sd} where {td, sd}
    return Lie(X, Y)
end
function Lie(X::Function, Y::Function; time_dependence::Symbol=CTBase.__fun_time_dependence())::VectorField
    #
    check_time_dependence(time_dependence)
    #
    return Lie(VectorField(X, time_dependence=time_dependence),
            VectorField(Y, time_dependence=time_dependence))
end
function ad(X::Function, Y::Function; time_dependence::Symbol=CTBase.__fun_time_dependence())::VectorField
    return Lie(X, Y, time_dependence=time_dependence)
end

# Multiple lie brackets of any sequence
const Sequence = Tuple{Vararg{Integer}}
const Sequences = Tuple{Vararg{Sequence}}
const SequenceLabels = Tuple{Vararg{Symbol}}
const SequencesLabels = Tuple{Vararg{SequenceLabels}}

#
__fun_sequence(Xs::VectorField) = Tuple(1:length(Xs))

#
function Lie_sequence(Xs::VectorField{td, sd}...; sequence::Sequence=__fun_sequence(Xs))::VectorField{td, sd} where {td, sd}

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
        return Lie(Lie(Xs..., sequence=sequence[1:end-1]), Xs[sequence[end]])
    end

end

#
__fun_sequence_labels(Xs::VectorField...) = Tuple([X.label for X ∈ Xs])

#
function Lie_sequence_labels(Xs::VectorField{td, sd}...; sequence::SequenceLabels=__fun_sequence_labels(Xs))::VectorField{td, sd} where {td, sd}

    # check length of Xs
    length(Xs) < 2 && throw(IncorrectArgument("Xs must have at least two elements"))

    # check length of sequence
    length(sequence) < 2 && throw(IncorrectArgument("sequence must have at least two elements"))
    
    # check if the elements of sequence are contained in the labels of Xs
    Xs_labels = [X.label for X ∈ Xs]
    for o ∈ sequence
        o ∉ Xs_labels && throw(IncorrectArgument("sequence must contain only labels of Xs"))
    end

    # check if the lables of Xs are unique
    length(Xs_labels) != length(unique(Xs_labels)) && throw(IncorrectArgument("the labels of Xs must be unique"))

    # 
    if length(sequence) == 2
        # get indices of sequence[1] and sequence[2] in Xs_labels
        i1 = findfirst(o -> o == sequence[1], Xs_labels)
        i2 = findfirst(o -> o == sequence[2], Xs_labels)
        # return Lie bracket
        return Lie(Xs[i1], Xs[i2])
    else
        # get indices of sequence[end] in Xs_labels
        iend = findfirst(o -> o == sequence[end], Xs_labels)
        # return Lie bracket
        return Lie(Lie(Xs..., sequence=sequence[1:end-1]), Xs[iend])
    end

end

#
function Lie_sequences(Xs::VectorField{td, sd}...; sequences::Sequences=(__fun_sequence(Xs),))::Tuple{Vararg{VectorField{td, sd}}} where {td, sd}

    # check length of Xs
    length(Xs) < 2 && throw(IncorrectArgument("Xs must have at least two elements"))

    # 
    Ls = Vector{VectorField{td, sd}}()
    for sequence ∈ sequences
        push!(Ls, Lie(Xs..., sequence=sequence))
    end
    return Tuple(Ls)
        
end

function Lie_sequences_labels(Xs::VectorField{td, sd}...; sequences::SequencesLabels=(__fun_sequence_labels(Xs),))::Tuple{Vararg{VectorField{td, sd}}} where {td, sd}

    # check length of Xs
    length(Xs) < 2 && throw(IncorrectArgument("Xs must have at least two elements"))

    # 
    Ls = Vector{VectorField{td, sd}}()
    for sequence ∈ sequences
        push!(Ls, Lie(Xs..., sequence=sequence))
    end
    return Tuple(Ls)
        
end

#
function Lie(Xs::VectorField{td, sd}...; 
    sequences::Union{Nothing, Sequences, SequencesLabels}=nothing, 
    sequence::Union{Nothing, Sequence, SequenceLabels}=nothing) where {td, sd}
    
    # check if only one of sequences and sequence is specified
    (!isnothing(sequence) && !isnothing(sequences)) && throw(IncorrectArgument("only one of sequences and sequence can be specified"))

    if sequences ≠ nothing # sequences is specified
        if sequences isa SequencesLabels # sequences is a tuple of sequence labels
            return Lie_sequences_labels(Xs..., sequences=sequences)
        else # sequences is a tuple of sequences
            return Lie_sequences(Xs..., sequences=sequences)
        end
    elseif sequence ≠ nothing # sequence is specified
        if sequence isa SequenceLabels # sequence is a tuple of sequence labels
            return Lie_sequence_labels(Xs..., sequence=sequence)
        else # sequence is a tuple of sequences
            return Lie_sequence(Xs..., sequence=sequence)
        end
    else
        return Lie_sequence(Xs...)
    end
end

function _Lie_sequence(expr::Symbol)
    v = split(string(expr))[1]
    @assert v[1] == 'F'
    uni = sort(unique(v[2:end]))
    vfs = Tuple([Symbol(:F, n) for n ∈ uni])
    seq = [parse(Integer, c) for c ∈ v[2:end]]
    sequence = Tuple([findfirst(v->v==s, parse.(Integer, uni)) for s ∈ seq])
    code = quote
        $expr = Lie($(vfs...), sequence=$sequence)
    end
    return code
end

macro Lie(expr::Symbol)
    v = split(string(expr))[1]
    @assert v[1] == 'F'
    uni = sort(unique(v[2:end]))
    vfs = Tuple([Symbol(:F, n) for n ∈ uni])
    seq = [parse(Integer, c) for c ∈ v[2:end]]
    sequence = Tuple([findfirst(v->v==s, parse.(Integer, uni)) for s ∈ seq])
    code = quote
        $expr = Lie($(vfs...), sequence=$sequence)
    end
    return esc(code)
end

macro Lie(expr::Expr)
    @assert hasproperty(expr, :head)
    @assert expr.head == :vect
    @assert length(expr.args) == 2
    return postwalk( x -> @capture(x, [a_, b_]) ? :(Lie($a, $b)) : x, expr)
end