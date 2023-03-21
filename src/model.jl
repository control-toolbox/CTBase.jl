# --------------------------------------------------------------------------------------------------
# Abstract Optimal control model
abstract type AbstractOptimalControlModel end

@with_kw mutable struct OptimalControlModel{time_dependence, dimension_usage} <: AbstractOptimalControlModel
    initial_time::Union{Time,Nothing}=nothing
    final_time::Union{Time,Nothing}=nothing
    time_label::Union{String, Nothing}=nothing
    lagrange::Union{LagrangeFunction{time_dependence, dimension_usage},Nothing}=nothing
    mayer::Union{MayerFunction{dimension_usage},Nothing}=nothing
    criterion::Union{Symbol,Nothing}=nothing
    dynamics::Union{DynamicsFunction{time_dependence, dimension_usage},Nothing}=nothing
    dynamics!::Union{Function,Nothing}=nothing
    state_dimension::Union{Dimension,Nothing}=nothing
    state_labels::Vector{String}=Vector{String}()
    control_dimension::Union{Dimension,Nothing}=nothing
    control_labels::Vector{String}=Vector{String}()
    constraints::Dict{Symbol, Tuple{Vararg{Any}}}=Dict{Symbol, Tuple{Vararg{Any}}}()
end

#
isnonautonomous(time_dependence::Symbol) = :nonautonomous == time_dependence
isautonomous(time_dependence::Symbol) = !isnonautonomous(time_dependence)
isnonautonomous(ocp::OptimalControlModel{time_dependence, dimension_usage}) where {time_dependence, dimension_usage} = isnonautonomous(time_dependence)
isautonomous(ocp::OptimalControlModel) = !isnonautonomous(ocp)

# Constructor
function Model(; time_dependence=_ocp_time_dependence(), dimension_usage=_ocp_dimension_usage()) 
    return OptimalControlModel{time_dependence, dimension_usage}()
end

# -------------------------------------------------------------------------------------------
# getters
dynamics(ocp::OptimalControlModel) = ocp.dynamics
lagrange(ocp::OptimalControlModel) = ocp.lagrange
mayer(ocp::OptimalControlModel) = ocp.mayer
criterion(ocp::OptimalControlModel) = ocp.criterion
ismin(ocp::OptimalControlModel) = criterion(ocp) == :min
initial_time(ocp::OptimalControlModel) = ocp.initial_time
final_time(ocp::OptimalControlModel) = ocp.final_time
control_dimension(ocp::OptimalControlModel) = ocp.control_dimension
control_labels(ocp::OptimalControlModel) = ocp.control_labels
state_dimension(ocp::OptimalControlModel) = ocp.state_dimension
state_labels(ocp::OptimalControlModel) = ocp.state_labels
constraints(ocp::OptimalControlModel) = ocp.constraints

# -------------------------------------------------------------------------------------------
# 
"""
    state!(ocp, n[, labels])

Define the state dimension and possibly the names of each coordinate.

# Examples
```jldoctest
julia> state!(ocp, 2, [ "x₁", "x₂" ])
```
"""
function state!(ocp::OptimalControlModel, n::Dimension, labels::Vector{String}=_state_labels(n))
    ocp.state_dimension = n
    ocp.state_labels = labels
end

"""
    control!(ocp, m[, labels])

Define the control dimension and possibly the names of each coordinate.

# Examples
```jldoctest
julia> control!(ocp, 2, [ "u₁", "u₂" ])
```
"""
function control!(ocp::OptimalControlModel, m::Dimension, labels::Vector{String}=_control_labels(m))
    ocp.control_dimension = m
    ocp.control_labels = labels
end

# -------------------------------------------------------------------------------------------
# 
"""
    time!(ocp, type, t[, label])

Fix initial (resp. final) time, the final (resp. initial) time being variable (free),
when type is `:initial`. And conversely when type is `:final`. 

# Examples
```jldoctest
julia> time!(ocp, :initial, 0, "t")
julia> time!(ocp, :final, 1, "t")
"""
function time!(ocp::OptimalControlModel, type::Symbol, time::Time, label::String=_time_label())
    type_ = Symbol(type, :_time)
    if type_ ∈ [ :initial_time, :final_time ]
        setproperty!(ocp, type_, time)
        ocp.time_label = label
    else
        throw(IncorrectArgument("the following type of time is not valid: " * String(type) *
        ". Please choose in [ :initial, :final ]."))
    end
end

"""
    time!(ocp, t[, label])

Fix initial and final times to `t[1]` and `t[2]`, respectively.

# Examples
```jldoctest
julia> time!(ocp, [ 0, 1 ], "t")
"""
function time!(ocp::OptimalControlModel, times::Times, label::String=_time_label())
    if length(times) != 2
        throw(IncorrectArgument("times must be of dimension 2"))
    end
    ocp.initial_time=times[1]
    ocp.final_time=times[2]
    ocp.time_label = label
end

