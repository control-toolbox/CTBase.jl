# --------------------------------------------------------------------------------------------------
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
@with_kw mutable struct OptimalControlModel{time_dependence, dimension_usage} <: AbstractOptimalControlModel
    initial_time::Union{Time,Nothing}=nothing
    final_time::Union{Time,Nothing}=nothing
    time_name::Union{String, Nothing}=nothing
    lagrange::Union{LagrangeFunction{time_dependence, dimension_usage},Nothing}=nothing
    mayer::Union{MayerObjective{dimension_usage},Nothing}=nothing
    criterion::Union{Symbol,Nothing}=nothing
    dynamics::Union{DynamicsFunction{time_dependence, dimension_usage},Nothing}=nothing
    dynamics!::Union{Function,Nothing}=nothing
    state_dimension::Union{Dimension,Nothing}=nothing
    state_names::Union{Vector{String}, Nothing}=nothing
    control_dimension::Union{Dimension,Nothing}=nothing
    control_names::Union{Vector{String}, Nothing}=nothing
    constraints::Dict{Symbol, Tuple{Vararg{Any}}}=Dict{Symbol, Tuple{Vararg{Any}}}()
end

# Constraint index
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

"""
$(TYPEDSIGNATURES)

Returns :nonautonomous == time_dependence
"""
isnonautonomous(time_dependence::Symbol) = :nonautonomous == time_dependence

"""
$(TYPEDSIGNATURES)

Returns !isnonautonomous(time_dependence)
"""
isautonomous(time_dependence::Symbol) = !isnonautonomous(time_dependence)

"""
$(TYPEDSIGNATURES)

Returns `true` if the model has been defined as nonautonomous.
"""
isnonautonomous(ocp::OptimalControlModel{time_dependence, dimension_usage}) where {time_dependence, dimension_usage} = isnonautonomous(time_dependence)

"""
$(TYPEDSIGNATURES)

Returns `true` if the model has been defined as autonomous.
"""
isautonomous(ocp::OptimalControlModel) = !isnonautonomous(ocp)

"""
$(TYPEDSIGNATURES)

Returns `true` if the criterion type of `ocp` is `:min`.
"""
ismin(ocp::OptimalControlModel) = ocp.criterion == :min

"""
$(TYPEDSIGNATURES)

Returns `true` if the criterion type of `ocp` is `:max`.
"""
ismax(ocp::OptimalControlModel) = !ismin(ocp)

"""
$(TYPEDSIGNATURES)

Returns a new `OptimalControlModel` instance, that is a model of an optimal control problem.

The model is defined by the following arguments:

- `time_dependence`: either `:autonomous` or `:nonautonomous`. Default is `:autonomous`.
- `dimension_usage`: either `:scalar` or `:vectorial`. Default is `:scalar`.

# Examples

```jldoctest
julia> ocp = Model()
julia> ocp = Model(time_dependence=:nonautonomous)
julia> ocp = Model(dimension_usage=:vectorial)
julia> ocp = Model(time_dependence=:nonautonomous, dimension_usage=:vectorial)
```

!!! note

    - If the time dependence of the model is defined as nonautonomous, then, the dynamics function, the lagrange cost and the path constraints must be defined as functions of time and state, and possibly control. If the model is defined as autonomous, then, the dynamics function, the lagrange cost and the path constraints must be defined as functions of state, and possibly control.
    - If the dimension usage of the model is defined as vectorial, then, one dimensional state and / or control variables are considered as vectors. If the model is defined as scalar, then, one dimensional state and / or control variables are considered as scalars.

"""
function Model(; time_dependence=__ocp_time_dependence(), dimension_usage=__ocp_dimension_usage()) 
    return OptimalControlModel{time_dependence, dimension_usage}()
end

