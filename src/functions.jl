# -------------------------------------------------------------------------------------------
abstract type AbstractCTFunction <: Function end
abstract_heritance=:AbstractCTFunction

# scalar usage = :scalar

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:BoundaryConstraintFunction
#
@eval @ctfunction_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval function (F::$(function_name){scalar_vectorial})(t0::Time, 
    x0::State, tf::Time, xf::State, args...; kwargs...) where {scalar_vectorial}
    x_ = (scalar_vectorial==:scalar && length(x0)==1) ? (t0, x0[1], tf, xf[1]) : (t0, x0, tf, xf)
    y = F.f(x_..., args...; kwargs...)
    if scalar_vectorial==:scalar && !(y isa MyNumber) && length(y)==1
        throw(IncorrectOutput("A boundary constraint must return a Real (scalar)" *
        " if the output and usage are scalar."))
    end
    return y isa MyNumber ? [y] : y
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
function_name=:MayerFunction
#
@eval @ctfunction_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: scalar
@eval function (F::$(function_name){scalar_vectorial})(t0::Time, 
    x0::State, tf::Time, xf::State, args...; kwargs...) where {scalar_vectorial}
    x_ = (scalar_vectorial==:scalar && length(x0)==1) ? (t0, x0[1], tf, xf[1]) : (t0, x0, tf, xf)
    y = F.f(x_..., args...; kwargs...)
    if !(y isa MyNumber)
        throw(IncorrectOutput("A Mayer cost must return a Real (scalar)."))
    end
    return y
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
function_name=:Hamiltonian
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: scalar
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, 
    x::State, p::Adjoint, args...; kwargs...) where {time_dependence, scalar_vectorial}
    args_ = time_dependence==:autonomous ? () : (t, )
    if scalar_vectorial==:scalar && length(x)==1
        args_ = (args_..., x[1], p[1])
    else
        args_ = (args_..., x, p)
    end
    y = F.f(args_..., args...; kwargs...)
    if !(y isa MyNumber)
        throw(IncorrectOutput("A Hamiltonian function must return a Real (scalar)."))
    end
    return y
end

