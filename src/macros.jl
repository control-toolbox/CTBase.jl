# generate callable structure with the managing of autonomous vs nonautonomous cases
macro ctfunction_td_sv(expr)

    #dump(expr)

    if !hasproperty(expr, :head) || expr.head != Symbol(:tuple)
        return :(throw_callable_error())
    end

    function_name = expr.args[1]
    abstract_heritance = expr.args[2]

    esc(quote
        struct $(function_name){time_dependence, dimension_usage} <: $(abstract_heritance)
            f::Function
            function $(function_name){time_dependence, dimension_usage}(f::Function) where {time_dependence, dimension_usage}
                if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
                    error("usage: $(function_name){time_dependence, dimension_usage}(fun) " *
                    "with time_dependence ∈ [:autonomous, :nonautonomous]")
                elseif !(dimension_usage ∈ [:scalar, :vectorial])
                    error("usage: $(function_name){time_dependence, dimension_usage}(fun) " *
                    "with dimension_usage ∈ [:scalar, :vectorial]")
                else
                    new{time_dependence, dimension_usage}(f)
                end
            end
            function $(function_name){time_dependence}(f::Function) where {time_dependence}
                if !(time_dependence ∈ [:autonomous, :nonautonomous]) 
                    error("usage: $(function_name){time_dependence, dimension_usage}(fun) " *
                    "with time_dependence ∈ [:autonomous, :nonautonomous]")
                else
                    new{time_dependence, _fun_dimension_usage()}(f)
                end
            end
            $(function_name)(f::Function) = new{_fun_time_dependence(), _fun_dimension_usage()}(f)
        end
        # basic usage
        function (F::$(function_name))(args...; kwargs...)
            return F.f(args...; kwargs...)
        end
        # handling time dependence
        function (F::$(function_name){time_dependence, dimension_usage})(t::Time, args...; kwargs...) where {time_dependence, dimension_usage}
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
        struct $(function_name){dimension_usage} <: $(abstract_heritance)
            f::Function
            function $(function_name){dimension_usage}(f::Function) where {dimension_usage}
                if !(dimension_usage ∈ [:scalar, :vectorial]) 
                    error("usage: $(function_name){dimension_usage}(fun) " *
                    "with dimension_usage ∈ [:scalar, :vectorial]")
                else
                    new{dimension_usage}(f)
                end
            end
            $(function_name)(f::Function) = new{_fun_dimension_usage()}(f)
        end
        # basic usage
        function (F::$(function_name))(args...; kwargs...)
            return F.f(args...; kwargs...)
        end
    end)
end