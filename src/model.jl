# --------------------------------------------------------------------------------------------------

# Index (for variable, state and control)
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

# Abstract Optimal control model
"""
$(TYPEDEF)
"""
abstract type AbstractOptimalControlModel end

"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)
"""
@with_kw mutable struct OptimalControlModel{time_dependence} <: AbstractOptimalControlModel
    initial_time::Union{Time,Index,Nothing}=nothing
    final_time::Union{Time,Index,Nothing}=nothing
    time_name::Union{String, Nothing}=nothing
    lagrange::Union{Lagrange,Nothing}=nothing
    mayer::Union{Mayer,Nothing}=nothing
    criterion::Union{Symbol,Nothing}=nothing
    dynamics::Union{Dynamics,Nothing}=nothing
    variable_dimension::Union{Dimension,Nothing}=nothing
    variable_names::Union{Vector{String}, Nothing}=nothing
    state_dimension::Union{Dimension,Nothing}=nothing
    state_names::Union{Vector{String}, Nothing}=nothing
    control_dimension::Union{Dimension, Nothing}=nothing
    control_names::Union{Vector{String}, Nothing}=nothing
    constraints::Dict{Symbol, Tuple{Vararg{Any}}}=Dict{Symbol, Tuple{Vararg{Any}}}()
    # store parsing informations inside Model itself
    defined_with_macro::Bool=false
    generated_code::Array{String}=[]
end

#
dims_set(ocp) = !isnothing(ocp.state_dimension) && !isnothing(ocp.control_dimension)
#
time_set(ocp) = !isnothing(ocp.initial_time) && !isnothing(ocp.final_time)

"""
$(TYPEDSIGNATURES)

Return :nonautonomous == time_dependence
"""
isnonautonomous(time_dependence::Symbol) = :nonautonomous == time_dependence

"""
$(TYPEDSIGNATURES)

Return !isnonautonomous(time_dependence)
"""
isautonomous(time_dependence::Symbol) = !isnonautonomous(time_dependence)

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined as nonautonomous.
"""
isnonautonomous(ocp::OptimalControlModel{time_dependence}) where {time_dependence} = isnonautonomous(time_dependence)

"""
$(TYPEDSIGNATURES)

Return `true` if the model has been defined as autonomous.
"""
isautonomous(ocp::OptimalControlModel) = !isnonautonomous(ocp)

"""
$(TYPEDSIGNATURES)

Return `true` if the criterion type of `ocp` is `:min`.
"""
ismin(ocp::OptimalControlModel) = ocp.criterion == :min

"""
$(TYPEDSIGNATURES)

Return `true` if the criterion type of `ocp` is `:max`.
"""
ismax(ocp::OptimalControlModel) = !ismin(ocp)

"""
$(TYPEDSIGNATURES)

Return `true` if a variable has been declared.
"""
hasvariable(ocp::OptimalControlModel) = !isnothing(ocp.variable_dimension)

"""
$(TYPEDSIGNATURES)

Return a new `OptimalControlModel` instance, that is a model of an optimal control problem.

The model is defined by the following optional keyword argument:

- `time_dependence`: either `:autonomous` or `:nonautonomous`. Default is `:autonomous`.

# Examples

```jldoctest
julia> ocp = Model()
julia> ocp = Model(time_dependence=:nonautonomous)
```

!!! note

    - If the time dependence of the model is defined as nonautonomous, then, the dynamics function, the lagrange cost and the path constraints must be defined as functions of time and state, and possibly control. If the model is defined as autonomous, then, the dynamics function, the lagrange cost and the path constraints must be defined as functions of state, and possibly control.

"""
function Model(; time_dependence=__ocp_time_dependence())
    if time_dependence ∉ [ :autonomous, :nonautonomous ]
        throw(InconsistentArgument("time_dependence must be either :autonomous or :nonautonomous"))
    end
    return OptimalControlModel{time_dependence}()
