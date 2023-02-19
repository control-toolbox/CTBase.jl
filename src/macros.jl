# exception thrower
function throw_callable_error( msg = nothing )
    if isnothing(msg)
        throw(error("@callable input is incorrect, expected a struct"))
    else
        throw(error("@callable input is incorrect: ", msg))
    end
end

macro callable(expr)

#=      @show(expr)
    println("---")
    println(expr)
    println("---")
    println(typeof(expr))
    println("---")
    println(Meta.show_sexpr(expr))
    println("---")
    println(expr.head)
    println("---")
    println(expr.args[1])
    println("---")
    println(expr.args[2])
    println("---")
    println(expr.args[3])
    println("==================================================") =#

    #dump(expr)

    # first elements must be :struct
    if !hasproperty(expr, :head) || expr.head != Symbol(:struct)
        return :(throw_callable_error())
    end

    #
    corps = expr.args[3]

    # parametric struct or not
    curly=false
    if hasproperty(expr.args[2], :head) && expr.args[2].head == Symbol(:curly)
        struct_name = expr.args[2].args[1]
        struct_params = expr.args[2].args[2:end]
        curly=true
    else
        struct_name = expr.args[2]
        struct_params = ""
    end
    #println(struct_name)
    #println(struct_params)

    fun = gensym("fun")

    if curly
        esc(quote
            struct $struct_name{$(struct_params...)}
                $fun::Function
                $corps
                #function $struct_name{$(struct_params...)}(caller::Function, args...) where {$(struct_params...)}
                #    new{$(struct_params...)}(caller, args...)
                #end
                #function $struct_name{$(struct_params...)}(args...; caller::Function) where {$(struct_params...)}
                #    new{$(struct_params...)}(caller, args...)
                #end
            end
            (s::$struct_name{$(struct_params...)})(args...; kwargs...) where {$(struct_params...)} = s.$fun(args...; kwargs...)
        end)
    else
        esc(quote
            struct $struct_name
                $fun::Function
                $corps
                #function $struct_name(caller::Function, args...)
                #    new(caller, args...)
                #end
                #function $struct_name(args...; caller::Function)
                #    new(caller, args...)
                #end
            end
            (s::$struct_name)(args...; kwargs...) = s.$fun(args...; kwargs...)
        end)
    end
end


# generate callable structure with the managing of autonomous vs nonautonomous cases
macro time_dependence_function(expr)

    #dump(expr)

    if !hasproperty(expr, :head) || expr.head != Symbol(:tuple)
        return :(throw_callable_error())
    end

    function_name = expr.args[1]
    abstract_name = Symbol(:Abstract, function_name)
    abstract_heritance = expr.args[2]

    esc(quote
        struct $(function_name){time_dependence} <: $(abstract_heritance){time_dependence}
            f::Function
            function $(function_name){time_dependence}(f::Function) where {time_dependence}
                if !(time_dependence ∈ [:autonomous, :nonautonomous])
                    error("the function must be :autonomous or :nonautonomous")
                else
                    new{time_dependence}(f)
                end
            end
            $(function_name)(f::Function) = new{:autonomous}(f)
        end
        function (F::$(function_name){time_dependence})(t, args...; kwargs...) where {time_dependence}
            return time_dependence==:autonomous ? F.f(args...; kwargs...) : F.f(t, args...; kwargs...)
        end
    end)

end