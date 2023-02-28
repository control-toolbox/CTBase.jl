# generate callable structure with the managing of autonomous vs nonautonomous cases
macro ctfunction_td_sv(expr)

    #dump(expr)

    if !hasproperty(expr, :head) || expr.head != Symbol(:tuple)
        return :(throw_callable_error())
    end

    function_name = expr.args[1]
    abstract_heritance = expr.args[2]

    esc(quote
        struct $(function_name){time_dependence, scalar_vectorial} <: $(abstract_heritance)
            f::Function
            function $(function_name){time_dependence, scalar_vectorial}(f::Function) where {time_dependence, scalar_vectorial}
                if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
                    error("usage: $(function_name){time_dependence, scalar_vectorial}(fun) " *
                    "with time_dependence ∈ [:autonomous, :nonautonomous]")
                elseif !(scalar_vectorial ∈ [:scalar, :vectorial])
                    error("usage: $(function_name){time_dependence, scalar_vectorial}(fun) " *
                    "with scalar_vectorial ∈ [:scalar, :vectorial]")
                else
                    new{time_dependence, scalar_vectorial}(f)
                end
            end
            function $(function_name){time_dependence}(f::Function) where {time_dependence}
                if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
                    error("usage: $(function_name){time_dependence, scalar_vectorial}(fun) " *
                    "with time_dependence ∈ [:autonomous, :nonautonomous]")
                else
                    new{time_dependence, _fun_scalar_vectorial()}(f)
                end
            end
            $(function_name)(f::Function) = new{_fun_time_dependence(), _fun_scalar_vectorial()}(f)
        end
        # basic usage
        function (F::$(function_name))(args...; kwargs...)
            return F.f(args...; kwargs...)
        end
        # handling time dependence
        function (F::$(function_name){time_dependence, scalar_vectorial})(t::Time, args...; kwargs...) where {time_dependence, scalar_vectorial}
            return time_dependence==:autonomous ? F.f(args...; kwargs...) : F.f(t, args...; kwargs...)
        end
    end)
end

#
macro ctfunction_sv(expr)

    #dump(expr)

    if !hasproperty(expr, :head) || expr.head != Symbol(:tuple)
        return :(throw_callable_error())
    end

    function_name = expr.args[1]
    abstract_heritance = expr.args[2]

    esc(quote
        struct $(function_name){scalar_vectorial} <: $(abstract_heritance)
            f::Function
            function $(function_name){scalar_vectorial}(f::Function) where {scalar_vectorial}
                if !(scalar_vectorial ∈ [:scalar, :vectorial]) 
                    error("usage: $(function_name){scalar_vectorial}(fun) " *
                    "with scalar_vectorial ∈ [:scalar, :vectorial]")
                else
                    new{scalar_vectorial}(f)
                end
            end
            $(function_name)(f::Function) = new{_fun_scalar_vectorial()}(f)
        end
        # basic usage
        function (F::$(function_name))(args...; kwargs...)
            return F.f(args...; kwargs...)
        end
    end)
end