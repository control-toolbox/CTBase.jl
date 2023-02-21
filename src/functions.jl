# -------------------------------------------------------------------------------------------
abstract type AbstractCTFunction <: Function end
abstract_heritance=:AbstractCTFunction

# -------------------------------------------------------------------------------------------
#
function_name=:BoundaryConstraintFunction
#
@eval @ctfunction_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
@eval function (F::$(function_name){scalar_vectorial})(t0::Time, x0::State, tf::Time, xf::State, args...; kwargs...) where {scalar_vectorial}
    x_ = (scalar_vectorial==:scalar && length(x0)==1) ? (t0, x0[1], tf, xf[1]) : (t0, x0, tf, xf)
    return F.f(x_..., args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
#
function_name=:MayerFunction
#
@eval @ctfunction_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
@eval function (F::$(function_name){scalar_vectorial})(t0::Time, x0::State, tf::Time, xf::State, args...; kwargs...) where {scalar_vectorial}
    x_ = (scalar_vectorial==:scalar && length(x0)==1) ? (t0, x0[1], tf, xf[1]) : (t0, x0, tf, xf)
    return F.f(x_..., args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
#
function_name=:Hamiltonian
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
#
function_name=:VectorField
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, x::State, args...; kwargs...) where {time_dependence, scalar_vectorial}
    args_ = time_dependence==:autonomous ? () : (t, )
    if scalar_vectorial==:scalar && length(x)==1
        args_ = (args_..., x[1])
    else
        args_ = (args_..., x)
    end
    return F.f(args_..., args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
#
function_name=:LagrangeFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, x::State, u::Control, args...; kwargs...) where {time_dependence, scalar_vectorial}
    t_ = time_dependence==:autonomous ? () : (t, )
    x_ = (scalar_vectorial==:scalar && length(x)==1) ? (x[1], ) : (x, )
    u_ = (scalar_vectorial==:scalar && length(u)==1) ? (u[1], ) : (u, )
    return F.f(t_..., x_..., u_..., args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
#
function_name=:DynamicsFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, x::State, u::Control, args...; kwargs...) where {time_dependence, scalar_vectorial}
    t_ = time_dependence==:autonomous ? () : (t, )
    x_ = (scalar_vectorial==:scalar && length(x)==1) ? (x[1], ) : (x, )
    u_ = (scalar_vectorial==:scalar && length(u)==1) ? (u[1], ) : (u, )
    return F.f(t_..., x_..., u_..., args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
#
function_name=:StateConstraintFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, x::State, args...; kwargs...) where {time_dependence, scalar_vectorial}
    t_ = time_dependence==:autonomous ? () : (t, )
    x_ = (scalar_vectorial==:scalar && length(x)==1) ? (x[1], ) : (x, )
    return F.f(t_..., x_..., args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
#
function_name=:ControlConstraintFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, u::Control, args...; kwargs...) where {time_dependence, scalar_vectorial}
    t_ = time_dependence==:autonomous ? () : (t, )
    u_ = (scalar_vectorial==:scalar && length(u)==1) ? (u[1], ) : (u, )
    return F.f(t_..., u_..., args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
#
function_name=:MixedConstraintFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
@eval function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, x::State, u::Control, args...; kwargs...) where {time_dependence, scalar_vectorial}
    t_ = time_dependence==:autonomous ? () : (t, )
    x_ = (scalar_vectorial==:scalar && length(x)==1) ? (x[1], ) : (x, )
    u_ = (scalar_vectorial==:scalar && length(u)==1) ? (u[1], ) : (u, )
    return F.f(t_..., x_..., u_..., args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
#
function_name=:ControlFunction
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
#
function_name=:MultiplierFunction
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