end

# -------------------------------------------------------------------------------------------
#
"""
$(TYPEDSIGNATURES)

Define the variable dimension and possibly the names of each coordinate.

# Examples
```jldoctest
julia> variable!(ocp, 1, "v")
julia> variable!(ocp, 2, [ "v₁", "v₂" ])
```
"""
function variable!(ocp::OptimalControlModel, q::Dimension, names::Union{String, Vector{String}}=__variable_names(q))
    (q > 1) && (names isa Vector{String}) && (length(names) ≠ q) && throw(InconsistentArgument("the number of variables names must be equal to the variable dimension"))
    (q == 1) && (names isa Vector{String}) && throw(InconsistentArgument("if the variable dimension is 1, then, the argument names must be a String"))
    (q > 1) && (names isa String) && (names = [ names * ctindices(i) for i ∈ range(1, q)])
    ocp.variable_dimension = q
    ocp.variable_names = (q == 1) ? [names] : names
end

function variable!(ocp::OptimalControlModel, q::Dimension, name::Symbol)
    variable!(ocp, q, string(name))
end

"""
$(TYPEDSIGNATURES)

Define the state dimension and possibly the names of each coordinate.

# Examples

```jldoctest
julia> state!(ocp, 1)
julia> ocp.state_dimension
1
julia> ocp.state_names
["x"]

julia> state!(ocp, 1, "y")
julia> ocp.state_dimension
1
julia> ocp.state_names
["y"]

julia> state!(ocp, 2)
julia> ocp.state_dimension
2
julia> ocp.state_names
["x₁", "x₂"]

julia> state!(ocp, 2, [ "y₁", "y₂" ])
julia> ocp.state_dimension
2
julia> ocp.state_names
["y₁", "y₂"]

julia> state!(ocp, 2, :y)
julia> ocp.state_dimension
2
julia> ocp.state_names
["y₁", "y₂"]

julia> state!(ocp, 2, "y")
julia> ocp.state_dimension
2
julia> ocp.state_names
["y₁", "y₂"]
```
"""
function state!(ocp::OptimalControlModel, n::Dimension, names::Union{String, Vector{String}}=__state_names(n))
    (n > 1 )&& (names isa Vector{String}) && (length(names) ≠ n) && throw(InconsistentArgument("the number of state names must be equal to the state dimension"))
    (n == 1) && (names isa Vector{String}) && throw(InconsistentArgument("if the state dimension is 1, then, the argument names must be a String"))
    (n > 1) && (names isa String) && (names = [ names * ctindices(i) for i ∈ range(1, n)])
    ocp.state_dimension = n
    ocp.state_names = (n == 1) ? [names] : names
    nothing
end
function state!(ocp::OptimalControlModel, n::Dimension, name::Symbol)
    state!(ocp, n, string(name))
end

"""
$(TYPEDSIGNATURES)

Define the control dimension and possibly the names of each coordinate.

# Examples

```jldoctest
julia> control!(ocp, 1)
julia> ocp.control_dimension
1
julia> ocp.control_names
["u"]

julia> control!(ocp, 1, "v")
julia> ocp.control_dimension
1
julia> ocp.control_names
["v"]

julia> control!(ocp, 2)
julia> ocp.control_dimension
2
julia> ocp.control_names
["u₁", "u₂"]

julia> control!(ocp, 2, [ "v₁", "v₂" ])
julia> ocp.control_dimension
2
julia> ocp.control_names
["v₁", "v₂"]

julia> control!(ocp, 2, :v)
julia> ocp.control_dimension
2
julia> ocp.control_names
["v₁", "v₂"]

julia> control!(ocp, 2, "v")
julia> ocp.control_dimension
2
julia> ocp.control_names
["v₁", "v₂"]
```
"""
function control!(ocp::OptimalControlModel, m::Dimension, names::Union{String, Vector{String}}=__control_names(m))
    (m > 1) && (names isa Vector{String}) && (length(names) != m) && throw(InconsistentArgument("the number of control names must be equal to the control dimension"))
    (m == 1) && (names isa Vector{String}) && throw(InconsistentArgument("if the control dimension is 1, then, the argument names must be a String"))
    (m > 1) && (names isa String) && (names = [ names * ctindices(i) for i ∈ range(1, m)])
    ocp.control_dimension = m
    ocp.control_names = (m == 1) ? [names] : names
    nothing
