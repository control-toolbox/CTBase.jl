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

!!! warning

    When the state is of dimension 1, consider `x0` and `xf` as a scalar. When the constraint is dimension 1, return a scalar.

**Examples**

## Classical calls

```@example
# state dimension: 1
# constraint dimension: 1
#
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> xf - x0)
julia> B(0, 0, 1, 1)
1
julia> B(0, [0], 1, [1])
1-element Vector{Int64}:
 1

# state dimension: 1
# constraint dimension: 2
#
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> [xf - x0, t0 - tf])
julia> B(0, 0, 1, 1)
2-element Vector{Int64}:
  1
 -1
julia> B(0, [0], 1, [1])
ERROR: MethodError: Cannot `convert` an object of type 
  Vector{Any} to an object of type 
  Union{Real, AbstractVector{<:Real}}

# state dimension: 2
# constraint dimension: 1
#
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> tf - t0)
julia> B(0, [1, 0], 1, [0, 1])
1

# state dimension: 2
# constraint dimension: 2
#
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> [tf - t0, xf[1] - x0[2]])
julia> B(0, [1, 0], 1, [1, 0])
2-element Vector{Int64}:
 1
 1
```

## Specific calls

When giving a _Time for `t0` and `tf`, the function takes a vector as input for `x0` and
`xf` and returns a vector as output.

!!! warning

    To use the specific call, you must construct the function with the keywords `state_dimension` and `constraint_dimension`.

```@example
# state dimension: 1
# constraint dimension: 1
#
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> xf - x0, 
    state_dimension=1, constraint_dimension=1)
julia> B(_Time(0), 0, _Time(1), 1)
ERROR: MethodError: no method matching (::BoundaryConstraint{1, 1})(::_Time, ::Int64, 
::_Time, ::Int64)
julia> B(_Time(0), [0], _Time(1), [1])
1-element Vector{Int64}:
 1

# state dimension: 1
# constraint dimension: 2
#
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> [xf - x0, t0 - tf], 
    state_dimension=1, constraint_dimension=2)
julia> B(_Time(0), 0, _Time(1), 1)
ERROR: MethodError: no method matching (::BoundaryConstraint{1, 2})(::_Time, ::Int64, 
::_Time, ::Int64)
julia> B(_Time(0), [0], _Time(1), [1])
2-element Vector{Int64}:
  1
 -1

# state dimension: 2
# constraint dimension: 1
#
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> tf - t0, 
    state_dimension=2, constraint_dimension=1)
julia> B(_Time(0), [1, 0], _Time(1), [0, 1])
1-element Vector{Int64}:
 1

# state dimension: 2
# constraint dimension: 2
#
julia> B = BoundaryConstraint((t0, x0, tf, xf) -> [tf - t0, xf[1] - x0[2]], 
    state_dimension=2, constraint_dimension=2)
julia> B(_Time(0), [1, 0], _Time(1), [1, 0])
2-element Vector{Int64}:
 1
 1
```
"""
struct BoundaryConstraint{state_dimension, constraint_dimension}
    f::Function
    function BoundaryConstraint(f::Function; state_dimension::Union{Nothing,Dimension}=__fun_dimension(), 
            constraint_dimension::Union{Nothing,Dimension}=__fun_dimension())
        new{state_dimension, constraint_dimension}(f)   # in the case of one dimension is 0, the user must be coherent
                                                        # that is one dimensional input or output must be scalar
    end
end

# classical call
function (F::BoundaryConstraint{N, M})(t0::Time, x0::Union{ctNumber, State}, 
        tf::Time, xf::Union{ctNumber, State}, args...; kwargs...)::Union{ctNumber, ctVector} where {N, M}
    return F.f(t0, x0, tf, xf, args...; kwargs...)
end

# specific calls: inputs and outputs are vectors, except times
function (F::BoundaryConstraint{1, 1})(t0::_Time, x0::State, 
        tf::_Time, xf::State, args...; kwargs...)::ctVector
    return [F.f(t0.value, x0[1], tf.value, xf[1], args...; kwargs...)]
end
function (F::BoundaryConstraint{1, N})(t0::_Time, x0::State, 
        tf::_Time, xf::State, args...; kwargs...)::ctVector where {N}
    return F.f(t0.value, x0[1], tf.value, xf[1], args...; kwargs...)
end
function (F::BoundaryConstraint{N, 1})(t0::_Time, x0::State, 
        tf::_Time, xf::State, args...; kwargs...)::ctVector where {N}
    return [F.f(t0.value, x0, tf.value, xf, args...; kwargs...)]
end
function (F::BoundaryConstraint{N, M})(t0::_Time, x0::State, 
        tf::_Time, xf::State, args...; kwargs...)::ctVector where {N, M}
    return F.f(t0.value, x0, tf.value, xf, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

!!! warning

    When the state is of dimension 1, consider `x0` and `xf` as a scalar.

**Example**

## Classical calls

```@example
# state dimension: 1
#
julia> G = MayerObjective((t0, x0, tf, xf) -> xf - x0)
julia> G(0, 0, 1, 1)
1
julia> G(0, [0], 1, [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real

# state dimension: 2
#
julia> G = MayerObjective((t0, x0, tf, xf) -> tf - t0)
julia> G(0, [1, 0], 1, [0, 1])
1
```

## Specific calls

When giving a _Time for `t0` and `tf`, the function takes a vector as input for `x0` and
`xf`.

!!! warning

    To use the specific call, you must construct the function with the keyword `state_dimension`.

```@example
# state dimension: 1
#
julia> G = MayerObjective((t0, x0, tf, xf) -> xf - x0, state_dimension=1)
julia> G(_Time(0), 0, _Time(1), 1)
ERROR: MethodError: no method matching (::MayerObjective{1})(::CTBase._Time, ::Int64, ::CTBase._Time, ::Int64)
julia> G(_Time(0), [0], _Time(1), [1])
1

# state dimension: 2
#
julia> G = MayerObjective((t0, x0, tf, xf) -> tf - t0, state_dimension=2)
julia> G(_Time(0), [1, 0], _Time(1), [0, 1])
1
```
"""
struct MayerObjective{state_dimension}
    f::Function
    function MayerObjective(f::Function; state_dimension::Union{Nothing,Dimension}=__fun_dimension())
        new{state_dimension}(f)
    end
