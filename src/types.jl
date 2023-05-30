# --------------------------------------------------------------------------------------------------
# functions
#
"""
$(TYPEDEF)

Abstract type for functions.
"""
abstract type AbstractCTFunction <: Function end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `variable_dependence` is `Fixed`.

!!! warning

    When the state is of dimension 1, consider `x0` and `xf` as a scalar. When the constraint is dimension 1, return a scalar.

## Examples

```@example
julia> B = BoundaryConstraint((x0, xf) -> [xf[2]-x0[1], 2xf[1]+x0[2]^2]) # variable=false by default
julia> B([0, 0], [1, 1])
[1, 2]
julia> B([0, 0], [1, 1], [])
[1, 2]
julia> B = BoundaryConstraint((x0, xf, v) -> [v[3]+xf[2]-x0[1], v[1]-v[2]+2xf[1]+x0[2]^2], variable=true)
julia> B([0, 0], [1, 1], [1, 2, 3])
[4, 1]
```
"""
struct BoundaryConstraint{variable_dependence}
    f::Function
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `variable_dependence` is `Fixed`.

!!! warning

    When the state is of dimension 1, consider `x0` and `xf` as a scalar.

## Examples

```@example
julia> G = Mayer((x0, xf) -> [xf[2]-x0[1]]) # variable=false by default
julia> G([0, 0], [1, 1])
MethodError
julia> G = Mayer((x0, xf) -> xf[2]-x0[1])
julia> G([0, 0], [1, 1])
1
julia> G([0, 0], [1, 1], [])
1
julia> G = Mayer((x0, xf, v) -> v[3]+xf[2]-x0[1], variable=true)
julia> G([0, 0], [1, 1], [1, 2, 3])
4
```
"""
struct Mayer{variable_dependence}
    f::Function
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

!!! warning

    When the state and costate are of dimension 1, consider `x` and `p` as scalars.

## Examples

```@example
julia> Hamiltonian((x, p) -> x + p, Int64)
IncorrectArgument 
julia> Hamiltonian((x, p) -> x + p, Int64)
IncorrectArgument
julia> H = Hamiltonian((x, p) -> [x[1]^2+2p[2]]) # autonomous=true, variable=false
julia> H([1, 0], [0, 1])
MethodError # H must return a scalar
julia> H = Hamiltonian((x, p) -> x[1]^2+2p[2])
julia> H([1, 0], [0, 1])
3
julia> t = 1
julia> v = []
julia> H(t, [1, 0], [0, 1])
MethodError
julia> H([1, 0], [0, 1], v)
MethodError 
julia> H(t, [1, 0], [0, 1], v)
3
julia> H = Hamiltonian((x, p, v) -> [x[1]^2+2p[2]+v[3]], variable=true)
julia> H([1, 0], [0, 1], [1, 2, 3])
6
julia> H(t, [1, 0], [0, 1], [1, 2, 3])
6
julia> H = Hamiltonian((t, x, p) -> [t+x[1]^2+2p[2]], autonomous=false)
julia> H(1, [1, 0], [0, 1])
4
julia> H(1, [1, 0], [0, 1], v)
4
julia> H = Hamiltonian((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3]], autonomous=false, variable=true)
julia> H(1, [1, 0], [0, 1], [1, 2, 3])
7
```
"""
struct Hamiltonian{time_dependence, variable_dependence}
    f::Function
end


"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default values for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

!!! warning

    When the state and costate are of dimension 1, consider `x` and `p` as scalars.

## Examples

```@example
julia> HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2], Int64)
IncorrectArgument
julia> HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2], Int64)
IncorrectArgument
julia> Hv = HamiltonianVectorField((x, p) -> [x[1]^2+2p[2], x[2]-3p[2]^2]) # autonomous=true, variable=false
julia> Hv([1, 0], [0, 1])
[3, -3]
julia> t = 1
julia> v = []
julia> Hv(t, [1, 0], [0, 1])
MethodError
julia> Hv([1, 0], [0, 1], v)
MethodError
julia> Hv(t, [1, 0], [0, 1], v)
[3, -3]
julia> Hv = HamiltonianVectorField((x, p, v) -> [x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], variable=true)
julia> Hv([1, 0], [0, 1], [1, 2, 3, 4])
[6, -3]
julia> Hv(t, [1, 0], [0, 1], [1, 2, 3, 4])
[6, -3]
julia> Hv = HamiltonianVectorField((t, x, p) -> [t+x[1]^2+2p[2], x[2]-3p[2]^2], autonomous=false)
julia> Hv(1, [1, 0], [0, 1])
[4, -3]
julia> Hv(1, [1, 0], [0, 1], v)
[4, -3]
julia> Hv = HamiltonianVectorField((t, x, p, v) -> [t+x[1]^2+2p[2]+v[3], x[2]-3p[2]^2+v[4]], autonomous=false, variable=true)
julia> Hv(1, [1, 0], [0, 1], [1, 2, 3, 4])
[7, -3]
```
"""
struct HamiltonianVectorField{time_dependence, variable_dependence}
    f::Function