end

function control!(ocp::OptimalControlModel, m::Dimension, name::Symbol)
    control!(ocp, m, string(name))
end

# -------------------------------------------------------------------------------------------
#
"""
$(TYPEDSIGNATURES)

Fix initial time, final time is free and given by the variable at the provided index.

!!! note

    You can use time! once to set either the initial or the final time, or both.

# Examples

```jldoctest
julia> time!(ocp, 0, Index(2), "t")
```
"""
function time!(ocp::OptimalControlModel, t0::Time, indf::Index, name::String=__time_name())
    time_set(ocp) && throw(UnauthorizedCall("the time has already been set. Use time! once."))
    (indf.val > ocp.variable_dimension) && throw(IncorrectArgument("out of range index of variable"))
    ocp.initial_time = t0
    ocp.final_time = indf
    ocp.time_name = name
end

function time!(ocp::OptimalControlModel, t0::Time, indf::Index, name::Symbol)
    time!(ocp, t0, indf, string(name))
end

"""
$(TYPEDSIGNATURES)

Fix final time, initial time is free and given by the variable at the provided index.

# Examples
```jldoctest
julia> time!(ocp, Index(2), 1, "t")
```
"""
function time!(ocp::OptimalControlModel, ind0::Index, tf::Time, name::String=__time_name())
    time_set(ocp) && throw(UnauthorizedCall("the time has already been set. Use time! once."))
    (ind0.val > ocp.variable_dimension) && throw(IncorrectArgument("out of range index of variable"))
    ocp.initial_time = ind0
    ocp.final_time = tf
    ocp.time_name = name
end

function time!(ocp::OptimalControlModel, ind0::Index, tf::Time, name::Symbol)
    time!(ocp, ind0, tf, string(name))
end

"""
$(TYPEDSIGNATURES)

Initial and final times are free and given by the variable at the provided indices.

# Examples
```jldoctest
julia> time!(ocp, Index(2), Index(3), "t")
```
"""
function time!(ocp::OptimalControlModel, ind0::Index, indf::Index, name::String=__time_name())
    time_set(ocp) && throw(UnauthorizedCall("the time has already been set. Use time! once."))
    (ind0.val > ocp.variable_dimension) && throw(IncorrectArgument("out of range index of variable"))
    (indf.val > ocp.variable_dimension) && throw(IncorrectArgument("out of range index of variable"))
    ocp.initial_time = ind0
    ocp.final_time = indf
    ocp.time_name = name
end

function time!(ocp::OptimalControlModel, ind0::Index, indf::Index, name::Symbol)
    time!(ocp, ind0, indf, string(name))
end

"""
$(TYPEDSIGNATURES)

Fix initial and final times to `times[1]` and `times[2]`, respectively.

# Examples

```jldoctest
julia> time!(ocp, [ 0, 1 ])
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"t"

julia> time!(ocp, [ 0, 1 ], "s")
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"s"

julia> time!(ocp, [ 0, 1 ], :s)
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"s"
```
"""
function time!(ocp::OptimalControlModel, times::Times, name::String=__time_name())
    (length(times) != 2) && throw(IncorrectArgument("times must be of dimension 2"))
    time!(ocp, times[1], times[2], name)
end

function time!(ocp::OptimalControlModel, times::Times, name::Symbol)
    time!(ocp, times, string(name))
end