end

# classical call
function (F::MayerObjective{N})(t0::Time, x0::Union{ctNumber, State}, 
    tf::Time, xf::Union{ctNumber, State}, args...; kwargs...)::ctNumber where {N}
return F.f(t0, x0, tf, xf, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
function (F::MayerObjective{1})(t0::_Time, x0::State, 
        tf::_Time, xf::State, args...; kwargs...)::ctNumber
    return F.f(t0.value, x0[1], tf.value, xf[1], args...; kwargs...)
end
function (F::MayerObjective{N})(t0::_Time, x0::State, 
        tf::_Time, xf::State, args...; kwargs...)::ctNumber where {N}
    return F.f(t0.value, x0, tf.value, xf, args...; kwargs...)
end

# -------------------------------------------------------------------------------------------
# 
#
# c'est bien pour le controle et pour le multiplier mais c'est tout
#
#
# je peux ajouter une paramétrisation pour savoir s'il dépend de x, de x et p
# ou que de p puis toujours pareil si je mets un _Time, on met tout
# sinon on gère en fonction du type. Par défaut: (x, p)
#
# dependence = (:time, :state, :adjoint)
# dependence = (:state, :adjoint)
# dependence = (:adjoint)
#
# est-ce que je garde nonautonomous vs autonomous ou dependence = (:time) ?
#
# pour l'ocp on peut garder puis dépendence pour les fonctions
#


# -------------------------------------------------------------------------------------------
# pre-condition: f returns a scalar
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` is `:autonomous`.

!!! warning

    When the state and adjoint are of dimension 1, consider `x` and `p` as scalars.

**Example**

## Classical calls

```@example
# state dimension: 1
# time dependence: autonomous
#
julia> H = Hamiltonian((x, p) -> x + p)
julia> H(1, 1)
2
julia> H([1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real
julia> H = Hamiltonian((x, p) -> x + p, time_dependence=:autonomous)
julia> H(1, 1)
2
julia> H([1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real

# state dimension: 1
# time dependence: nonautonomous
#
julia> H = Hamiltonian((t, x, p) -> x + p, time_dependence=:nonautonomous)
julia> H(1, 1, 1)
2
julia> H(1, [1], [1])
ERROR: MethodError: Cannot `convert` an object of type Vector{Int64} to an object of type Real

# state dimension: 2
# time dependence: autonomous
#
julia> H = Hamiltonian((x, p) -> x[1]^2 + p[2]^2) # or time_dependence=:autonomous
julia> H([1, 0], [0, 1])
2

# state dimension: 2
# time dependence: nonautonomous
#
julia> H = Hamiltonian((t, x, p) -> t + x[1]^2 + p[2]^2, time_dependence=:nonautonomous)
julia> H(1, [1, 0], [0, 1])
3
```

## Specific calls

When giving a _Time for `t`, the function takes a vector as input for `x` and `p`.

```@example
# state dimension: 1
# time dependence: autonomous
#
julia> H = Hamiltonian((x, p) -> x + p, state_dimension=1)
julia> H(_Time(0), 1, 1)
ERROR: MethodError: no method matching (::Hamiltonian{:autonomous, 1})(::CTBase._Time, ::Int64, ::Int64)
julia> H(_Time(0), [1], [1])
2

# state dimension: 1
# time dependence: nonautonomous
#
julia> H = Hamiltonian((t, x, p) -> t + x + p, state_dimension=1, time_dependence=:nonautonomous)
julia> H(_Time(1), 1, 1)
ERROR: MethodError: no method matching (::Hamiltonian{:nonautonomous, 1})(::CTBase._Time, ::Int64, ::Int64)
julia> H(_Time(1), [1], [1])
3

# state dimension: 2
# time dependence: autonomous
#
julia> H = Hamiltonian((x, p) -> x[1]^2 + p[2]^2, state_dimension=2)
julia> H(_Time(0), [1, 0], [0, 1])
2

# state dimension: 2
# time dependence: nonautonomous
#
julia> H = Hamiltonian((t, x, p) -> t + x[1]^2 + p[2]^2, state_dimension=2, time_dependence=:nonautonomous)
julia> H(_Time(1), [1, 0], [0, 1])
3
```
"""
struct Hamiltonian{time_dependence, state_dimension}
    f::Function
    function Hamiltonian(f::Function; state_dimension::Union{Nothing,Dimension}=__fun_dimension(), 
            time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        new{time_dependence, state_dimension}(f)
    end
end

# classical call
function (F::Hamiltonian{:nonautonomous, N})(t::Time, x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctNumber where {N}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::Hamiltonian{:autonomous, N})(x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctNumber where {N}
    return F.f(x, p, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
# state dimension: 1
function (F::Hamiltonian{:nonautonomous, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber
    return F.f(t.value, x[1], p[1], args...; kwargs...)
end
function (F::Hamiltonian{:autonomous, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber
    return F.f(x[1], p[1], args...; kwargs...)
end
# state dimension: N>1
function (F::Hamiltonian{:nonautonomous, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber where {N}
    return F.f(t.value, x, p, args...; kwargs...)
end
function (F::Hamiltonian{:autonomous, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctNumber where {N}
    return F.f(x, p, args...; kwargs...)
end


#-------------------------------------------------------------------------------------------
# pre-condition: no
"""

$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` is `:autonomous`.

!!! warning

    When the state and adjoint are of dimension 1, consider `x` and `p` as scalars.

**Example**

## Classical calls

```@example
# state dimension: 1
# time dependence: autonomous
#
julia> Hv = HamiltonianVectorField((x, p) -> [x + p, x - p])
julia> Hv(1, 1)
2-element Vector{Int64}:
 2
 0
julia> Hv([1], [1])
ERROR: MethodError: Cannot `convert` an object of type 
  Vector{Vector{Int64}} to an object of type 
  AbstractVector{<:Real}
julia> Hv = HamiltonianVectorField((x, p) -> [x + p, x - p], time_dependence=:autonomous)
julia> Hv(1, 1)
2-element Vector{Int64}:
 2
 0
julia> Hv([1], [1])
ERROR: MethodError: Cannot `convert` an object of type 
  Vector{Vector{Int64}} to an object of type 
  AbstractVector{<:Real}

# state dimension: 1
# time dependence: nonautonomous
#
julia> Hv = HamiltonianVectorField((t, x, p) -> [x + p, x - p], time_dependence=:nonautonomous)
julia> Hv(1, 1, 1)
2-element Vector{Int64}:
 2
 0
julia> Hv(1, [1], [1])
ERROR: MethodError: Cannot `convert` an object of type 
  Vector{Vector{Int64}} to an object of type 
  AbstractVector{<:Real}

# state dimension: 2
# time dependence: autonomous
#
julia> Hv = HamiltonianVectorField((x, p) -> [x[1]^2 + p[2]^2, x[2]^2 - p[1]^2]) # or time_dependence=:autonomous
julia> Hv([1, 0], [0, 1])
2-element Vector{Int64}:
 2
 0

# state dimension: 2
# time dependence: nonautonomous
#
julia> Hv = HamiltonianVectorField((t, x, p) -> [t + x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], time_dependence=:nonautonomous)
julia> Hv(1, [1, 0], [0, 1])
2-element Vector{Int64}:
 3
 0
```

## Specific calls

When giving a _Time for `t`, the function takes a vector as input for `x` and `p`.

```@example
# state dimension: 1
# time dependence: autonomous
#
julia> Hv = HamiltonianVectorField((x, p) -> [x + p, x - p], state_dimension=1)
julia> Hv(_Time(0), 1, 1)
ERROR: MethodError: no method matching (::HamiltonianVectorField{:autonomous, 1})(::CTBase._Time, ::Int64, ::Int64)
julia> Hv(_Time(0), [1], [1])
2-element Vector{Int64}:
 2
 0

# state dimension: 1
# time dependence: nonautonomous
#
julia> Hv = HamiltonianVectorField((t, x, p) -> [t + x + p, x - p], state_dimension=1, time_dependence=:nonautonomous)
julia> Hv(_Time(1), 1, 1)
ERROR: MethodError: no method matching (::HamiltonianVectorField{:nonautonomous, 1})(::CTBase._Time, ::Int64, ::Int64)
julia> Hv(_Time(1), [1], [1])
2-element Vector{Int64}:
 3
 0

# state dimension: 2
# time dependence: autonomous
#
julia> Hv = HamiltonianVectorField((x, p) -> [x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], state_dimension=2)
julia> Hv(_Time(0), [1, 0], [0, 1])
2-element Vector{Int64}:
 2
 0

# state dimension: 2
# time dependence: nonautonomous
#
julia> Hv = HamiltonianVectorField((t, x, p) -> [t + x[1]^2 + p[2]^2, x[2]^2 - p[1]^2], state_dimension=2, time_dependence=:nonautonomous)
julia> Hv(_Time(1), [1, 0], [0, 1])
2-element Vector{Int64}:
 3
 0
```
"""
struct HamiltonianVectorField{time_dependence, state_dimension}
    f::Function
    function HamiltonianVectorField(f::Function; 
            state_dimension::Union{Nothing,Dimension}=__fun_dimension(), 
            time_dependence::Union{Nothing,Symbol}=__fun_time_dependence())
        new{time_dependence, state_dimension}(f)
    end
end

# classical call
function (F::HamiltonianVectorField{:nonautonomous, N})(t::Time, x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctVector where {N}
    return F.f(t, x, p, args...; kwargs...)
end
function (F::HamiltonianVectorField{:autonomous, N})(x::Union{ctNumber, State}, 
        p::Union{ctNumber, Adjoint}, args...; kwargs...)::ctVector where {N}
    return F.f(x, p, args...; kwargs...)
end

# specific calls: inputs are vectors, except times
# state dimension: 1
function (F::HamiltonianVectorField{:nonautonomous, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector
    return F.f(t.value, x[1], p[1], args...; kwargs...)
end
function (F::HamiltonianVectorField{:autonomous, 1})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector
    return F.f(x[1], p[1], args...; kwargs...)
end
# state dimension: N>1
function (F::HamiltonianVectorField{:nonautonomous, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector where {N}
    return F.f(t.value, x, p, args...; kwargs...)
end
function (F::HamiltonianVectorField{:autonomous, N})(t::_Time, x::State, p::Adjoint, args...; kwargs...)::ctVector where {N}
    return F.f(x, p, args...; kwargs...)
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
            if !(y isa ctNumber)
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
        if !(y isa ctNumber)
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
            if !(y isa ctNumber)
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
        if dimension_usage==:scalar && !(y isa ctNumber) && length(y)==1
            throw(IncorrectOutput("A state constraint must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa ctNumber ? [y] : y
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
        if dimension_usage==:scalar && !(y isa ctNumber) && length(y)==1
            throw(IncorrectOutput("A control constraint must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa ctNumber ? [y] : y
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
        if dimension_usage==:scalar && !(y isa ctNumber) && length(y)==1
            throw(IncorrectOutput("A mixed state/control constraint must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa ctNumber ? [y] : y
    end
end

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
        if dimension_usage==:scalar && !(y isa ctNumber) && length(y)==1
            throw(IncorrectOutput("A control function must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa ctNumber ? [y] : y
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
        if dimension_usage==:scalar && !(y isa ctNumber) && length(y)==1
            throw(IncorrectOutput("A multiplier function must return a Real (scalar)" *
            " if the output and usage are scalar."))
        end
        return y isa ctNumber ? [y] : y
    end
end
