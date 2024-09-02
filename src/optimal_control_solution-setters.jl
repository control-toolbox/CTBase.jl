# ----------------------------------------------------------------------
#
# Interaction with an optimal control solution that affect it. Setters / Constructors.
#

"""
$(TYPEDSIGNATURES)

Constructor from an optimal control problem. Internal.
"""
function __OptimalControlSolution(
    ocp::OptimalControlModel;
    state::Union{Nothing, Function} = nothing,
    control::Union{Nothing, Function} = nothing,
    objective::Union{Nothing, ctNumber} = nothing,
    costate::Union{Nothing, Function} = nothing,
    time_grid::Union{Nothing, TimesDisc} = nothing,
    variable::Union{Nothing, Variable} = nothing,
    iterations::Union{Nothing, Integer} = nothing,
    stopping::Union{Nothing, Symbol} = nothing,
    message::Union{Nothing, String} = nothing,
    success::Union{Nothing, Bool} = nothing,
    infos::Dict{Symbol, Any} = Dict{Symbol, Any}(),
    boundary_constraints::Union{Nothing, ctVector} = nothing,
    mult_boundary_constraints::Union{Nothing, ctVector} = nothing,
    variable_constraints::Union{Nothing, ctVector} = nothing,
    mult_variable_constraints::Union{Nothing, ctVector} = nothing,
    mult_variable_box_lower::Union{Nothing, ctVector} = nothing,
    mult_variable_box_upper::Union{Nothing, ctVector} = nothing,
    control_constraints::Union{Nothing, Function} = nothing,
    mult_control_constraints::Union{Nothing, Function} = nothing,
    state_constraints::Union{Nothing, Function} = nothing,
    mult_state_constraints::Union{Nothing, Function} = nothing,
    mixed_constraints::Union{Nothing, Function} = nothing,
    mult_mixed_constraints::Union{Nothing, Function} = nothing,
    mult_state_box_lower::Union{Nothing, Function} = nothing,
    mult_state_box_upper::Union{Nothing, Function} = nothing,
    mult_control_box_lower::Union{Nothing, Function} = nothing,
    mult_control_box_upper::Union{Nothing, Function} = nothing,
)::OptimalControlSolution

    #
    sol = OptimalControlSolution()

    # data from ocp 
    sol.initial_time_name = initial_time_name(ocp)
    sol.final_time_name = final_time_name(ocp)
    sol.time_name = time_name(ocp)
    sol.control_dimension = control_dimension(ocp)
    sol.control_components_names = control_components_names(ocp)
    sol.control_name = control_name(ocp)
    sol.state_dimension = state_dimension(ocp)
    sol.state_components_names = state_components_names(ocp)
    sol.state_name = state_name(ocp)
    sol.variable_dimension = variable_dimension(ocp)
    sol.variable_components_names = variable_components_names(ocp)
    sol.variable_name = variable_name(ocp)

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

    sol.boundary_constraints = boundary_constraints
    sol.mult_boundary_constraints = mult_boundary_constraints
    sol.variable_constraints = variable_constraints
    sol.mult_variable_constraints = mult_variable_constraints
    sol.mult_variable_box_lower = mult_variable_box_lower
    sol.mult_variable_box_upper = mult_variable_box_upper

    sol.control_constraints = control_constraints
    sol.mult_control_constraints = mult_control_constraints
    sol.state_constraints = state_constraints
    sol.mult_state_constraints = mult_state_constraints
    sol.mixed_constraints = mixed_constraints
    sol.mult_mixed_constraints = mult_mixed_constraints
    sol.mult_state_box_lower = mult_state_box_lower
    sol.mult_state_box_upper = mult_state_box_upper
    sol.mult_control_box_lower = mult_control_box_lower
    sol.mult_control_box_upper = mult_control_box_upper

    return sol
end