"""
$(TYPEDSIGNATURES)

Fix initial and final times to `times[1]` and `times[2]`, respectively.

# Examples

```jldoctest
julia> time!(ocp, 0, 1)
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"t"

julia> time!(ocp, 0, 1, "s")
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"s"

julia> time!(ocp, 0, 1, :s)
julia> ocp.initial_time
0
julia> ocp.final_time
1
julia> ocp.time_name
"s"
```
"""
function time!(ocp::OptimalControlModel, t0::Time, tf::Time, name::String=__time_name())
    time_set(ocp) && throw(UnauthorizedCall("the time has already been set. Use time! once."))
    ocp.initial_time=t0
    ocp.final_time=tf
    ocp.time_name = name
end

function time!(ocp::OptimalControlModel, t0::Time, tf::Time, name::Symbol)
    time!(ocp, t0, tf, string(name))
end

# -------------------------------------------------------------------------------------------
#
"""
$(TYPEDSIGNATURES)

Add an `:initial` or `:final` value constraint on the state.

# Examples

```jldoctest
# state dimension: 1
julia> constraint!(ocp, :initial, 0)
julia> constraint!(ocp, :final, 1)

# state dimension: 2
julia> constraint!(ocp, :initial, [ 0, 0 ])
julia> constraint!(ocp, :final, [ 0, 0 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, val, label::Symbol=__constraint_label())

    # check if the constraint named label already exists
    if label ∈ constraints_labels(ocp)
        throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    end

    # set the constraint
    if type ∈ [ :initial, :final ] # not allowed for :control or :state (does not make sense)
        ocp.constraints[label] = (type, :eq, x -> x, val, val)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final ] or check the arguments of the constraint! method."))
    end

end

"""
$(TYPEDSIGNATURES)

Add an `:initial` or `:final` value constraint on a range of the state.

# Examples

```jldoctest
julia> constraint!(ocp, :initial, 1:2:5, [ 0, 0, 0 ])
julia> constraint!(ocp, :initial, 2:3, [ 0, 0 ])
julia> constraint!(ocp, :final, Index(2), 0)
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, rg::Union{Index, OrdinalRange{<:Integer}}, val, label::Symbol=__constraint_label())

    # check if the constraint named label already exists
    if label ∈ constraints_labels(ocp)
        throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    end

    # set the constraint
    if type ∈ [ :initial, :final ] # not allowed for :control or :state (does not make sense)
    rg = rg isa Index ? rg.val : rg
        ocp.constraints[label] = (type, :eq, x -> x[rg], val, val)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final ] or check the arguments of the constraint! method."))
    end

end

"""
$(TYPEDSIGNATURES)

Add an :initial, :final, :control or :state box constraint (whole range).

# Examples

```jldoctest
julia> constraint!(ocp, :initial, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :final, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :control, [ 0, 0 ], [ 2, 3 ])
julia> constraint!(ocp, :state, [ 0, 0, 0 ], [ 1, 2, 1 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, lb, ub, label::Symbol=__constraint_label())

    # check if the constraint named label already exists
    if label ∈ constraints_labels(ocp)
        throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    end

    # check if the dimensions of the state and control are set
    !dims_set(ocp) && throw(UnauthorizedCall("the dimensions of the state and control must be set before adding the dynamics."))
    n = ocp.state_dimension
    m = ocp.control_dimension

    # set the constraint
    if type ∈ [ :initial, :final ]
        ocp.constraints[label] = (type, :ineq, x -> x, lb, ub)
    elseif type == :control
        ocp.constraints[label] = (type, :ineq, m == 1 ? 1 : 1:m, lb, ub)
    elseif type == :state
        ocp.constraints[label] = (type, :ineq, n == 1 ? 1 : 1:n, lb, ub)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final, :control, :state ] or check the arguments of the constraint! method."))
    end

end

