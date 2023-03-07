# --------------------------------------------------------------------------------------------------
# Abstract Optimal control model
abstract type AbstractOptimalControlModel end

@with_kw mutable struct OptimalControlModel{time_dependence, scalar_vectorial} <: AbstractOptimalControlModel
    initial_time::Union{Time,Nothing}=nothing
    final_time::Union{Time,Nothing}=nothing
    lagrange::Union{LagrangeFunction{time_dependence, scalar_vectorial},Nothing}=nothing
    mayer::Union{MayerFunction{scalar_vectorial},Nothing}=nothing
    criterion::Union{Symbol,Nothing}=nothing
    dynamics::Union{DynamicsFunction{time_dependence, scalar_vectorial},Nothing}=nothing
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
isnonautonomous(ocp::OptimalControlModel{time_dependence, scalar_vectorial}) where {time_dependence, scalar_vectorial} = isnonautonomous(time_dependence)
isautonomous(ocp::OptimalControlModel) = !isnonautonomous(ocp)

# Constructors
abstract type Model{td, sv} end # c'est un peu du bricolage ça
function Model{time_dependence, scalar_vectorial}() where {time_dependence, scalar_vectorial}
    return OptimalControlModel{time_dependence, scalar_vectorial}()
end
function Model{time_dependence}() where {time_dependence}
    return OptimalControlModel{time_dependence, _ocp_scalar_vectorial()}()
end
Model() = Model{_ocp_time_dependence(), _ocp_scalar_vectorial()}() # default value

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
state_dimension(ocp::OptimalControlModel) = ocp.state_dimension
constraints(ocp::OptimalControlModel) = ocp.constraints
function initial_condition(ocp::OptimalControlModel) 
    cs = constraints(ocp)
    x0 = nothing
    for (_, c) ∈ cs
        type, _, _, val = c
        if type == :initial
             x0 = val
        end
    end
    return x0
end
function final_condition(ocp::OptimalControlModel) 
    cs = constraints(ocp)
    xf = nothing
    for (_, c) ∈ cs
        type, _, _, val = c
        if type == :final
             xf = val
        end
    end
    return xf
end
function initial_constraint(ocp::OptimalControlModel) 
    cs = constraints(ocp)
    c0 = nothing
    for (_, c) ∈ cs
        type, _, f, val = c
        if type == :initial
            c0 = x -> f(x) - val
        end
    end
    return c0
end
function final_constraint(ocp::OptimalControlModel) 
    cs = constraints(ocp)
    cf = nothing
    for (_, c) ∈ cs
        type, _, f, val = c
        if type == :final
            cf = x -> f(x) - val
        end
    end
    return cf
end

# -------------------------------------------------------------------------------------------
# 
function state!(ocp::OptimalControlModel, n::Dimension; labels::Vector{String}=_state_labels(n))
    ocp.state_dimension = n
    ocp.state_labels = labels
end

function control!(ocp::OptimalControlModel, m::Dimension; labels::Vector{String}=_control_labels(m))
    ocp.control_dimension = m
    ocp.control_labels = labels
end

# -------------------------------------------------------------------------------------------
# 
function time!(ocp::OptimalControlModel, type::Symbol, time::Time)
    type_ = Symbol(type, :_time)
    if type_ ∈ [ :initial_time, :final_time ]
        setproperty!(ocp, type_, time)
    else
        throw(IncorrectArgument("the following type of time is not valid: " * String(type) *
        ". Please choose in [ :initial_time, :final_time ]."))
    end
end

function time!(ocp::OptimalControlModel, times::Times)
    if length(times) != 2
        throw(IncorrectArgument("times must be of dimension 2"))
    end
    ocp.initial_time=times[1]
    ocp.final_time=times[2]
end