# -------------------------------------------------------------------------------------------
# 
"""
$(TYPEDSIGNATURES)

Define the state dimension and possibly the names of each coordinate.

# Examples
```jldoctest
julia> state!(ocp, 1, "y")
julia> state!(ocp, 2, [ "x₁", "x₂" ])
```
"""
function state!(ocp::OptimalControlModel, n::Dimension, names::Union{String, Vector{String}}=__state_names(n))
    if n > 1 && length(names) != n
        throw(InconsistentArgument("the number of state names must be equal to the state dimension"))
    end
    if n == 1 && names isa Vector{String}
        throw(InconsistentArgument("if the state dimension is 1, then, the argument names must be a String"))
    end
    ocp.state_dimension = n
    ocp.state_names = n==1 ? [names] : names
end

"""
$(TYPEDSIGNATURES)

Define the control dimension and possibly the names of each coordinate.

# Examples
```jldoctest
julia> control!(ocp, 1, "v")
julia> control!(ocp, 2, [ "u₁", "u₂" ])
```
"""
function control!(ocp::OptimalControlModel, m::Dimension, names::Union{String, Vector{String}}=__control_names(m))
    if m > 1 && length(names) != m
        throw(InconsistentArgument("the number of control names must be equal to the control dimension"))
    end
    if m == 1 && names isa Vector{String}
        throw(InconsistentArgument("if the control dimension is 1, then, the argument names must be a String"))
    end
    ocp.control_dimension = m
    ocp.control_names = m==1 ? [names] : names
end

# -------------------------------------------------------------------------------------------
# 
"""
$(TYPEDSIGNATURES)

Fix initial (resp. final) time, the final (resp. initial) time being variable (free),
when type is `:initial`. And conversely when type is `:final`. 

# Examples
```jldoctest
julia> time!(ocp, :initial, 0, "t")
julia> time!(ocp, :final, 1, "t")
```
"""
function time!(ocp::OptimalControlModel, type::Symbol, time::Time, name::String=__time_name())
    type_ = Symbol(type, :_time)
    if type_ ∈ [ :initial_time, :final_time ]
        setproperty!(ocp, type_, time)
        ocp.time_name = name
    else
        throw(IncorrectArgument("the following type of time is not valid: " * String(type) *
        ". Please choose in [ :initial, :final ]."))
    end
end

"""
$(TYPEDSIGNATURES)

Fix initial and final times to `t[1]` and `t[2]`, respectively.

# Examples
```jldoctest
julia> time!(ocp, [ 0, 1 ], "t")
```
"""
function time!(ocp::OptimalControlModel, times::Times, name::String=__time_name())
    if length(times) != 2
        throw(IncorrectArgument("times must be of dimension 2"))
    end
    ocp.initial_time=times[1]
    ocp.final_time=times[2]
    ocp.time_name = name
end