# -------------------------------------------------------------------------------------------
#
"""
    constraint!(ocp, type, val[, label])

Add an `:initial` or `:final` value constraint on the state.

# Examples
```jldoctest
julia> constraint!(ocp, :initial, [ 0, 0, 0 ])
julia> constraint!(ocp, :final, [ 0, 0, 0 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, val, label::Symbol=gensym(:anonymous))
    if type ∈ [ :initial, :final ] # not allowed for :control or :state
        ocp.constraints[label] = (type, :eq, x -> x, val, val)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final ] or check the arguments of the constraint! method."))
    end
end

"""
    constraint!(ocp, type, rg, val[, label])

Add an `:initial` or `:final` value constraint on a range of the state.

# Examples
```jldoctest
julia> constraint!(ocp, :initial, 2:3, [ 0, 0 ])
julia> constraint!(ocp, :final, 1, 0)
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, rg::Union{Integer, UnitRange{<:Integer}}, val, label::Symbol=gensym(:anonymous))
    if type ∈ [ :initial, :final ] # not allowed for :control or :state (does not make sense)
        ocp.constraints[label] = (type, :eq, x -> x[rg], val, val)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final ] or check the arguments of the constraint! method."))
    end
end

"""
    constraint!(ocp, type, lb, ub[, label])

Add an :initial, :final, :control or :state box constraint (whole range).

# Examples
```jldoctest
julia> constraint!(ocp, :initial, [ 0, 0, 0 ], [ 1, 2, 1 ])
julia> constraint!(ocp, :final, 1, 0, 2)
julia> constraint!(ocp, :control, 1, 0, 2)
julia> constraint!(ocp, :state, [ 0, 0, 0 ], [ 1, 2, 1 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, lb, ub, label::Symbol=gensym(:anonymous))
    if type ∈ [ :initial, :final ]
        ocp.constraints[label] = (type, :ineq, x -> x, lb, ub)
    elseif type == :control
        ocp.constraints[label] = (type, :ineq, lb isa MyNumber ? 1 : 1:control_dimension(ocp), lb, ub) # debug
    elseif type == :state
        ocp.constraints[label] = (type, :ineq, lb isa MyNumber ? 1 : 1:state_dimension(ocp), lb, ub) # debug
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final, :control, :state ] or check the arguments of the constraint! method."))
    end
end

"""
    constraint!(ocp, type, rg, lb, ub[, label])

Add an `:initial`, `:final`, `:control` or `:state` box constraint on a range.

# Examples
```jldoctest
julia> constraint!(ocp, :initial, 2:3, [ 0, 0 ], [1, 2])
julia> constraint!(ocp, :final, 1, 0, 2)
julia> constraint!(ocp, :control, 1, 0, 2)
julia> constraint!(ocp, :state, 2:3, [ 0, 0 ], [1, 2])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, rg::Union{Integer, UnitRange{<:Integer}}, lb, ub, label::Symbol=gensym(:anonymous))
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
    constraint!(ocp, type, f, val[, label])

Add a `:boundary`, `:control`, `:state` or `:mixed` value functional constraint.

# Examples
```jldoctest
julia> constraint!(ocp, :boundary, f, [ 0, 0 ])
julia> constraint!(ocp, :control, f, [ 0, 0 ])
julia> constraint!(ocp, :state, f, [ 0, 0 ])
julia> constraint!(ocp, :mixed, f, [ 0, 0 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, val, label::Symbol=gensym(:anonymous))
    if type ∈ [ :boundary, :control, :state, :mixed ]
        ocp.constraints[label] = (type, :eq, f, val, val)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :boundary, :control, :state, :mixed ] or check the arguments of the constraint! method."))
    end
end

"""
    constraint!(ocp, type, f, lb, ub[, label])

Add a `:boundary`, `:control`, `:state` or `:mixed` box functional constraint.

# Examples
```jldoctest
julia> constraint!(ocp, :boundary, f, [ 0, 0 ], [ 1, 2 ])
julia> constraint!(ocp, :control, f, [ 0, 0 ], [ 1, 2 ])
julia> constraint!(ocp, :state, f, [ 0, 0 ], [ 1, 2 ])
julia> constraint!(ocp, :mixed, f, [ 0, 0 ], [ 1, 2 ])
```
"""
function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, lb, ub, label::Symbol=gensym(:anonymous))
    if type ∈ [ :boundary, :control, :state, :mixed ]
        ocp.constraints[label] = (type, :ineq, f, lb, ub)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :boundary, :control, :state, :mixed ] or check the arguments of the constraint! method."))
    end
end

"""
    constraint!(ocp, type, f)

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
    remove_constraint!(ocp, label)

Remove a labeled constraint.

# Examples
```jldoctest
julia> remove_constraint!(ocp, :con)
```
"""
function remove_constraint!(ocp::OptimalControlModel, label::Symbol)
    delete!(ocp.constraints, label)
end

#
"""
    constraint(ocp, label)

Retrieve a labeled constraint. The result is a function associated with the constraint
computation (not taking into account provided value / bounds).

