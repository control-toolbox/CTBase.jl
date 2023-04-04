"""
$(TYPEDSIGNATURES)

Generate callable types, that is functions, handling the time dependence and the dimension usages.
"""
macro ctfunction_td_sv(expr)

    #dump(expr)

    if !hasproperty(expr, :head) || expr.head != Symbol(:tuple)
        return :(throw_callable_error())
    end

    function_name = expr.args[1]
    abstract_heritance = expr.args[2]

    esc(quote
        """
        $(TYPEDEF)

        **Fields**

        $(TYPEDFIELDS)

        **Constructors**
        ```julia
        $(function_name){time_dependence, dimension_usage}(f::Function) where {time_dependence, dimension_usage}
        $(function_name){time_dependence}(f::Function) where {time_dependence}
        $(function_name)(f::Function)
        ```

        !!! warning

            - The parameter `time_dependence` can be `:autonomous` or `:nonautonomous`.
            - The parameter `dimension_usage` can be `:scalar` or `:vectorial`.
        """
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
                    new{time_dependence, __fun_dimension_usage()}(f)
                end
            end
            $(function_name)(f::Function) = new{__fun_time_dependence(), __fun_dimension_usage()}(f)
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

"""
$(TYPEDSIGNATURES)

Generate callable types, that is functions, handling the dimension usage.

**Note:** This macro is used to generate callable types for functions that are not time dependent.
If the function is time dependent, use the macro `@ctfunction_td_sv` instead.
"""
macro ctfunction_sv(expr)

    #dump(expr)

    if !hasproperty(expr, :head) || expr.head != Symbol(:tuple)
        return :(throw_callable_error())
    end

    function_name = expr.args[1]
    abstract_heritance = expr.args[2]

    esc(quote
        """
        $(TYPEDEF)

        **Fields**

        $(TYPEDFIELDS)

        **Constructors**
        ```julia
        $(function_name){dimension_usage}(f::Function) where {dimension_usage}
        $(function_name)(f::Function)
        ```

        !!! warning

            The parameter `dimension_usage` can be `:scalar` or `:vectorial`.
        """
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
            $(function_name)(f::Function) = new{__fun_dimension_usage()}(f)
        end
        # basic usage
        function (F::$(function_name))(args...; kwargs...)
            return F.f(args...; kwargs...)
        end
    end)
end

# -------------------------------------------------------------------------------------------
# Functions

# -------------------------------------------------------------------------------------------
"""
$(TYPEDEF)

Abstract type for functions.
"""
abstract type AbstractCTFunction <: Function end

#
const abstract_heritance=:AbstractCTFunction

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:BoundaryConstraintFunction
#
@eval @ctfunction_sv $(function_name), $(abstract_heritance)
# handling scalar / vectorial usage
# output: vectorial
@eval begin
    function (F::$(function_name){dimension_usage})(t0::Time, 
        x0::State, tf::Time, xf::State, args...; kwargs...) where {dimension_usage}
        x_ = (dimension_usage==:scalar && length(x0)==1) ? (t0, x0[1], tf, xf[1]) : (t0, x0, tf, xf)
        y = F.f(x_..., args...; kwargs...)
        if dimension_usage==:scalar && !(y isa MyNumber) && length(y)==1
            throw(IncorrectOutput("A boundary constraint must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa MyNumber ? [y] : y
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
function_name=:MayerFunction
#
@eval @ctfunction_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: scalar
@eval begin
    function (F::$(function_name){dimension_usage})(t0::Time, 
        x0::State, tf::Time, xf::State, args...; kwargs...) where {dimension_usage}
        x_ = (dimension_usage==:scalar && length(x0)==1) ? (t0, x0[1], tf, xf[1]) : (t0, x0, tf, xf)
        y = F.f(x_..., args...; kwargs...)
        if !(y isa MyNumber)
            throw(IncorrectOutput("A Mayer cost must return a Real (scalar)."))
        end
        return y
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
function_name=:Hamiltonian
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: scalar
@eval begin
    function (F::$(function_name){time_dependence, dimension_usage})(t::Time, 
        x::State, p::Adjoint, args...; kwargs...) where {time_dependence, dimension_usage}
        args_ = time_dependence==:autonomous ? () : (t, )
        if dimension_usage==:scalar && length(x)==1
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
end

# -------------------------------------------------------------------------------------------
#
function_name=:HamiltonianVectorField
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
@eval begin
    function (F::$(function_name){time_dependence, dimension_usage})(t::Time, x::State, p::Adjoint, args...; kwargs...) where {time_dependence, dimension_usage}
        args_ = time_dependence==:autonomous ? () : (t, )
        if dimension_usage==:scalar && length(x)==1
            args_ = (args_..., x[1], p[1])
        else
            args_ = (args_..., x, p)
        end
        return F.f(args_..., args...; kwargs...)
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if scalar usage and scalar as input
function_name=:VectorField
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval begin
    function (F::$(function_name){time_dependence, dimension_usage})(t::Time, 
        x::State, args...; kwargs...) where {time_dependence, dimension_usage}
        args_ = time_dependence==:autonomous ? () : (t, )
        if dimension_usage==:scalar && length(x)==1
            args_ = (args_..., x[1])
        else
            args_ = (args_..., x)
        end
        y = F.f(args_..., args...; kwargs...)
        if dimension_usage==:scalar && length(x)==1
            if !(y isa MyNumber)
                throw(IncorrectOutput("A VectorField function must return a Real (scalar)" *
                " if the input and usage are scalar."))
            end
            return [y]
        else
            return y
        end
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
function_name=:LagrangeFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: scalar
@eval begin
    function (F::$(function_name){time_dependence, dimension_usage})(t::Time, 
        x::State, u::Control, args...; kwargs...) where {time_dependence, dimension_usage}
        t_ = time_dependence==:autonomous ? () : (t, )
        x_ = (dimension_usage==:scalar && length(x)==1) ? (x[1], ) : (x, )
        u_ = (dimension_usage==:scalar && length(u)==1) ? (u[1], ) : (u, )
        y = F.f(t_..., x_..., u_..., args...; kwargs...)
        if !(y isa MyNumber)
            throw(IncorrectOutput("A Lagrange cost must return a Real (scalar)."))
        end
        return y
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if scalar usage and x scalar as input
function_name=:DynamicsFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval begin
     function (F::$(function_name){time_dependence, dimension_usage})(t::Time, 
        x::State, u::Control, args...; kwargs...) where {time_dependence, dimension_usage}
        t_ = time_dependence==:autonomous ? () : (t, )
        x_ = (dimension_usage==:scalar && length(x)==1) ? (x[1], ) : (x, )
        u_ = (dimension_usage==:scalar && length(u)==1) ? (u[1], ) : (u, )
        y = F.f(t_..., x_..., u_..., args...; kwargs...)
        if dimension_usage==:scalar && length(x)==1
            if !(y isa MyNumber)
                throw(IncorrectOutput("A Dynamics function must return a Real (scalar)" *
                " if the input x and the usage are scalar."))
            end
            return [y]
        else
            return y
        end
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:StateConstraintFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval begin
    function (F::$(function_name){time_dependence, dimension_usage})(t::Time, x::State, args...; kwargs...) where {time_dependence, dimension_usage}
        t_ = time_dependence==:autonomous ? () : (t, )
        x_ = (dimension_usage==:scalar && length(x)==1) ? (x[1], ) : (x, )
        y = F.f(t_..., x_..., args...; kwargs...)
        if dimension_usage==:scalar && !(y isa MyNumber) && length(y)==1
            throw(IncorrectOutput("A state constraint must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa MyNumber ? [y] : y
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:ControlConstraintFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval begin 
    function (F::$(function_name){time_dependence, dimension_usage})(t::Time, u::Control, args...; kwargs...) where {time_dependence, dimension_usage}
        t_ = time_dependence==:autonomous ? () : (t, )
        u_ = (dimension_usage==:scalar && length(u)==1) ? (u[1], ) : (u, )
        y = F.f(t_..., u_..., args...; kwargs...)
        if dimension_usage==:scalar && !(y isa MyNumber) && length(y)==1
            throw(IncorrectOutput("A control constraint must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa MyNumber ? [y] : y
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:MixedConstraintFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval begin 
    function (F::$(function_name){time_dependence, dimension_usage})(t::Time, x::State, u::Control, args...; kwargs...) where {time_dependence, dimension_usage}
        t_ = time_dependence==:autonomous ? () : (t, )
        x_ = (dimension_usage==:scalar && length(x)==1) ? (x[1], ) : (x, )
        u_ = (dimension_usage==:scalar && length(u)==1) ? (u[1], ) : (u, )
        y = F.f(t_..., x_..., u_..., args...; kwargs...)
        if dimension_usage==:scalar && !(y isa MyNumber) && length(y)==1
            throw(IncorrectOutput("A mixed state/control constraint must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa MyNumber ? [y] : y
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:ControlFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval begin 
    function (F::$(function_name){time_dependence, dimension_usage})(t::Time, 
        x::State, p::Adjoint, args...; kwargs...) where {time_dependence, dimension_usage}
        args_ = time_dependence==:autonomous ? () : (t, )
        if dimension_usage==:scalar && length(x)==1
            args_ = (args_..., x[1], p[1])
        else
            args_ = (args_..., x, p)
        end
        y = F.f(args_..., args...; kwargs...)
        if dimension_usage==:scalar && !(y isa MyNumber) && length(y)==1
            throw(IncorrectOutput("A control function must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa MyNumber ? [y] : y
    end
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar is scalar usage and one dimensional output
function_name=:MultiplierFunction
#
@eval @ctfunction_td_sv $(function_name), $(abstract_heritance)
# handling time dependence and scalar / vectorial usage
# output: vectorial
@eval begin 
    function (F::$(function_name){time_dependence, dimension_usage})(t::Time, 
        x::State, p::Adjoint, args...; kwargs...) where {time_dependence, dimension_usage}
        args_ = time_dependence==:autonomous ? () : (t, )
        if dimension_usage==:scalar && length(x)==1
            args_ = (args_..., x[1], p[1])
        else
            args_ = (args_..., x, p)
        end
        y = F.f(args_..., args...; kwargs...)
        if dimension_usage==:scalar && !(y isa MyNumber) && length(y)==1
            throw(IncorrectOutput("A multiplier function must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa MyNumber ? [y] : y
    end
end