# -------------------------------------------------------------------------------------------
#
"""
$(TYPEDSIGNATURES)

Add an `:initial` or `:final` value constraint on the state.

# Examples
```jldoctest
julia> constraint!(ocp, :initial, [ 0, 0, 0 ])
julia> constraint!(ocp, :final, [ 0, 0, 0 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, val, label::Symbol=__constraint_label())
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
julia> constraint!(ocp, :initial, 2:3, [ 0, 0 ])
julia> constraint!(ocp, :final, Index(1), 0)
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, rg::Union{Index, UnitRange{<:Integer}}, val, label::Symbol=__constraint_label())
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
    if type ∈ [ :initial, :final ]
        ocp.constraints[label] = (type, :ineq, x -> x, lb, ub)
    elseif type == :control
        ocp.constraints[label] = (type, :ineq, ocp.control_dimension == 1 ? 1 : 1:ocp.control_dimension, lb, ub)
    elseif type == :state
        ocp.constraints[label] = (type, :ineq, ocp.state_dimension == 1 ? 1 : 1:ocp.state_dimension, lb, ub)
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
julia> constraint!(ocp, :initial, 2:3, [ 0, 0 ], [1, 2])
julia> constraint!(ocp, :final, Index(1), 0, 2)
julia> constraint!(ocp, :control, Index(1), 0, 2)
julia> constraint!(ocp, :state, 2:3, [ 0, 0 ], [1, 2])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, rg::Union{Index, UnitRange{<:Integer}}, lb, ub, label::Symbol=__constraint_label())
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
```jldoctest
julia> constraint!(ocp, :boundary, f, [ 0, 0 ])
julia> constraint!(ocp, :control, f, [ 0, 0 ])
julia> constraint!(ocp, :state, f, [ 0, 0 ])
julia> constraint!(ocp, :mixed, f, [ 0, 0 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, val, label::Symbol=__constraint_label())
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
```jldoctest
julia> constraint!(ocp, :boundary, f, [ 0, 0 ], [ 1, 2 ])
julia> constraint!(ocp, :control, f, [ 0, 0 ], [ 1, 2 ])
julia> constraint!(ocp, :state, f, [ 0, 0 ], [ 1, 2 ])
julia> constraint!(ocp, :mixed, f, [ 0, 0 ], [ 1, 2 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, lb, ub, label::Symbol=__constraint_label())
    if type ∈ [ :boundary, :control, :state, :mixed ]
        ocp.constraints[label] = (type, :ineq, f, lb, ub)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :boundary, :control, :state, :mixed ] or check the arguments of the constraint! method."))
    end
end

"""
$(TYPEDSIGNATURES)

Provide dynamics (possibly in place).

# Examples
```jldoctest
julia> constraint!(ocp, :dynamics, f)
julia> constraint!(ocp, :dynamics!, f!)
```
"""
function constraint!(ocp::OptimalControlModel{time_dependence, dimension_usage}, type::Symbol, f::Function) where {time_dependence, dimension_usage}
    if type ∈ [ :dynamics, :dynamics! ]
        setproperty!(ocp, type, DynamicsFunction{time_dependence, dimension_usage}(f))
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :dynamics, :dynamics! ] or check the arguments of the constraint! method."))
    end
end

#
"""
$(TYPEDSIGNATURES)

Remove a labeled constraint.

# Examples
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

Returns the labels of the constraints as a `Base.keys`.

# Examples
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

# Examples
```jldoctest
julia> constraint(ocp, :eq)
```
"""
function constraint(ocp::OptimalControlModel, label::Symbol)
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

#
"""
$(TYPEDSIGNATURES)

Return a 6-tuple of tuples:
- `(ξl, ξ, ξu)` are control constraints
- `(ηl, η, ηu)` are state constraints
- `(ψl, ψ, ψu)` are mixed constraints
- `(ϕl, ϕ, ϕu)` are boundary constraints
- `(ulb, uind, uub)` are control linear constraints of a subset of indices
- `(xlb, xind, xub)` are state linear constraints of a subset of indices

