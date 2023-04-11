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
# pre-condition: f returns a scalar if the output is of dimension 1
"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

**Example**

```@example
julia> B = $(FUNCTIONNAME)((t0, x0, tf, xf) -> xf - x0, state_dimension=1, constraint_dimension=1)
julia> B(0, 0, 1, 1)
1
julia> B(0, [0], 1, [1])
[1]
julia> B = $(FUNCTIONNAME)((t0, x0, tf, xf) -> [xf - x0, t0 - tf], state_dimension=1, constraint_dimension=2)
julia> B(0, 0, 1, 1)
 [1, -1]
julia> B(0, [0], 1, [1])
[1, -1]
julia> B = $(FUNCTIONNAME)((t0, x0, tf, xf) -> tf - t0, state_dimension=2, constraint_dimension=1)
julia> B(0, [1, 0], 1, [0, 1])
[1]
julia> B = $(FUNCTIONNAME)((t0, x0, tf, xf) -> [tf - t0, xf[1] - x0[2]], state_dimension=2, constraint_dimension=2)
julia> B(0, [1, 0], 1, [1, 0])
[1, 1]
julia> B = $(FUNCTIONNAME)((t0, x0, tf, xf) -> xf - x0)
julia> B(0, 0, 1, 1)
1
julia> B = $(FUNCTIONNAME)((t0, x0, tf, xf) -> [xf - x0, t0 - tf])
julia> B(0, 0, 1, 1)
[1, -1]
julia> B = $(FUNCTIONNAME)((t0, x0, tf, xf) -> xf[2] - x0[1])
julia> B(0, [1, 0], 1, [0, 1])
0
```
"""
struct BoundaryConstraintFunction{dim_x, dim_y}
    f::Function
    function BoundaryConstraintFunction(f::Function; state_dimension::Dimension=0, constraint_dimension::Dimension=0)
        new{state_dimension, constraint_dimension}(f)   # in the case of one dimension is 0, the user must be coherent
                                                        # that is one dimensional means scalar
    end
end
function (F::BoundaryConstraintFunction{1, 1})(t0::Time, x0::State, tf::Time, xf::State, args...; kwargs...)
    return [F.f(t0, x0[1], tf, xf[1], args...; kwargs...)]
end
function (F::BoundaryConstraintFunction{1, N})(t0::Time, x0::State, tf::Time, xf::State, args...; kwargs...) where {N}
    return F.f(t0, x0[1], tf, xf[1], args...; kwargs...)
end
function (F::BoundaryConstraintFunction{N, 1})(t0::Time, x0::State, tf::Time, xf::State, args...; kwargs...) where {N}
    return [F.f(t0, x0, tf, xf, args...; kwargs...)]
end
function (F::BoundaryConstraintFunction{N, M})(t0::Time, x0::State, tf::Time, xf::State, args...; kwargs...) where {N, M}
    return F.f(t0, x0, tf, xf, args...; kwargs...)
end
function (F::BoundaryConstraintFunction{N, M})(args...; kwargs...) where {N, M}
    return F.f(args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

**Example**

```@example
julia> G = $(FUNCTIONNAME){1}((t0, x0, tf, xf) -> xf - x0)
julia> G(0, 0, 1, 1)
1
julia> G(0, [0], 1, [1])
1
julia> G = $(FUNCTIONNAME){2}((t0, x0, tf, xf) -> xf[2] - x0[1])
julia> G(0, [1, 0], 1, [0, 1])
0
```
"""
struct MayerFunction{dim_x}
    f::Function
    function MayerFunction{dim_x}(f::Function) where {dim_x}
        if !(dim_x isa Integer)
            error("usage: MayerFunction{dim_x}(fun) with dim_x ∈ ℕ")
        else
            new{dim_x}(f)
        end
    end
end
function (F::MayerFunction{1})(t0::Time, x0::State, tf::Time, xf::State, args...; kwargs...)
    return F.f(t0, x0[1], tf, xf[1], args...; kwargs...)
end
function (F::MayerFunction{N})(t0::Time, x0::State, tf::Time, xf::State, args...; kwargs...) where {N}
    return F.f(t0, x0, tf, xf, args...; kwargs...)