# Examples
```jldoctest
julia> constraint(ocp, :con)
```
"""
function constraint(ocp::OptimalControlModel, label::Symbol)
    con = ocp.constraints[label]
    @match con begin
        (:initial , _, f          , _, _) => return f
        (:final   , _, f          , _, _) => return f
        (:boundary, _, f          , _, _) => return f 
        (:control , _, f::Function, _, _) => return f 
        (:control , _, rg         , _, _) => return u -> u[rg]
        (:state   , _, f::Function, _, _) => return f 
        (:state   , _, rg         , _, _) => return x -> x[rg]
        (:mixed   , _, f          , _, _) => return f 
        _ => throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
             ". Please choose within [ :initial, :final, :boundary, :control, :state, :mixed ]."))
    end
end

#
"""
    nlp_constraints(ocp)

Return a 6-tuple of tuples:
- `(ξl, ξ, ξu)` are control constraints
- `(ηl, η, ηu)` are state constraints
- `(ψl, ψ, ψu)` are mixed constraints
- `(ϕl, ϕ, ϕu)` are boundary constraints
- `(ulb, uind, uub)` are control linear constraints of a subset of indices
- `(xlb, xind, xub)` are state linear constraints of a subset of indices

# Examples
```jldoctest
julia> (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (ulb, uind, uub), (xlb, xind, xub) = nlp_constraints(ocp)
```
"""
function nlp_constraints(ocp::OptimalControlModel{time_dependence, dimension_usage}) where {time_dependence, dimension_usage}
 
    constraints = ocp.constraints
    n = ocp.state_dimension
    
    ξf = Vector{ControlConstraintFunction}(); ξl = Vector{MyNumber}(); ξu = Vector{MyNumber}()
    ηf = Vector{StateConstraintFunction}(); ηl = Vector{MyNumber}(); ηu = Vector{MyNumber}()
    ψf = Vector{MixedConstraintFunction}(); ψl = Vector{MyNumber}(); ψu = Vector{MyNumber}()
    ϕf = Vector{BoundaryConstraintFunction}(); ϕl = Vector{MyNumber}(); ϕu = Vector{MyNumber}()
    uind = Vector{Int}(); ulb = Vector{MyNumber}(); uub = Vector{MyNumber}()
    xind = Vector{Int}(); xlb = Vector{MyNumber}(); xub = Vector{MyNumber}()

    for (_, c) ∈ constraints
        @match c begin
        (:initial, _, f, lb, ub) => begin
            push!(ϕf, BoundaryConstraintFunction{dimension_usage}((t0, x0, tf, xf) -> f(x0)))
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:final, _, f, lb, ub) => begin
            push!(ϕf, BoundaryConstraintFunction{dimension_usage}((t0, x0, tf, xf) -> f(xf)))
            append!(ϕl, lb)
            append!(ϕu, ub) end
        (:boundary, _, f, lb, ub) => begin
            push!(ϕf, BoundaryConstraintFunction{dimension_usage}((t0, x0, tf, xf) -> f(t0, x0, tf, xf)))
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
        val = Vector{MyNumber}()
        for i ∈ 1:length(ξf) append!(val, ξf[i](t, u)) end
        return val
    end 

    function η(t, x)
        val = Vector{MyNumber}()
        for i ∈ 1:length(ηf) append!(val, ηf[i](t, x)) end
        return val
    end 

    function ψ(t, x, u)
        val = Vector{MyNumber}()
        for i ∈ 1:length(ψf) append!(val, ψf[i](t, x, u)) end
        return val
    end 

    function ϕ(t0, x0, tf, xf)
        val = Vector{MyNumber}()
        for i ∈ 1:length(ϕf) append!(val, ϕf[i](t0, x0, tf, xf)) end
        return val
    end 

    return (ξl, ξ, ξu), (ηl, η, ηu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu), (ulb, uind, uub), (xlb, xind, xub)

end

# -------------------------------------------------------------------------------------------
# 
"""
    objective!(ocp, type, f, criterion=:min)

Set the criterion to the function `f`. Type can be `:mayer` or `:lagrange`. Criterion is `:min` or `:max`.

# Examples
```jldoctest
julia> objective!(ocp, (t0, x0, tf, xf) -> tf, :mayer) 
```
"""
function objective!(ocp::OptimalControlModel{time_dependence, dimension_usage}, type::Symbol, f::Function, criterion::Symbol=:min) where {time_dependence, dimension_usage}
    setproperty!(ocp, :mayer, nothing)
    setproperty!(ocp, :lagrange, nothing)
    if criterion ∈ [ :min, :max ]
        ocp.criterion = criterion
    else
        throw(IncorrectArgument("the following criterion is not valid: " * String(criterion) *
        ". Please choose in [ :min, :max ]."))
    end
    if type == :mayer
        setproperty!(ocp, :mayer, MayerFunction{dimension_usage}(f))
    elseif type == :lagrange
        setproperty!(ocp, :lagrange, LagrangeFunction{time_dependence, dimension_usage}(f))
    else
        throw(IncorrectArgument("the following objective is not valid: " * String(objective) *
        ". Please choose in [ :mayer, :lagrange ]."))
    end
end