"""
$(TYPEDSIGNATURES)

Constructor from an optimal control problem for a Fixed ocp.
"""
function OptimalControlSolution(
    ocp::OptimalControlModel{<:TimeDependence, Fixed};
    state::Function,
    control::Function,
    objective::ctNumber,
    variable::Union{Nothing, Variable} = nothing,
    costate::Union{Nothing, Function} = nothing,
    time_grid::Union{Nothing, TimesDisc} = nothing,
    iterations::Union{Nothing, Integer} = nothing,
    stopping::Union{Nothing, Symbol} = nothing,
    message::Union{Nothing, String} = nothing,
    success::Union{Nothing, Bool} = nothing,
    infos::Dict{Symbol, Any} = Dict{Symbol, Any}(),
    boundary_constraints::Union{Nothing, ctVector} = nothing,
    mult_boundary_constraints::Union{Nothing, ctVector} = nothing,
    variable_constraints::Union{Nothing, ctVector} = nothing,
    mult_variable_constraints::Union{Nothing, ctVector} = nothing,
    mult_variable_box_lower::Union{Nothing, ctVector} = nothing,
    mult_variable_box_upper::Union{Nothing, ctVector} = nothing,
    control_constraints::Union{Nothing, Function} = nothing,
    mult_control_constraints::Union{Nothing, Function} = nothing,
    state_constraints::Union{Nothing, Function} = nothing,
    mult_state_constraints::Union{Nothing, Function} = nothing,
    mixed_constraints::Union{Nothing, Function} = nothing,
    mult_mixed_constraints::Union{Nothing, Function} = nothing,
    mult_state_box_lower::Union{Nothing, Function} = nothing,
    mult_state_box_upper::Union{Nothing, Function} = nothing,
    mult_control_box_lower::Union{Nothing, Function} = nothing,
    mult_control_box_upper::Union{Nothing, Function} = nothing,
)::OptimalControlSolution
    return __OptimalControlSolution(
        ocp;
        state = state,
        control = control,
        objective = objective,
        costate = costate,
        time_grid = time_grid,
        variable = variable,
        iterations = iterations,
        stopping = stopping,
        message = message,
        success = success,
        infos = infos,
        boundary_constraints = boundary_constraints,
        mult_boundary_constraints = mult_boundary_constraints,
        variable_constraints = variable_constraints,
        mult_variable_constraints = mult_variable_constraints,
        mult_variable_box_lower = mult_variable_box_lower,
        mult_variable_box_upper = mult_variable_box_upper,
        control_constraints = control_constraints,
        mult_control_constraints = mult_control_constraints,
        state_constraints = state_constraints,
        mult_state_constraints = mult_state_constraints,
        mixed_constraints = mixed_constraints,
        mult_mixed_constraints = mult_mixed_constraints,
        mult_state_box_lower = mult_state_box_lower,
        mult_state_box_upper = mult_state_box_upper,
        mult_control_box_lower = mult_control_box_lower,
        mult_control_box_upper = mult_control_box_upper,
    )
end

"""
$(TYPEDSIGNATURES)

Constructor from an optimal control problem for a NonFixed ocp.
"""
function OptimalControlSolution(
    ocp::OptimalControlModel{<:TimeDependence, NonFixed};
    state::Function,
    control::Function,
    objective::ctNumber,
    variable::Variable,
    costate::Union{Nothing, Function} = nothing,
    time_grid::Union{Nothing, TimesDisc} = nothing,
    iterations::Union{Nothing, Integer} = nothing,
    stopping::Union{Nothing, Symbol} = nothing,
    message::Union{Nothing, String} = nothing,
    success::Union{Nothing, Bool} = nothing,
    infos::Dict{Symbol, Any} = Dict{Symbol, Any}(),
    boundary_constraints::Union{Nothing, ctVector} = nothing,
    mult_boundary_constraints::Union{Nothing, ctVector} = nothing,
    variable_constraints::Union{Nothing, ctVector} = nothing,
    mult_variable_constraints::Union{Nothing, ctVector} = nothing,
    mult_variable_box_lower::Union{Nothing, ctVector} = nothing,
    mult_variable_box_upper::Union{Nothing, ctVector} = nothing,
    control_constraints::Union{Nothing, Function} = nothing,
    mult_control_constraints::Union{Nothing, Function} = nothing,
    state_constraints::Union{Nothing, Function} = nothing,
    mult_state_constraints::Union{Nothing, Function} = nothing,
    mixed_constraints::Union{Nothing, Function} = nothing,
    mult_mixed_constraints::Union{Nothing, Function} = nothing,
    mult_state_box_lower::Union{Nothing, Function} = nothing,
    mult_state_box_upper::Union{Nothing, Function} = nothing,
    mult_control_box_lower::Union{Nothing, Function} = nothing,
    mult_control_box_upper::Union{Nothing, Function} = nothing,
)::OptimalControlSolution
    return __OptimalControlSolution(
        ocp;
        state = state,
        control = control,
        objective = objective,
        costate = costate,
        time_grid = time_grid,
        variable = variable,
        iterations = iterations,
        stopping = stopping,
        message = message,
        success = success,
        infos = infos,
        boundary_constraints = boundary_constraints,
        mult_boundary_constraints = mult_boundary_constraints,
        variable_constraints = variable_constraints,
        mult_variable_constraints = mult_variable_constraints,
        mult_variable_box_lower = mult_variable_box_lower,
        mult_variable_box_upper = mult_variable_box_upper,
        control_constraints = control_constraints,
        mult_control_constraints = mult_control_constraints,
        state_constraints = state_constraints,
        mult_state_constraints = mult_state_constraints,
        mixed_constraints = mixed_constraints,
        mult_mixed_constraints = mult_mixed_constraints,
        mult_state_box_lower = mult_state_box_lower,
        mult_state_box_upper = mult_state_box_upper,
        mult_control_box_lower = mult_control_box_lower,
        mult_control_box_upper = mult_control_box_upper,
    )
end