"""
$(TYPEDSIGNATURES)

Add an `:initial`, `:final`, `:control` or `:state` box constraint on a range.

# Examples

```jldoctest
julia> constraint!(ocp, :initial, 2:3, [ 0, 0 ], [ 1, 2 ])
julia> constraint!(ocp, :final, Index(1), 0, 2)
julia> constraint!(ocp, :control, Index(1), 0, 2)
julia> constraint!(ocp, :state, 2:3, [ 0, 0 ], [ 1, 2 ])
julia> constraint!(ocp, :initial, 1:2:5, [ 0, 0, 0 ], [ 1, 2, 1 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, rg::Union{Index, OrdinalRange{<:Integer}}, lb, ub, label::Symbol=__constraint_label())

    # check if the constraint named label already exists
    if label ∈ constraints_labels(ocp)
        throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    end

    # set the constraint
    rg = rg isa Index ? rg.val : rg
    if type ∈ [ :initial, :final ]
        ocp.constraints[label] = (type, :ineq, x -> x[rg], lb, ub)
    elseif type ∈ [ :control, :state ]
        ocp.constraints[label] = (type, :ineq, rg, lb, ub)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final, :contol, :state ] or check the arguments of the constraint! method."))
    end

end

"""
$(TYPEDSIGNATURES)

Add a `:boundary`, `:control`, `:state` or `:mixed` value functional constraint.

# Examples

```@example
julia> constraint!(ocp, :boundary, (t0, x0, tf, xf) -> [ t0+tf, x0[3]+xf[2]], [ 0, 0 ])

# autonomous ocp
julia> constraint!(ocp, :control, u -> 2u, 1)
julia> constraint!(ocp, :state, x -> x-1, [ 0, 0, 0 ])
julia> constraint!(ocp, :mixed, (x, u) -> x[1]-u, 0)

# nonautonomous ocp
julia> constraint!(ocp, :control, (t, u) -> 2u, 1)
julia> constraint!(ocp, :state, (t, x) -> x-t, [ 0, 0, 0 ])
julia> constraint!(ocp, :mixed, (t, x, u) -> x[1]-u, 0)
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, val, label::Symbol=__constraint_label())

    # check if the constraint named label already exists
    if label ∈ constraints_labels(ocp)
        throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    end

    # set the constraint
    if type ∈ [ :boundary, :control, :state, :mixed ]
        ocp.constraints[label] = (type, :eq, f, val, val)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :boundary, :control, :state, :mixed ] or check the arguments of the constraint! method."))
    end

end

"""
$(TYPEDSIGNATURES)

Add a `:boundary`, `:control`, `:state` or `:mixed` box functional constraint.

# Examples

```@example
julia> constraint!(ocp, :boundary, (t0, x0, tf, xf) -> [ t0+tf, x0[3]+xf[2]], [ 0, 0 ], [ 1, 1 ])

# autonomous ocp
julia> constraint!(ocp, :control, u -> 2u, 0, 1)
julia> constraint!(ocp, :state, x -> x-1, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :mixed, (x, u) -> x[1]-u, 0, 1)

# nonautonomous ocp
julia> constraint!(ocp, :control, (t, u) -> 2u, 0, 1)
julia> constraint!(ocp, :state, (t, x) -> x-t, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :mixed, (t, x, u) -> x[1]-u, 0, 1)
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, lb, ub, label::Symbol=__constraint_label())

    # check if the constraint named label already exists
    if label ∈ constraints_labels(ocp)
        throw(UnauthorizedCall("the constraint named " * String(label) * " already exists."))
    end

    # set the constraint
    if type ∈ [ :boundary, :control, :state, :mixed ]
        ocp.constraints[label] = (type, :ineq, f, lb, ub)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :boundary, :control, :state, :mixed ] or check the arguments of the constraint! method."))
    end
    
end

