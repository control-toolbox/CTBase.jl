# ----------------------------------------------------------------------
# 
# Definition of an optimal control model
#
"""
$(TYPEDEF)

**Fields**

$(TYPEDFIELDS)
"""
@with_kw mutable struct OptimalControlModel{
    time_dependence<:TimeDependence,variable_dependence<:VariableDependence
} <: AbstractOptimalControlModel
    model_expression::Union{Nothing,Expr} = nothing
    initial_time::Union{Time,Index,Nothing} = nothing
    initial_time_name::Union{String,Nothing} = nothing
    final_time::Union{Time,Index,Nothing} = nothing
    final_time_name::Union{String,Nothing} = nothing
    time_name::Union{String,Nothing} = nothing
    control_dimension::Union{Dimension,Nothing} = nothing
    control_components_names::Union{Vector{String},Nothing} = nothing
    control_name::Union{String,Nothing} = nothing
    state_dimension::Union{Dimension,Nothing} = nothing
    state_components_names::Union{Vector{String},Nothing} = nothing
    state_name::Union{String,Nothing} = nothing
    variable_dimension::Union{Dimension,Nothing} = nothing
    variable_components_names::Union{Vector{String},Nothing} = nothing
    variable_name::Union{String,Nothing} = nothing
    lagrange::Union{Lagrange,Lagrange!,Nothing} = nothing
    mayer::Union{Mayer,Mayer!,Nothing} = nothing
    criterion::Union{Symbol,Nothing} = nothing
    dynamics::Union{Dynamics,Dynamics!,Nothing} = nothing
    constraints::Dict{Symbol,Tuple{Vararg{Any}}} = Dict{Symbol,Tuple{Vararg{Any}}}()
    dim_control_constraints::Union{Dimension,Nothing} = nothing
    dim_state_constraints::Union{Dimension,Nothing} = nothing
    dim_mixed_constraints::Union{Dimension,Nothing} = nothing
    dim_boundary_constraints::Union{Dimension,Nothing} = nothing
    dim_variable_constraints::Union{Dimension,Nothing} = nothing
    dim_control_range::Union{Dimension,Nothing} = nothing
    dim_state_range::Union{Dimension,Nothing} = nothing
    dim_variable_range::Union{Dimension,Nothing} = nothing
    in_place::Union{Bool,Nothing} = nothing
end

# ----------------------------------------------------------------------
#
# checkings: internal functions
#
"""
$(TYPEDSIGNATURES)

"""
function __is_variable_not_set(ocp::OptimalControlModel)
    conditions = [
        isnothing(ocp.variable_dimension),
        isnothing(ocp.variable_name),
        isnothing(ocp.variable_components_names),
    ]
    @assert all(conditions) || !any(conditions) # either all or none
    return isnothing(ocp.variable_dimension)
end

"""
$(TYPEDSIGNATURES)

"""
__is_variable_set(ocp::OptimalControlModel) = !__is_variable_not_set(ocp)

"""
$(TYPEDSIGNATURES)

"""
function __is_time_not_set(ocp::OptimalControlModel)
    conditions = [
        isnothing(ocp.initial_time),
        isnothing(ocp.initial_time_name),
        isnothing(ocp.final_time),
        isnothing(ocp.final_time_name),
        isnothing(ocp.time_name),
    ]
    @assert all(conditions) || !any(conditions) # either all or none
    return isnothing(ocp.initial_time)
end

"""
$(TYPEDSIGNATURES)

"""
__is_time_set(ocp::OptimalControlModel) = !__is_time_not_set(ocp)

"""
$(TYPEDSIGNATURES)

"""
function __is_state_not_set(ocp::OptimalControlModel)
    conditions = [
        isnothing(ocp.state_dimension),
        isnothing(ocp.state_name),
        isnothing(ocp.state_components_names),
    ]
    @assert all(conditions) || !any(conditions) # either all or none
    return isnothing(ocp.state_dimension)
end

"""
$(TYPEDSIGNATURES)

"""
__is_state_set(ocp::OptimalControlModel) = !__is_state_not_set(ocp)

"""
$(TYPEDSIGNATURES)

"""
function __is_control_not_set(ocp::OptimalControlModel)
    conditions = [
        isnothing(ocp.control_dimension),
        isnothing(ocp.control_name),
        isnothing(ocp.control_components_names),
    ]
    @assert all(conditions) || !any(conditions) # either all or none
    return isnothing(ocp.control_dimension)
end

"""
$(TYPEDSIGNATURES)

"""
__is_control_set(ocp::OptimalControlModel) = !__is_control_not_set(ocp)