end


"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

!!! warning

    When the state is of dimension 1, consider `x` as a scalar.

## Examples

```@example
julia> VectorField(x -> [x[1]^2, 2x[2]], Int64)
IncorrectArgument
julia> VectorField(x -> [x[1]^2, 2x[2]], Int64)
IncorrectArgument
julia> V = VectorField(x -> [x[1]^2, 2x[2]]) # autonomous=true, variable=false
julia> V([1, -1])
[1, -2]
julia> t = 1
julia> v = []
julia> V(t, [1, -1])
MethodError
julia> V([1, -1], v)
MethodError
julia> V(t, [1, -1], v)
[1, -2]
julia> V = VectorField((x, v) -> [x[1]^2, 2x[2]+v[3]], variable=true)
julia> V([1, -1], [1, 2, 3])
[1, 1]
julia> V(t, [1, -1], [1, 2, 3])
[1, 1]
julia> V = VectorField((t, x) -> [t+x[1]^2, 2x[2]], autonomous=false)
julia> V(1, [1, -1])
[2, -2]
julia> V(1, [1, -1], v)
[2, -2]
julia> V = VectorField((t, x, v) -> [t+x[1]^2, 2x[2]+v[3]], autonomous=false, variable=true)
julia> V(1, [1, -1], [1, 2, 3])
[2, 1]
```
"""
struct VectorField{time_dependence, variable_dependence}
    f::Function
end


"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

The default value for `time_dependence` and `variable_dependence` are `Autonomous` and `Fixed` respectively.

!!! warning

    When the state is of dimension 1, consider `x` as a scalar. Same for the control.

## Examples

```@example
julia> Lagrange((x, u) -> 2x[2]-u[1]^2, Int64)
IncorrectArgument
julia> Lagrange((x, u) -> 2x[2]-u[1]^2, Int64)
IncorrectArgument
julia> L = Lagrange((x, u) -> [2x[2]-u[1]^2], autonomous=true, variable=false)
julia> L([1, 0], [1])
MethodError
julia> L = Lagrange((x, u) -> 2x[2]-u[1]^2, autonomous=true, variable=false)
julia> L([1, 0], [1])
-1
julia> t = 1
julia> v = []
julia> L(t, [1, 0], [1])
MethodError
julia> L([1, 0], [1], v)
MethodError
julia> L(t, [1, 0], [1], v)
-1
julia> L = Lagrange((x, u, v) -> 2x[2]-u[1]^2+v[3], autonomous=true, variable=true)
julia> L([1, 0], [1], [1, 2, 3])
2
julia> L(t, [1, 0], [1], [1, 2, 3])
2
julia> L = Lagrange((t, x, u) -> t+2x[2]-u[1]^2, autonomous=false, variable=false)
julia> L(1, [1, 0], [1])
0
julia> L(1, [1, 0], [1], v)
0
julia> L = Lagrange((t, x, u, v) -> t+2x[2]-u[1]^2+v[3], autonomous=false, variable=true)
julia> L(1, [1, 0], [1], [1, 2, 3])
3
```
"""
struct Lagrange{time_dependence, variable_dependence}
    f::Function
end


"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `Lagrange`, but the function `f` is assumed to return a vector of the same dimension as the state `x`.

"""
struct Dynamics{time_dependence, variable_dependence}
    f::Function
end


"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `VectorField` in the usage, but the dimension of the output of the function `f` is arbitrary.

"""
struct StateConstraint{time_dependence, variable_dependence}
    f::Function
end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `VectorField` in the usage, but the dimension of the output of the function `f` is arbitrary.

"""
struct ControlConstraint{time_dependence, variable_dependence}
    f::Function
end


"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `Lagrange` in the usage, but the dimension of the output of the function `f` is arbitrary.

"""
struct MixedConstraint{time_dependence, variable_dependence}
    f::Function
end


"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

!!! warning

    When the variable is of dimension 1, consider `v` as a scalar.

"""
struct VariableConstraint
    f::Function
end


"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `VectorField` in the usage, but the dimension of the output of the function `f` is arbitrary.

"""
struct FeedbackControl{time_dependence, variable_dependence}
    f::Function
end


"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `Hamiltonian` in the usage, but the dimension of the output of the function `f` is arbitrary.