# -------------------------------------------------------------------------------------------
#
# debug: starts here
function constraint!(ocp::OptimalControlModel, type::Symbol, val::State, label::Symbol=gensym(:anonymous))
    if type ∈ [ :initial, :final ]
        ocp.constraints[label] = (type, :eq, x -> x, val)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final ] or check the arguments of the constraint! method."))
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, lb::Real, ub::Real, label::Symbol=gensym(:anonymous))
    if type ∈ [ :initial, :final ]
        ocp.constraints[label] = (type, :ineq, x -> x, ub, lb)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final ] or check the arguments of the constraint! method."))
    end
end

function constraint!(ocp::OptimalControlModel{time_dependence, scalar_vectorial}, type::Symbol, f::Function) where {time_dependence, scalar_vectorial}
    if type ∈ [ :dynamics, :dynamics! ]
        setproperty!(ocp, type, DynamicsFunction{time_dependence, scalar_vectorial}(f))
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :dynamics, :dynamics! ] or check the arguments of the constraint! method."))
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, val::Real, label::Symbol=gensym(:anonymous))
    if type ∈ [ :control, :mixed, :boundary ]
        ocp.constraints[label] = (type, :eq, f, val)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :control, :mixed, :boundary ] or check the arguments of the constraint! method."))
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, lb::Real, ub::Real, label::Symbol=gensym(:anonymous))
    if type ∈ [ :control, :mixed, :boundary ]
        ocp.constraints[label] = (type, :ineq, f, lb, ub)
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :control, :mixed, :boundary ] or check the arguments of the constraint! method."))
    end
end

#
function remove_constraint!(ocp::OptimalControlModel, label::Symbol)
    delete!(ocp.constraints, label)
end

#
function constraint(ocp::OptimalControlModel{time_dependence, scalar_vectorial}, label::Symbol) where {time_dependence, scalar_vectorial}
    con = ocp.constraints[label]
    if length(con) == 5
        throw(IncorrectArgument("the following constraint is not valid: " * String(label) *
        ". You must choose the bound in [ :lower, :upper ]."))
    end
    type, _, f, val = con
    if type ∈ [ :initial, :final ]
        return x -> f(x) - val
    elseif type == :boundary
        return (t0, x0, tf, xf) -> f(t0, x0, tf, xf) - val
    elseif type == :control
        return isautonomous(time_dependence) ? u -> f(u) - val : (t, u) -> f(t, u) - val
    elseif type == :mixed
        return isautonomous(time_dependence) ? (x, u) -> f(x, u) - val : (t, x, u) -> f(t, x, u) - val
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final, :boundary, :control, :mixed ]."))
    end
    return nothing
end

#
function constraint(ocp::OptimalControlModel{time_dependence, scalar_vectorial}, label::Symbol, bound::Symbol) where {time_dependence, scalar_vectorial}
    # constraints are all >= 0
    con = ocp.constraints[label]
    if length(con) == 4
        throw(IncorrectArgument("the following constraint is not valid: " * String(label) *
        ". You can't choose a bound."))
    end
    type, _, f, lb, ub = con
    if !( bound ∈ [ :lower, :upper ] )
        throw(IncorrectArgument("the following bound is not valid: " * String(bound) *
        ". Please choose in [ :lower, :upper ]."))
    end
    if (bound == :lower && lb == -Inf) || (bound == :upper && ub == Inf)
        throw(IncorrectArgument("there is no constraint for the bound: " * String(bound)))
    end
    if type ∈ [ :initial, :final ]
        return bound == :lower ? x -> f(x) - lb : x -> ub - f(x)
    elseif type == :boundary
        return bound == :lower ? (t0, x0, tf, xf) -> f(t0, x0, tf, xf) - lb : (t0, x0, tf, xf) -> ub - f(t0, x0, tf, xf)
    elseif type == :control
        if isautonomous(time_dependence)
            return bound == :lower ? u -> f(u) - lb : u -> ub - f(u)
        else
            return bound == :lower ? (t, u) -> f(t, u) - lb : (t, u) -> ub - f(t, u)
        end
    elseif type == :mixed
        if isautonomous(time_dependence)
            return bound == :lower ? (x, u) -> f(x, u) - lb : (x, u) -> ub - f(x, u) 
        else
            return bound == :lower ? (t, x, u) -> f(t, x, u) - lb : (t, x, u) -> ub - f(t, x, u) 
        end
    else
        throw(IncorrectArgument("the following type of constraint is not valid: " * String(type) *
        ". Please choose in [ :initial, :final, :boundary, :control, :mixed ]."))
    end
    return nothing