"""
$(TYPEDSIGNATURES)

Set the dynamics `f(x, u)` in the autonomous case and `f(t, x, u)` in the nonautonomous case.

!!! note

    - The dimensions of the state and control must be set before adding the dynamics.
    - The dynamics must be provided as a function of time (if ocp is nonautonomous), state and control.
    - The output of the dynamics must be of same dimension as the state (scalar if the state is of dimension 1).

# Example

```jldoctest
julia> constraint!(ocp, :dynamics, f)
```
"""
function constraint!(ocp::OptimalControlModel{time_dependence}, type::Symbol, f::Function) where {time_dependence}

    # check if the dimensions of the state and control are set
    !dims_set(ocp) && throw(UnauthorizedCall("the dimensions of the state and control must be set before adding the dynamics."))
    n = ocp.state_dimension
    m = ocp.control_dimension

    # set the dynamics
    if type ∈ [ :dynamics ]
        setproperty!(ocp, type, Dynamics(f, time_dependence=time_dependence, state_dimension=n, control_dimension=m))
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :dynamics ] or check the arguments of the constraint! method."))
    end

end

"""
$(TYPEDSIGNATURES)

Remove a labeled constraint.

# Example

```jldoctest
julia> remove_constraint!(ocp, :con)
```
"""
function remove_constraint!(ocp::OptimalControlModel, label::Symbol)
    if !haskey(ocp.constraints, label)
        throw(IncorrectArgument("the following constraint does not exist: " * String(label) *
        ". Please check the list of constraints: ocp.constraints."))
    end
    delete!(ocp.constraints, label)
end

"""
$(TYPEDSIGNATURES)

Return the labels of the constraints as a `Base.keys`.

# Example

```@example
julia> constraints_labels(ocp)
```
"""
function constraints_labels(ocp::OptimalControlModel)
    return keys(ocp.constraints)
end

#
"""
$(TYPEDSIGNATURES)

Retrieve a labeled constraint. The result is a function associated with the constraint
computation (not taking into account provided value / bounds).

# Example

```jldoctest
julia> constraint!(ocp, :initial, 0, :c0)
julia> c = constraint(ocp, :c0)
julia> c(1)
1
```
"""
function constraint(ocp::OptimalControlModel{:autonomous}, label::Symbol)
    con = ocp.constraints[label]
    @match con begin
        (:initial , _, f::Function, _, _) => return f
        (:final   , _, f::Function, _, _) => return f
        (:boundary, _, f::Function, _, _) => return f
        (:control , _, f::Function, _, _) => return f
        (:control , _, rg         , _, _) => return u -> u[rg]
        (:state   , _, f::Function, _, _) => return f
        (:state   , _, rg         , _, _) => return x -> x[rg]
        (:mixed   , _, f::Function, _, _) => return f
        _ => throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
             ". Please choose within [ :initial, :final, :boundary, :control, :state, :mixed ]."))
    end
end
function constraint(ocp::OptimalControlModel{:nonautonomous}, label::Symbol)
    con = ocp.constraints[label]
    @match con begin
        (:initial , _, f::Function, _, _) => return f
        (:final   , _, f::Function, _, _) => return f
        (:boundary, _, f::Function, _, _) => return f 
        (:control , _, f::Function, _, _) => return f 
        (:control , _, rg         , _, _) => return (t, u) -> u[rg]
        (:state   , _, f::Function, _, _) => return f 
        (:state   , _, rg         , _, _) => return (t, x) -> x[rg]
        (:mixed   , _, f::Function, _, _) => return f 
        _ => throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
             ". Please choose within [ :initial, :final, :boundary, :control, :state, :mixed ]."))
    end
end