"""
struct ControlLaw{time_dependence, variable_dependence}
    f::Function
end


"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)

Similar to `ControlLaw` in the usage.

"""
struct Multiplier{time_dependence, variable_dependence}
    f::Function
end

# --------------------------------------------------------------------------------------------------
# model
#
"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)
"""
mutable struct Index
    val::Integer
    Index(v::Integer) = v ≥ 1 ? new(v) : error("index must be at least 1")
end
Base.:(==)(i::Index, j::Index) = i.val == j.val # needed, as this is not the default behaviour for composite types
Base.to_index(i::Index) = i.val
Base.getindex(x::AbstractArray, i::Index) = x[i.val]
Base.getindex(x::Real, i::Index) = x[i.val]
Base.isless(i::Index, j::Index) = i.val ≤ j.val
Base.isless(i::Index, j::Real) = i.val ≤ j
Base.isless(i::Real, j::Index) = i ≤ j.val
Base.length(i::Index) = 1
Base.iterate(i::Index, state=0) = state == 0 ? (i, 1) : nothing
Base.IteratorSize(::Type{Index}) = Base.HasLength()
Base.append!(v::Vector, i::Index) = Base.append!(v, i.val)

"""
Type alias for an index or range.
"""
const RangeConstraint = Union{Index, OrdinalRange{<:Integer}}

"""
$(TYPEDEF)
"""
abstract type AbstractOptimalControlModel end

"""
$(TYPEDEF)
"""
abstract type TimeDependence end
abstract type Autonomous <: TimeDependence end
abstract type NonAutonomous <: TimeDependence end

abstract type VariableDependence end
abstract type NonFixed <: VariableDependence end
abstract type Fixed <: VariableDependence end
"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)
"""
@with_kw mutable struct OptimalControlModel{time_dependence <: TimeDependence, variable_dependence <: VariableDependence} <: AbstractOptimalControlModel
    model_expression::Union{Nothing, Expr}=nothing
    initial_time::Union{Time,Index,Nothing}=nothing
    initial_time_name::Union{String, Nothing}=nothing
    final_time::Union{Time,Index,Nothing}=nothing
    final_time_name::Union{String, Nothing}=nothing
    time_name::Union{String, Nothing}=nothing
    control_dimension::Union{Dimension, Nothing}=nothing
    control_components_names::Union{Vector{String}, Nothing}=nothing
    control_name::Union{String, Nothing}=nothing
    state_dimension::Union{Dimension,Nothing}=nothing
    state_components_names::Union{Vector{String}, Nothing}=nothing
    state_name::Union{String, Nothing}=nothing
    variable_dimension::Union{Dimension,Nothing}=nothing
    variable_components_names::Union{Vector{String}, Nothing}=nothing
    variable_name::Union{String, Nothing}=nothing
    lagrange::Union{Lagrange,Nothing}=nothing
    mayer::Union{Mayer,Nothing}=nothing
    criterion::Union{Symbol,Nothing}=nothing
    dynamics::Union{Dynamics,Nothing}=nothing
    constraints::Dict{Symbol, Tuple{Vararg{Any}}}=Dict{Symbol, Tuple{Vararg{Any}}}()
end

# used for checkings
function __is_variable_not_set(ocp::OptimalControlModel) 
    conditions = [
        isnothing(ocp.variable_dimension),
        isnothing(ocp.variable_name),
        isnothing(ocp.variable_components_names)]
    @assert all(conditions) || !any(conditions) # either all or none
    return isnothing(ocp.variable_dimension)
end
__is_variable_set(ocp::OptimalControlModel) = !__is_variable_not_set(ocp)

function __is_time_not_set(ocp::OptimalControlModel)
    conditions = [
        isnothing(ocp.initial_time),
        isnothing(ocp.initial_time_name),
        isnothing(ocp.final_time),
        isnothing(ocp.final_time_name),
        isnothing(ocp.time_name)]
    @assert all(conditions) || !any(conditions) # either all or none
    return isnothing(ocp.initial_time)
end
__is_time_set(ocp::OptimalControlModel) = !__is_time_not_set(ocp)

function __is_state_not_set(ocp::OptimalControlModel)
    conditions = [
        isnothing(ocp.state_dimension),
        isnothing(ocp.state_name),
        isnothing(ocp.state_components_names)]
    @assert all(conditions) || !any(conditions) # either all or none
    return isnothing(ocp.state_dimension)
end
__is_state_set(ocp::OptimalControlModel) = !__is_state_not_set(ocp)

function __is_control_not_set(ocp::OptimalControlModel) 
    conditions = [
        isnothing(ocp.control_dimension),
        isnothing(ocp.control_name),
        isnothing(ocp.control_components_names)]
    @assert all(conditions) || !any(conditions) # either all or none
    return isnothing(ocp.control_dimension)