end

#
function nlp_constraints(ocp::OptimalControlModel{time_dependence, scalar_vectorial}) where {time_dependence, scalar_vectorial}
    #
    constraints = ocp.constraints
    n = ocp.state_dimension
    
    ξf = Vector{ControlConstraintFunction}(); ξl = Vector{MyNumber}(); ξu = Vector{MyNumber}()
    ψf = Vector{MixedConstraintFunction}(); ψl = Vector{MyNumber}(); ψu = Vector{MyNumber}()
    ϕf = Vector{BoundaryConstraintFunction}(); ϕl = Vector{MyNumber}(); ϕu = Vector{MyNumber}()

    for (_, c) ∈ constraints
        if c[1] == :control
            push!(ξf, ControlConstraintFunction{time_dependence, scalar_vectorial}(c[3]))
            append!(ξl, c[4])
            append!(ξu, c[2] == :eq ? c[4] : c[5])
        elseif c[1] == :mixed
            push!(ψf, MixedConstraintFunction{time_dependence, scalar_vectorial}(c[3]))
            append!(ψl, c[4])
            append!(ψu, c[2] == :eq ? c[4] : c[5])
        elseif c[1] == :initial
            push!(ϕf, BoundaryConstraintFunction{scalar_vectorial}((t0, x0, tf, xf) -> c[3](x0)))
            append!(ϕl, c[4])
            append!(ϕu, c[2] == :eq ? c[4] : c[5])
        elseif c[1] == :final
            push!(ϕf, BoundaryConstraintFunction{scalar_vectorial}((t0, x0, tf, xf) -> c[3](xf)))
            append!(ϕl, c[4])
            append!(ϕu, c[2] == :eq ? c[4] : c[5])
        elseif c[1] == :boundary
            push!(ϕf, BoundaryConstraintFunction{scalar_vectorial}((t0, x0, tf, xf) -> c[3](t0, x0, tf, xf)))
            append!(ϕl, c[4])
            append!(ϕu, c[2] == :eq ? c[4] : c[5])
        end
    end

#    ξ!(val, u) = [ val[i] = ξf[i](u) for i ∈ 1:length(ξf) ]
#    ψ!(val, x, u) = [ val[i] = ψf[i](x, u) for i ∈ 1:length(ψf) ]
#    ϕ!(val, t0, x0, tf, xf) = [ val[i] = ϕf[i](t0, x0, tf, xf) for i ∈ 1:length(ϕf) ]

    function ξ(t, u)
        val = Vector{MyNumber}()
        for i ∈ 1:length(ξf) append!(val, ξf[i](t, u)) end
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

    return (ξl, ξ, ξu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu)

end

# -------------------------------------------------------------------------------------------
# 
function objective!(ocp::OptimalControlModel{time_dependence, scalar_vectorial}, type::Symbol, f::Function, criterion::Symbol=:min) where {time_dependence, scalar_vectorial}
    setproperty!(ocp, :mayer, nothing)
    setproperty!(ocp, :lagrange, nothing)
    if criterion ∈ [ :min, :max ]
        ocp.criterion = criterion
    else
        throw(IncorrectArgument("the following criterion is not valid: " * String(criterion) *
        ". Please choose in [ :min, :max ]."))
    end
    if type == :mayer
        setproperty!(ocp, :mayer, MayerFunction{scalar_vectorial}(f))
    elseif type == :lagrange
        setproperty!(ocp, :lagrange, LagrangeFunction{time_dependence, scalar_vectorial}(f))
    else
        throw(IncorrectArgument("the following objective is not valid: " * String(objective) *
        ". Please choose in [ :mayer, :lagrange ]."))
    end
end