"""
$(TYPEDSIGNATURES)

Return a 6-tuple of tuples:

- `(ξl, ξ, ξu)` are control constraints
- `(ηl, η, ηu)` are state constraints
- `(ψl, ψ, ψu)` are mixed constraints
- `(ϕl, ϕ, ϕu)` are boundary constraints
- `(ulb, uind, uub)` are control linear constraints of a subset of indices
- `(xlb, xind, xub)` are state linear constraints of a subset of indices

!!! note

    - The dimensions of the state and control must be set before calling `nlp_constraints`.

# Example

```jldoctest
julia> (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu),
    (ulb, uind, uub), (xlb, xind, xub) = nlp_constraints(ocp)
```
"""
function nlp_constraints(ocp::OptimalControlModel{time_dependence}) where {time_dependence}
 
    !dims_set(ocp) && throw(UnauthorizedCall("the dimensions of the state and/or control are not set. Please use state! and control! methods."))
    n = ocp.state_dimension
    m = ocp.control_dimension
    constraints = ocp.constraints

    ξf = Vector{ControlConstraint}(); ξl = Vector{ctNumber}(); ξu = Vector{ctNumber}()
    ηf = Vector{StateConstraint}(); ηl = Vector{ctNumber}(); ηu = Vector{ctNumber}()
    ψf = Vector{MixedConstraint}(); ψl = Vector{ctNumber}(); ψu = Vector{ctNumber}()
    ϕf = Vector{BoundaryConstraint}(); ϕl = Vector{ctNumber}(); ϕu = Vector{ctNumber}()
    uind = Vector{Int}(); ulb = Vector{ctNumber}(); uub = Vector{ctNumber}()
    xind = Vector{Int}(); xlb = Vector{ctNumber}(); xub = Vector{ctNumber}()

    for (_, c) ∈ constraints
        @match c begin
        (:initial, _, f, lb, ub) => begin
            push!(ϕf, BoundaryConstraint((t0, x0, tf, xf) -> f(x0), state_dimension=n, constraint_dimension=length(lb)))
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:final, _, f, lb, ub) => begin
            push!(ϕf, BoundaryConstraint((t0, x0, tf, xf) -> f(xf), state_dimension=n, constraint_dimension=length(lb)))
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:boundary, _, f, lb, ub) => begin
            push!(ϕf, BoundaryConstraint((t0, x0, tf, xf) -> f(t0, x0, tf, xf), state_dimension=n, constraint_dimension=length(lb)))
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:control, _, f::Function, lb, ub) => begin
            push!(ξf, ControlConstraint(f, time_dependence=time_dependence, control_dimension=m, constraint_dimension=length(lb)))
            append!(ξl, lb)
            append!(ξu, ub) end
        (:control, _, rg, lb, ub) => begin 
            append!(uind, rg)
            append!(ulb, lb)
            append!(uub, ub) end
        (:state, _, f::Function, lb, ub) => begin
            push!(ηf, StateConstraint(f, time_dependence=time_dependence, state_dimension=n, constraint_dimension=length(lb)))
            append!(ηl, lb)
            append!(ηu, ub) end
        (:state, _, rg, lb, ub) => begin
            append!(xind, rg)
            append!(xlb, lb)
            append!(xub, ub) end
        (:mixed, _, f, lb, ub) => begin
            push!(ψf, MixedConstraint(f, time_dependence=time_dependence, state_dimension=n, control_dimension=m, constraint_dimension=length(lb)))
            append!(ψl, lb)
            append!(ψu, ub) end
        _ => throw(NotImplemented("dealing with this kind of constraint is not implemented"))
    end # match
    end # for

    function ξ(t, u)
        val = Vector{ctNumber}()
        for i ∈ 1:length(ξf) append!(val, ξf[i](t, u)) end
        return val
    end

    function η(t, x)
        val = Vector{ctNumber}()
        for i ∈ 1:length(ηf) append!(val, ηf[i](t, x)) end
        return val
    end

    function ψ(t, x, u)
        val = Vector{ctNumber}()
        for i ∈ 1:length(ψf) append!(val, ψf[i](t, x, u)) end
        return val
    end

    function ϕ(t0, x0, tf, xf)
        val = Vector{ctNumber}()
        for i ∈ 1:length(ϕf) append!(val, ϕf[i](t0, x0, tf, xf)) end
        return val
    end

    return (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (ulb, uind, uub), (xlb, xind, xub)

end

# -------------------------------------------------------------------------------------------
#
"""
$(TYPEDSIGNATURES)

Set the criterion to the function `f`. Type can be `:mayer` or `:lagrange`. Criterion is `:min` or `:max`.

!!! note

    - The dimensions of the state and control must be set before adding the dynamics.
    
# Examples

```jldoctest
julia> objective!(ocp, :mayer, (t0, x0, tf, xf) -> tf)
julia> objective!(ocp, :lagrange, (x, u) -> x[1]^2 + u[1]^2)
```

!!! warning

    If you set twice the objective, only the last one will be taken into account.
"""
function objective!(ocp::OptimalControlModel{time_dependence}, type::Symbol, f::Function, criterion::Symbol=__criterion_type()) where {time_dependence}

    !dims_set(ocp) && throw(UnauthorizedCall("the dimensions of the state and/or control are not set. Please use state! and control! methods."))
    n = ocp.state_dimension
    m = ocp.control_dimension

    # reset the objective
    if !isnothing(ocp.mayer) || !isnothing(ocp.lagrange)
        println("warning: The objective is already set. It will be replaced by the new one.")
    end
    setproperty!(ocp, :mayer, nothing)
    setproperty!(ocp, :lagrange, nothing)

    # check the validity of the criterion
    if criterion ∈ [ :min, :max ]
        ocp.criterion = criterion
    else
        throw(IncorrectArgument("the following criterion is not valid: " * String(criterion) *
        ". Please choose in [ :min, :max ]."))
    end

    # set the objective
    if type == :mayer
        setproperty!(ocp, :mayer, Mayer(f, state_dimension=n))
    elseif type == :lagrange
        setproperty!(ocp, :lagrange, Lagrange(f, time_dependence=time_dependence, state_dimension=n, control_dimension=m))
    else
        throw(IncorrectArgument("the following objective is not valid: " * String(objective) *
        ". Please choose in [ :mayer, :lagrange ]."))
    end
end

"""
$(TYPEDSIGNATURES)

Set the criterion to the function `g` and `f⁰`. Type can be `:bolza`. Criterion is `:min` or `:max`.

!!! note

    - The dimensions of the state and control must be set before adding the dynamics.

# Example

```jldoctest
julia> objective!(ocp, :bolza, (t0, x0, tf, xf) -> tf, (x, u) -> x[1]^2 + u[1]^2)
```
"""
function objective!(ocp::OptimalControlModel{time_dependence}, type::Symbol, g::Function, f⁰::Function, criterion::Symbol=__criterion_type()) where {time_dependence}

    !dims_set(ocp) && throw(UnauthorizedCall("the dimensions of the state and/or control are not set. Please use state! and control! methods."))
    n = ocp.state_dimension
    m = ocp.control_dimension

    # reset the objective
    if !isnothing(ocp.mayer) || !isnothing(ocp.lagrange)
        println("warning: The objective is already set. It will be replaced by the new one.")
    end
    setproperty!(ocp, :mayer, nothing)
    setproperty!(ocp, :lagrange, nothing)

    # check the validity of the criterion
    if criterion ∈ [ :min, :max ]
        ocp.criterion = criterion
    else
        throw(IncorrectArgument("the following criterion is not valid: " * String(criterion) *
        ". Please choose in [ :min, :max ]."))
    end

    # set the objective
    if type == :bolza
        setproperty!(ocp, :mayer, Mayer(g, state_dimension=n))
        setproperty!(ocp, :lagrange, Lagrange(f⁰, time_dependence=time_dependence, state_dimension=n, control_dimension=m))
    else
        throw(IncorrectArgument("the following objective is not valid: " * String(objective) *
        ". Please choose :bolza."))
    end
end