end
__is_control_set(ocp::OptimalControlModel) = !__is_control_not_set(ocp)

__is_dynamics_not_set(ocp::OptimalControlModel) = isnothing(ocp.dynamics)
__is_dynamics_set(ocp::OptimalControlModel) = !__is_dynamics_not_set(ocp)

function __is_objective_not_set(ocp::OptimalControlModel)
    conditions = [
        isnothing(ocp.lagrange) && isnothing(ocp.mayer),
        isnothing(ocp.criterion)]
    @assert all(conditions) || !any(conditions) # either all or none
    return isnothing(ocp.criterion)
end
__is_objective_set(ocp::OptimalControlModel) = !__is_objective_not_set(ocp)

__is_empty(ocp::OptimalControlModel) = begin
    isnothing(ocp.initial_time) && 
    isnothing(ocp.initial_time_name) &&
    isnothing(ocp.final_time) && 
    isnothing(ocp.final_time_name) &&
    isnothing(ocp.time_name) && 
    isnothing(ocp.lagrange) && 
    isnothing(ocp.mayer) && 
    isnothing(ocp.criterion) && 
    isnothing(ocp.dynamics) && 
    isnothing(ocp.state_dimension) && 
    isnothing(ocp.state_name) &&
    isnothing(ocp.state_components_names) &&
    isnothing(ocp.control_dimension) && 
    isnothing(ocp.control_name) &&
    isnothing(ocp.control_components_names) &&
    isnothing(ocp.variable_dimension) && 
    isnothing(ocp.variable_name) &&
    isnothing(ocp.variable_components_names) &&
    isempty(ocp.constraints)
end

__is_initial_time_free(ocp) = ocp.initial_time isa Index

__is_final_time_free(ocp) = ocp.final_time isa Index

__is_incomplete(ocp) = begin __is_time_not_set(ocp) || __is_state_not_set(ocp) || 
    __is_control_not_set(ocp) || __is_dynamics_not_set(ocp) || __is_objective_not_set(ocp) ||
    (__is_variable_not_set(ocp) && is_variable_dependent(ocp))
end
__is_complete(ocp) = !__is_incomplete(ocp)

__is_criterion_valid(criterion::Symbol) = criterion ∈ [:min, :max]

# --------------------------------------------------------------------------------------------------
# solution
#
"""
$(TYPEDEF)

Abstract type for optimal control solutions.
"""
abstract type AbstractOptimalControlSolution end

"""
$(TYPEDEF)

Type of an optimal control solution.

# Fields

$(TYPEDFIELDS)
"""
@with_kw mutable struct OptimalControlSolution <: AbstractOptimalControlSolution 
    times::Union{Nothing, TimesDisc}=nothing
    initial_time_name::Union{String, Nothing}=nothing
    final_time_name::Union{String, Nothing}=nothing
    time_name::Union{String, Nothing}=nothing
    control_dimension::Union{Nothing, Dimension}=nothing
    control_components_names::Union{Vector{String}, Nothing}=nothing
    control_name::Union{String, Nothing}=nothing
    control::Union{Nothing, Function}=nothing
    state_dimension::Union{Nothing, Dimension}=nothing
    state_components_names::Union{Vector{String}, Nothing}=nothing
    state_name::Union{String, Nothing}=nothing
    state::Union{Nothing, Function}=nothing
    variable_dimension::Union{Dimension,Nothing}=nothing
    variable_components_names::Union{Vector{String}, Nothing}=nothing
    variable_name::Union{String, Nothing}=nothing
    variable::Union{Nothing, Variable}=nothing
    costate::Union{Nothing, Function}=nothing
    objective::Union{Nothing, ctNumber}=nothing
    iterations::Union{Nothing, Integer}=nothing
    stopping::Union{Nothing, Symbol}=nothing # the stopping criterion
    message::Union{Nothing, String}=nothing # the message corresponding to the stopping criterion
    success::Union{Nothing, Bool}=nothing # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    infos::Dict{Symbol, Any}=Dict{Symbol, Any}()
end

function Base.copy!(sol::OptimalControlSolution, ocp::OptimalControlModel)
    sol.initial_time_name = ocp.initial_time_name
    sol.final_time_name = ocp.final_time_name
    sol.time_name = ocp.time_name
    sol.control_dimension = ocp.control_dimension
    sol.control_components_names = ocp.control_components_names
    sol.control_name = ocp.control_name
    sol.state_dimension = ocp.state_dimension
    sol.state_components_names = ocp.state_components_names
    sol.state_name = ocp.state_name
    sol.variable_dimension = ocp.variable_dimension
    sol.variable_components_names = ocp.variable_components_names
    sol.variable_name = ocp.variable_name
end
