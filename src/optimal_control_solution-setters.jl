# ----------------------------------------------------------------------
#
# Interaction with an optimal control solution that affect it. Setters / Constructors.
#

"""
$(TYPEDSIGNATURES)

Constructor from an optimal control problem. Internal.
"""
function __OptimalControlSolution(ocp::OptimalControlModel;
    state::Union{Nothing, Function}=nothing,
    control::Union{Nothing, Function}=nothing,
    objective::Union{Nothing, ctNumber}=nothing,
    costate::Union{Nothing, Function}=nothing,
    time_grid::Union{Nothing, TimesDisc}=nothing,
    variable::Union{Nothing, Variable}=nothing,
    iterations::Union{Nothing, Integer}=nothing,
    stopping::Union{Nothing, Symbol}=nothing,
    message::Union{Nothing, String}=nothing,
    success::Union{Nothing, Bool}=nothing,
    infos::Dict{Symbol, Any}=Dict{Symbol, Any}())::OptimalControlSolution

    #
    sol = OptimalControlSolution()

    # data from ocp 
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

    # data from args 
    sol.state = state
    sol.control = control
    sol.objective = objective 
    sol.costate = costate 
    sol.time_grid = time_grid 
    sol.variable = variable 
    sol.iterations = iterations 
    sol.stopping = stopping
    sol.message = message
    sol.success = success
    sol.infos = infos

    return sol

end

"""
$(TYPEDSIGNATURES)

Constructor from an optimal control problem for a Fixed ocp.
"""
function OptimalControlSolution(ocp::OptimalControlModel{<:TimeDependence, Fixed};
    state::Function,
    control::Function,
    objective::ctNumber,
    variable::Union{Nothing, Variable}=nothing,
    costate::Union{Nothing, Function}=nothing,
    time_grid::Union{Nothing, TimesDisc}=nothing,
    iterations::Union{Nothing, Integer}=nothing,
    stopping::Union{Nothing, Symbol}=nothing,
    message::Union{Nothing, String}=nothing,
    success::Union{Nothing, Bool}=nothing,
    infos::Dict{Symbol, Any}=Dict{Symbol, Any}())::OptimalControlSolution

    return __OptimalControlSolution(ocp;
    state=state,
    control=control,
    objective=objective,
    costate=costate,
    time_grid=time_grid,
    variable=variable,
    iterations=iterations,
    stopping=stopping,
    message=message,
    success=success,
    infos=infos)

end

"""
$(TYPEDSIGNATURES)

Constructor from an optimal control problem for a NonFixed ocp.
"""
function OptimalControlSolution(ocp::OptimalControlModel{<:TimeDependence, NonFixed};
    state::Function,
    control::Function,
    objective::ctNumber,
    variable::Variable,
    costate::Union{Nothing, Function}=nothing,
    time_grid::Union{Nothing, TimesDisc}=nothing,
    iterations::Union{Nothing, Integer}=nothing,
    stopping::Union{Nothing, Symbol}=nothing,
    message::Union{Nothing, String}=nothing,
    success::Union{Nothing, Bool}=nothing,
    infos::Dict{Symbol, Any}=Dict{Symbol, Any}())::OptimalControlSolution

    return __OptimalControlSolution(ocp;
    state=state,
    control=control,
    objective=objective,
    costate=costate,
    time_grid=time_grid,
    variable=variable,
    iterations=iterations,
    stopping=stopping,
    message=message,
    success=success,
    infos=infos)

end