# setters
#state!(sol::OptimalControlSolution, state::Function) = (sol.state = state; nothing)
#control!(sol::OptimalControlSolution, control::Function) = (sol.control = control; nothing)
#objective!(sol::OptimalControlSolution, objective::ctNumber) = (sol.objective = objective; nothing)
#variable!(sol::OptimalControlSolution, variable::Variable) = (sol.variable = variable; nothing)

"""
$(TYPEDSIGNATURES)

Set the time grid.

"""
time_grid!(sol::OptimalControlSolution, time_grid::TimesDisc) = (sol.time_grid = time_grid; nothing)

"""
$(TYPEDSIGNATURES)

Set the costate.

"""
costate!(sol::OptimalControlSolution, costate::Function) = (sol.costate = costate; nothing)

"""
$(TYPEDSIGNATURES)

Set the number of iterations.

"""
iterations!(sol::OptimalControlSolution, iterations::Int) = (sol.iterations = iterations; nothing)

"""
$(TYPEDSIGNATURES)

Set the stopping criterion.

"""
stopping!(sol::OptimalControlSolution, stopping::Symbol) = (sol.stopping = stopping; nothing)

"""
$(TYPEDSIGNATURES)

Set the message of stopping.

"""
message!(sol::OptimalControlSolution, message::String) = (sol.message = message; nothing)

"""
$(TYPEDSIGNATURES)

Set the success.

"""
success!(sol::OptimalControlSolution, success::Bool) = (sol.success = success; nothing)

"""
$(TYPEDSIGNATURES)

Set the additional infos.

"""
infos!(sol::OptimalControlSolution, infos::Dict{Symbol, Any}) = (sol.infos = infos; nothing)

"""
$(TYPEDSIGNATURES)

Set the boundary constraints.

"""
boundary_constraints!(sol::OptimalControlSolution, boundary_constraints::ctVector) =
    (sol.boundary_constraints = boundary_constraints; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the boundary constraints.

"""
mult_boundary_constraints!(sol::OptimalControlSolution, mult_boundary_constraints::ctVector) =
    (sol.mult_boundary_constraints = mult_boundary_constraints; nothing)

"""
$(TYPEDSIGNATURES)

Set the variable constraints.

"""
variable_constraints!(sol::OptimalControlSolution, variable_constraints::ctVector) =
    (sol.variable_constraints = variable_constraints; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the variable constraints.

"""
mult_variable_constraints!(sol::OptimalControlSolution, mult_variable_constraints::ctVector) =
    (sol.mult_variable_constraints = mult_variable_constraints; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the variable lower bounds.

"""
mult_variable_box_lower!(sol::OptimalControlSolution, mult_variable_box_lower::ctVector) =
    (sol.mult_variable_box_lower = mult_variable_box_lower; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the variable upper bounds.

"""
mult_variable_box_upper!(sol::OptimalControlSolution, mult_variable_box_upper::ctVector) =
    (sol.mult_variable_box_upper = mult_variable_box_upper; nothing)

"""
$(TYPEDSIGNATURES)

Set the control constraints.

"""
control_constraints!(sol::OptimalControlSolution, control_constraints::Function) =
    (sol.control_constraints = control_constraints; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the control constraints.

"""
mult_control_constraints!(sol::OptimalControlSolution, mult_control_constraints::Function) =
    (sol.mult_control_constraints = mult_control_constraints; nothing)

"""
$(TYPEDSIGNATURES)

Set the state constraints.

"""
state_constraints!(sol::OptimalControlSolution, state_constraints::Function) =
    (sol.state_constraints = state_constraints; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the state constraints.

"""
mult_state_constraints!(sol::OptimalControlSolution, mult_state_constraints::Function) =
    (sol.mult_state_constraints = mult_state_constraints; nothing)

"""
$(TYPEDSIGNATURES)

Set the mixed state/control constraints.

"""
mixed_constraints!(sol::OptimalControlSolution, mixed_constraints::Function) =
    (sol.mixed_constraints = mixed_constraints; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the mixed state/control constraints.

"""
mult_mixed_constraints!(sol::OptimalControlSolution, mult_mixed_constraints::Function) =
    (sol.mult_mixed_constraints = mult_mixed_constraints; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the state lower bounds.

"""
mult_state_box_lower!(sol::OptimalControlSolution, mult_state_box_lower::Function) =
    (sol.mult_state_box_lower = mult_state_box_lower; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the state upper bounds.

"""
mult_state_box_upper!(sol::OptimalControlSolution, mult_state_box_upper::Function) =
    (sol.mult_state_box_upper = mult_state_box_upper; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the control lower bounds.

"""
mult_control_box_lower!(sol::OptimalControlSolution, mult_control_box_lower::Function) =
    (sol.mult_control_box_lower = mult_control_box_lower; nothing)

"""
$(TYPEDSIGNATURES)

Set the multipliers to the control upper bounds.

"""
mult_control_box_upper!(sol::OptimalControlSolution, mult_control_box_upper::Function) =
    (sol.mult_control_box_upper = mult_control_box_upper; nothing)