# Examples
```jldoctest
julia> (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), 
    (ulb, uind, uub), (xlb, xind, xub) = nlp_constraints(ocp)
```
"""
function nlp_constraints(ocp::OptimalControlModel{time_dependence, dimension_usage}) where {time_dependence, dimension_usage}
 
    constraints = ocp.constraints
    n = ocp.state_dimension
    
    ξf = Vector{ControlConstraintFunction}(); ξl = Vector{ctNumber}(); ξu = Vector{ctNumber}()
    ηf = Vector{StateConstraintFunction}(); ηl = Vector{ctNumber}(); ηu = Vector{ctNumber}()
    ψf = Vector{MixedConstraintFunction}(); ψl = Vector{ctNumber}(); ψu = Vector{ctNumber}()
    ϕf = Vector{BoundaryConstraint}(); ϕl = Vector{ctNumber}(); ϕu = Vector{ctNumber}()
    uind = Vector{Int}(); ulb = Vector{ctNumber}(); uub = Vector{ctNumber}()
    xind = Vector{Int}(); xlb = Vector{ctNumber}(); xub = Vector{ctNumber}()

    for (_, c) ∈ constraints
        @match c begin
        (:initial, _, f, lb, ub) => begin
            push!(ϕf, BoundaryConstraint{dimension_usage}((t0, x0, tf, xf) -> f(x0)))
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:final, _, f, lb, ub) => begin
            push!(ϕf, BoundaryConstraint{dimension_usage}((t0, x0, tf, xf) -> f(xf)))
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:boundary, _, f, lb, ub) => begin
            push!(ϕf, BoundaryConstraint{dimension_usage}((t0, x0, tf, xf) -> f(t0, x0, tf, xf)))
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:control, _, f::Function, lb, ub) => begin
            push!(ξf, ControlConstraintFunction{time_dependence, dimension_usage}(f))
            append!(ξl, lb)
            append!(ξu, ub) end
        (:control, _, rg, lb, ub) => begin 
	    append!(uind, rg)
	    append!(ulb, lb)
	    append!(uub, ub) end
        (:state, _, f::Function, lb, ub) => begin
            push!(ηf, StateConstraintFunction{time_dependence, dimension_usage}(f))
            append!(ηl, lb)
            append!(ηu, ub) end
        (:state, _, rg, lb, ub) => begin
	    append!(xind, rg)
	    append!(xlb, lb)
	    append!(xub, ub) end
        (:mixed, _, f, lb, ub) => begin
            push!(ψf, MixedConstraintFunction{time_dependence, dimension_usage}(f))
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

# Examples
```jldoctest
julia> objective!(ocp, :mayer, (t0, x0, tf, xf) -> tf)
julia> objective!(ocp, :lagrange, (x, u) -> x[1]^2 + u[1]^2)
```

# Important

If you set twice the objective, only the last one will be taken into account.
"""
function objective!(ocp::OptimalControlModel{time_dependence, dimension_usage}, type::Symbol, f::Function, criterion::Symbol=__criterion_type()) where {time_dependence, dimension_usage}
    setproperty!(ocp, :mayer, nothing)
    setproperty!(ocp, :lagrange, nothing)
    if criterion ∈ [ :min, :max ]
        ocp.criterion = criterion
    else
        throw(IncorrectArgument("the following criterion is not valid: " * String(criterion) *
        ". Please choose in [ :min, :max ]."))
    end
    if type == :mayer
        setproperty!(ocp, :mayer, MayerObjective{dimension_usage}(f))
    elseif type == :lagrange
        setproperty!(ocp, :lagrange, LagrangeFunction{time_dependence, dimension_usage}(f))
    else
        throw(IncorrectArgument("the following objective is not valid: " * String(objective) *
        ". Please choose in [ :mayer, :lagrange ]."))
    end
end

"""
$(TYPEDSIGNATURES)

Set the criterion to the function `g` and `f⁰`. Type can be `:bolza`. Criterion is `:min` or `:max`.

# Examples
```jldoctest
julia> objective!(ocp, :bolza, (t0, x0, tf, xf) -> tf, (x, u) -> x[1]^2 + u[1]^2) 
```
"""
function objective!(ocp::OptimalControlModel{time_dependence, dimension_usage}, type::Symbol, g::Function, f⁰::Function, criterion::Symbol=__criterion_type()) where {time_dependence, dimension_usage}
    setproperty!(ocp, :mayer, nothing)
    setproperty!(ocp, :lagrange, nothing)
    if criterion ∈ [ :min, :max ]
        ocp.criterion = criterion
    else
        throw(IncorrectArgument("the following criterion is not valid: " * String(criterion) *
        ". Please choose in [ :min, :max ]."))
    end
    if type == :bolza
        setproperty!(ocp, :mayer, MayerObjective{dimension_usage}(g))
        setproperty!(ocp, :lagrange, LagrangeFunction{time_dependence, dimension_usage}(f⁰))
    else
        throw(IncorrectArgument("the following objective is not valid: " * String(objective) *
        ". Please choose :bolza."))
    end
end