# -------------------------------------------------------------------------------------------
#
function_name=:HamiltonianVectorField
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, x::State, p::Adjoint, args...; kwargs...) where {time_dependence, scalar_vectorial}
    args_ = time_dependence==:autonomous ? () : (t, )
    if scalar_vectorial==:scalar && length(x)==1
        args_ = (args_..., x[1], p[1])
    else
        args_ = (args_..., x, p)
    end
    return F.f(args_..., args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if scalar usage and scalar as input
function_name=:VectorField
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, 
    x::State, args...; kwargs...) where {time_dependence, scalar_vectorial}
    args_ = time_dependence==:autonomous ? () : (t, )
    if scalar_vectorial==:scalar && length(x)==1
        args_ = (args_..., x[1])
    else
        args_ = (args_..., x)
    end
    y = F.f(args_..., args...; kwargs...)
    if scalar_vectorial==:scalar && length(x)==1
        if !(y isa MyNumber)
            throw(IncorrectOutput("A VectorField function must return a Real (scalar)" *
            " if the input and usage are scalar."))
        end
        return [y]
    else
        return y
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
function_name=:LagrangeFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: scalar
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, 
    x::State, u::Control, args...; kwargs...) where {time_dependence, scalar_vectorial}
    t_ = time_dependence==:autonomous ? () : (t, )
    x_ = (scalar_vectorial==:scalar && length(x)==1) ? (x[1], ) : (x, )
    u_ = (scalar_vectorial==:scalar && length(u)==1) ? (u[1], ) : (u, )
    y = F.f(t_..., x_..., u_..., args...; kwargs...)
    if !(y isa MyNumber)
        throw(IncorrectOutput("A Lagrange cost must return a Real (scalar)."))
    end
    return y
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if scalar usage and x scalar as input
function_name=:DynamicsFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, 
    x::State, u::Control, args...; kwargs...) where {time_dependence, scalar_vectorial}
    t_ = time_dependence==:autonomous ? () : (t, )
    x_ = (scalar_vectorial==:scalar && length(x)==1) ? (x[1], ) : (x, )
    u_ = (scalar_vectorial==:scalar && length(u)==1) ? (u[1], ) : (u, )
    y = F.f(t_..., x_..., u_..., args...; kwargs...)
    if scalar_vectorial==:scalar && length(x)==1
        if !(y isa MyNumber)
            throw(IncorrectOutput("A Dynamics function must return a Real (scalar)" *
            " if the input x and the usage are scalar."))
        end
        return [y]
    else
        return y
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:StateConstraintFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, x::State, args...; kwargs...) where {time_dependence, scalar_vectorial}
    t_ = time_dependence==:autonomous ? () : (t, )
    x_ = (scalar_vectorial==:scalar && length(x)==1) ? (x[1], ) : (x, )
    y = F.f(t_..., x_..., args...; kwargs...)
    if scalar_vectorial==:scalar && !(y isa MyNumber) && length(y)==1
        throw(IncorrectOutput("A state constraint must return a Real (scalar)" *
        " if the output and usage are scalar."))
    end
    return y isa MyNumber ? [y] : y
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:ControlConstraintFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, u::Control, args...; kwargs...) where {time_dependence, scalar_vectorial}
    t_ = time_dependence==:autonomous ? () : (t, )
    u_ = (scalar_vectorial==:scalar && length(u)==1) ? (u[1], ) : (u, )
    y = F.f(t_..., u_..., args...; kwargs...)
    if scalar_vectorial==:scalar && !(y isa MyNumber) && length(y)==1
        throw(IncorrectOutput("A control constraint must return a Real (scalar)" *
        " if the output and usage are scalar."))
    end
    return y isa MyNumber ? [y] : y
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:MixedConstraintFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, x::State, u::Control, args...; kwargs...) where {time_dependence, scalar_vectorial}
    t_ = time_dependence==:autonomous ? () : (t, )
    x_ = (scalar_vectorial==:scalar && length(x)==1) ? (x[1], ) : (x, )
    u_ = (scalar_vectorial==:scalar && length(u)==1) ? (u[1], ) : (u, )
    y = F.f(t_..., x_..., u_..., args...; kwargs...)
    if scalar_vectorial==:scalar && !(y isa MyNumber) && length(y)==1
        throw(IncorrectOutput("A mixed state/control constraint must return a Real (scalar)" *
        " if the output and usage are scalar."))
    end
    return y isa MyNumber ? [y] : y
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:ControlFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, 
    x::State, p::Adjoint, args...; kwargs...) where {time_dependence, scalar_vectorial}
    args_ = time_dependence==:autonomous ? () : (t, )
    if scalar_vectorial==:scalar && length(x)==1
        args_ = (args_..., x[1], p[1])
    else
        args_ = (args_..., x, p)
    end
    y = F.f(args_..., args...; kwargs...)
    if scalar_vectorial==:scalar && !(y isa MyNumber) && length(y)==1
        throw(IncorrectOutput("A control function must return a Real (scalar)" *
        " if the output and usage are scalar."))
    end
    return y isa MyNumber ? [y] : y
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:MultiplierFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, 
    x::State, p::Adjoint, args...; kwargs...) where {time_dependence, scalar_vectorial}
    args_ = time_dependence==:autonomous ? () : (t, )
    if scalar_vectorial==:scalar && length(x)==1
        args_ = (args_..., x[1], p[1])
    else
        args_ = (args_..., x, p)
    end
    y = F.f(args_..., args...; kwargs...)
    if scalar_vectorial==:scalar && !(y isa MyNumber) && length(y)==1
        throw(IncorrectOutput("A multiplier function must return a Real (scalar)" *
        " if the output and usage are scalar."))
    end
    return y isa MyNumber ? [y] : y
end