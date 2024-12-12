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
    iterations::Union{Nothing, Int} = nothing,
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
    iterations::Union{Nothing, Int} = nothing,
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
    iterations::Union{Nothing, Int} = nothing,
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
    
Build OCP functional solution from discrete solution (given as raw variables and multipliers plus some optional infos)
"""
function OptimalControlSolution(
    ocp::OptimalControlModel,
    T,
    X,
    U,
    v,
    P;
    objective = 0,
    iterations = 0,
    constraints_violation = 0,
    message = "No msg",
    stopping = nothing,
    success = nothing,
    constraints_types = (nothing, nothing, nothing, nothing, nothing),
    constraints_mult = (nothing, nothing, nothing, nothing, nothing),
    box_multipliers = (nothing, nothing, nothing, nothing, nothing, nothing),
)
    dim_x = state_dimension(ocp)
    dim_u = control_dimension(ocp)
    dim_v = variable_dimension(ocp)

    # check that time grid is strictly increasing
    # if not proceed with list of indexes as time grid
    if !issorted(T, lt = <=)
        println(
            "WARNING: time grid at solution is not strictly increasing, replacing with list of indices...",
        )
        println(T)
        dim_NLP_steps = length(T) - 1
        T = LinRange(0, dim_NLP_steps, dim_NLP_steps + 1)
    end

    # variables: remove additional state for lagrange cost
    x = ctinterpolate(T, matrix2vec(X[:, 1:dim_x], 1))
    p = ctinterpolate(T[1:(end - 1)], matrix2vec(P[:, 1:dim_x], 1))
    u = ctinterpolate(T, matrix2vec(U[:, 1:dim_u], 1))

    # force scalar output when dimension is 1
    fx = (dim_x == 1) ? deepcopy(t -> x(t)[1]) : deepcopy(t -> x(t))
    fu = (dim_u == 1) ? deepcopy(t -> u(t)[1]) : deepcopy(t -> u(t))
    fp = (dim_x == 1) ? deepcopy(t -> p(t)[1]) : deepcopy(t -> p(t))
    var = (dim_v == 1) ? v[1] : v

    # misc infos
    infos = Dict{Symbol, Any}()
    infos[:constraints_violation] = constraints_violation

    # nonlinear constraints and multipliers
    control_constraints = t -> ctinterpolate(T, matrix2vec(constraints_types[1], 1))(t)
    mult_control_constraints = t -> ctinterpolate(T, matrix2vec(constraints_mult[1], 1))(t)
    state_constraints = t -> ctinterpolate(T, matrix2vec(constraints_types[2], 1))(t)
    mult_state_constraints = t -> ctinterpolate(T, matrix2vec(constraints_mult[2], 1))(t)
    mixed_constraints = t -> ctinterpolate(T, matrix2vec(constraints_types[3], 1))(t)
    mult_mixed_constraints = t -> ctinterpolate(T, matrix2vec(constraints_mult[3], 1))(t)

    # boundary and variable constraints
    boundary_constraints = constraints_types[4]
    mult_boundary_constraints = constraints_mult[4]
    variable_constraints = constraints_types[5]
    mult_variable_constraints = constraints_mult[5]

    # box constraints multipliers
    mult_state_box_lower = t -> ctinterpolate(T, matrix2vec(box_multipliers[1][:, 1:dim_x], 1))(t)
    mult_state_box_upper = t -> ctinterpolate(T, matrix2vec(box_multipliers[2][:, 1:dim_x], 1))
    mult_control_box_lower = t -> ctinterpolate(T, matrix2vec(box_multipliers[3][:, 1:dim_u], 1))(t)
    mult_control_box_upper = t -> ctinterpolate(T, matrix2vec(box_multipliers[4][:, 1:dim_u], 1))
    mult_variable_box_lower, mult_variable_box_upper = box_multipliers[5], box_multipliers[6]

    # build and return solution
    if is_variable_dependent(ocp)
        return OptimalControlSolution(
            ocp;
            state = fx,
            control = fu,
            objective = objective,
            costate = fp,
            time_grid = T,
            variable = var,
            iterations = iterations,
            stopping = stopping,
            message = message,
            success = success,
            infos = infos,
            control_constraints = control_constraints,
            state_constraints = state_constraints,
            mixed_constraints = mixed_constraints,
            boundary_constraints = boundary_constraints,
            variable_constraints = variable_constraints,
            mult_control_constraints = mult_control_constraints,
            mult_state_constraints = mult_state_constraints,
            mult_mixed_constraints = mult_mixed_constraints,
            mult_boundary_constraints = mult_boundary_constraints,
            mult_variable_constraints = mult_variable_constraints,
            mult_state_box_lower = mult_state_box_lower,
            mult_state_box_upper = mult_state_box_upper,
            mult_control_box_lower = mult_control_box_lower,
            mult_control_box_upper = mult_control_box_upper,
            mult_variable_box_lower = mult_variable_box_lower,
            mult_variable_box_upper = mult_variable_box_upper,
        )
    else
        return OptimalControlSolution(
            ocp;
            state = fx,
            control = fu,
            objective = objective,
            costate = fp,
            time_grid = T,
            iterations = iterations,
            stopping = stopping,
            message = message,
            success = success,
            infos = infos,
            control_constraints = control_constraints,
            state_constraints = state_constraints,
            mixed_constraints = mixed_constraints,
            boundary_constraints = boundary_constraints,
            mult_control_constraints = mult_control_constraints,
            mult_state_constraints = mult_state_constraints,
            mult_mixed_constraints = mult_mixed_constraints,
            mult_boundary_constraints = mult_boundary_constraints,
            mult_state_box_lower = mult_state_box_lower,
            mult_state_box_upper = mult_state_box_upper,
            mult_control_box_lower = mult_control_box_lower,
            mult_control_box_upper = mult_control_box_upper,
        )
    end
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