"""
$(TYPEDSIGNATURES)

"""
__is_dynamics_not_set(ocp::OptimalControlModel) = isnothing(ocp.dynamics)

"""
$(TYPEDSIGNATURES)

"""
__is_dynamics_set(ocp::OptimalControlModel) = !__is_dynamics_not_set(ocp)

"""
$(TYPEDSIGNATURES)

"""
function __is_objective_not_set(ocp::OptimalControlModel)
    conditions = [isnothing(ocp.lagrange) && isnothing(ocp.mayer), isnothing(ocp.criterion)]
    @assert all(conditions) || !any(conditions) # either all or none
    return isnothing(ocp.criterion)
end

"""
$(TYPEDSIGNATURES)

"""
__is_objective_set(ocp::OptimalControlModel) = !__is_objective_not_set(ocp)

"""
$(TYPEDSIGNATURES)

"""
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

"""
$(TYPEDSIGNATURES)

"""
__is_initial_time_free(ocp) = ocp.initial_time isa Index

"""
$(TYPEDSIGNATURES)

"""
__is_final_time_free(ocp) = ocp.final_time isa Index

"""
$(TYPEDSIGNATURES)

"""
__is_incomplete(ocp) = begin
    __is_time_not_set(ocp) ||
    __is_state_not_set(ocp) ||
    __is_control_not_set(ocp) ||
    __is_dynamics_not_set(ocp) ||
    __is_objective_not_set(ocp) ||
    (__is_variable_not_set(ocp) && is_variable_dependent(ocp))
end

"""
$(TYPEDSIGNATURES)

"""
__is_complete(ocp) = !__is_incomplete(ocp)

"""
$(TYPEDSIGNATURES)

"""
__is_criterion_valid(criterion::Symbol) = criterion ∈ [:min, :max]

# ----------------------------------------------------------------------
#
# checkings: internal functions, return exceptions
#

"""
$(TYPEDSIGNATURES)

Throw ```IncorrectArgument``` exception if dependencies arguments are incorrect.

"""
function __check_dependencies(dependencies::Tuple{Vararg{DataType}})
    size(filter(p -> p <: VariableDependence, dependencies), 1) > 1 && throw(
        IncorrectArgument(
            "the number of arguments about variable dependence must be equal at most to 1",
        ),
    )
    size(filter(p -> p <: TimeDependence, dependencies), 1) > 1 && throw(
        IncorrectArgument(
            "the number of arguments about time dependence must be equal at most to 1"
        ),
    )
    size(dependencies, 1) > 2 && throw(
        IncorrectArgument(
            "the number of arguments about dependencies must be equal at most to 2"
        ),
    )
    return size(
        filter(p -> !(p <: Union{TimeDependence,VariableDependence}), dependencies), 1
    ) > 0 && throw(
        IncorrectArgument(
            "wrong type arguments, possible arguments are: NonAutonomous, Autonomous, Fixed, NonFixed",
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Throw ```UnauthorizedCall``` exception if the state of an ocp is not set.

"""
function __check_state_set(ocp::OptimalControlModel)
    return __is_state_not_set(ocp) &&
        throw(UnauthorizedCall("the state dimension has to be set before."))
end

"""
$(TYPEDSIGNATURES)

Throw ```UnauthorizedCall``` exception if the control of an ocp is not set.

"""
function __check_control_set(ocp::OptimalControlModel)
    return __is_control_not_set(ocp) &&
        throw(UnauthorizedCall("the control dimension has to be set before."))
end

"""
$(TYPEDSIGNATURES)

Throw ```UnauthorizedCall``` exception if the time of an ocp is not set.

"""
function __check_is_time_set(ocp::OptimalControlModel)
    return __is_time_not_set(ocp) &&
        throw(UnauthorizedCall("the time dimension has to be set before."))
end

"""
$(TYPEDSIGNATURES)

Throw ```UnauthorizedCall``` exception if the variable of an ocp is not set.

"""
function __check_variable_set(ocp::OptimalControlModel{<:TimeDependence,NonFixed})
    return __is_variable_not_set(ocp) &&
        throw(UnauthorizedCall("the variable dimension has to be set before."))
end

"""
$(TYPEDSIGNATURES)

Do nothing, no variable for fixed ocp.

"""
function __check_variable_set(ocp::OptimalControlModel{<:TimeDependence,Fixed})
    return nothing
end

"""
$(TYPEDSIGNATURES)

Check if the parameters of an ocp are set.

"""
function __check_all_set(ocp::OptimalControlModel)
    __check_state_set(ocp)
    __check_control_set(ocp)
    __check_is_time_set(ocp)
    return __check_variable_set(ocp)
end