end
function (F::MayerFunction{N})(args...; kwargs...) where {N}
    return F.f(args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

**Example**

```@example
julia> H = $(FUNCTIONNAME){:autonomous, 1}((x, p) -> p^2/2 - x)
julia> H(0, 1)
1/2
julia> H(0, [0], [1])
1/2
julia> H = $(FUNCTIONNAME){:nonautonomous, 1}((t, x, p) -> t + p^2/2 - x)
julia> H(1, 0, 1)
3/2
julia> H(1, [0], [1])
3/2
julia> H = $(FUNCTIONNAME){:autonomous, 2}((x, p) -> p[1]^2/2 - x[1] + p[2]^2/2 - x[2])
julia> H([0, 0], [1, 1])
1
julia> H = $(FUNCTIONNAME){:nonautonomous, 2}((t, x, p) -> t + p[1]^2/2 - x[1] + p[2]^2/2 - x[2])
julia> H(1, [0, 0], [1, 1])
2
```
"""
struct Hamiltonian{time_dependence, dim_x}
    f::Function
    function Hamiltonian{time_dependence, dim_x}(f::Function) where {time_dependence, dim_x}
        if !(time_dependence isa Symbol) || !(dim_x isa Integer)
            error("usage: Hamiltonian{time_dependence, dim_x}(fun) with time_dependence ∈ (:autonomous, :nonautonomous) and dim_x ∈ ℕ")
        else
            new{time_dependence, dim_x}(f)
        end
    end
end
function (F::Hamiltonian{:autonomous, 1})(t::Time, x::State, p::Adjoint, args...; kwargs...)
    return F.f(x[1], p[1], args...; kwargs...)
end
function (F::Hamiltonian{:autonomous, N})(t::Time, x::State, p::Adjoint, args...; kwargs...) where {N}
    return F.f(x, p, args...; kwargs...)
end
function (F::Hamiltonian{:nonautonomous, 1})(t::Time, x::State, p::Adjoint, args...; kwargs...)
    return F.f(t, x[1], p[1], args...; kwargs...)
end
function (F::Hamiltonian{:nonautonomous, N})(t::Time, x::State, p::Adjoint, args...; kwargs...) where {N}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::Hamiltonian{time_dependence, N})(args...; kwargs...) where {time_dependence, N}
    return F.f(args...; kwargs...)
end

#-------------------------------------------------------------------------------------------
# pre-condition: no
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

**Example**

```@example
julia> Hv = $(FUNCTIONNAME){:autonomous, 1}((x, p) -> [p^2/2 - x, p^2/2 + x])
julia> Hv(0, 1)
2-element Array{Float64,1}:
  0.5
  0.5
julia> Hv(0, [0], [1])
2-element Array{Float64,1}:
  0.5
  0.5
julia> Hv = $(FUNCTIONNAME){:nonautonomous, 1}((t, x, p) -> [t + p^2/2 - x, t + p^2/2 + x])
julia> Hv(1, 0, 1)
2-element Array{Float64,1}:
 1.5
 1.5
julia> Hv(1, [0], [1])
2-element Array{Float64,1}:
 1.5
 1.5
julia> Hv = $(FUNCTIONNAME){:autonomous, 2}((x, p) -> [p[1]^2/2 - x[1] + p[2]^2/2 - x[2], p[1]^2/2 + x[1] + p[2]^2/2 + x[2]])
julia> Hv([0, 0], [1, 1])
2-element Array{Float64,1}:
 1.0
 1.0
julia> Hv = $(FUNCTIONNAME){:nonautonomous, 2}((t, x, p) -> [t + p[1]^2/2 - x[1] + p[2]^2/2 - x[2], t + p[1]^2/2 + x[1] + p[2]^2/2 + x[2]])
julia> Hv(1, [0, 0], [1, 1])
2-element Array{Float64,1}:
 2.0
 2.0
```
"""
struct HamiltonianVectorField{time_dependence, dim_x}
    f::Function
    function HamiltonianVectorField{time_dependence, dim_x}(f::Function) where {time_dependence, dim_x}
        if !(time_dependence isa Symbol) || !(dim_x isa Integer)
            error("usage: HamiltonianVectorField{time_dependence, dim_x}(fun) with time_dependence ∈ (:autonomous, :nonautonomous) and dim_x ∈ ℕ")
        else
            new{time_dependence, dim_x}(f)
        end
    end
end
function (F::HamiltonianVectorField{:autonomous, 1})(t::Time, x::State, p::Adjoint, args...; kwargs...)
    return F.f(x[1], p[1], args...; kwargs...)
end
function (F::HamiltonianVectorField{:autonomous, N})(t::Time, x::State, p::Adjoint, args...; kwargs...) where {N}
    return F.f(x, p, args...; kwargs...)
end
function (F::HamiltonianVectorField{:nonautonomous, 1})(t::Time, x::State, p::Adjoint, args...; kwargs...)
    return F.f(t, x[1], p[1], args...; kwargs...)
end
function (F::HamiltonianVectorField{:nonautonomous, N})(t::Time, x::State, p::Adjoint, args...; kwargs...) where {N}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::HamiltonianVectorField{time_dependence, N})(args...; kwargs...) where {time_dependence, N}
    return F.f(args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar if x is a scalar



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
