function __check_time_dependence(time_dependence::Symbol)
    time_dependence ∉ [:t_indep, :t_dep] && throw(IncorrectArgument("time_dependence must be either :t_indep or :t_dep"))
end

function __check_variable_dependence(variable_dependence::Symbol)
    variable_dependence ∉ [:v_indep, :v_dep] && throw(IncorrectArgument("variable_dependence must be either :v_indep or :v_dep"))
end

function __check_criterion(criterion::Symbol)
    criterion ∉ [:min, :max] && throw(IncorrectArgument("criterion must be either :min or :max"))
end

function __check_state_set(ocp::OptimalControlModel)
    __is_state_not_set(ocp) && throw(UnauthorizedCall("the state dimension has to be set before. Use state!."))
end

function __check_control_set(ocp::OptimalControlModel)
    __is_control_not_set(ocp) && throw(UnauthorizedCall("the control dimension has to be set before. Use control!."))
end

function __check___is_time_set(ocp::OptimalControlModel)
    __is_time_not_set(ocp) && throw(UnauthorizedCall("the time dimension has to be set before. Use time!."))
end

function __check_variable_set(ocp::OptimalControlModel{td, :v_dep}) where {td}
    __is_variable_not_set(ocp) && throw(UnauthorizedCall("the variable dimension has to be set before. Use variable!."))
end

function __check_variable_set(ocp::OptimalControlModel{td, :v_indep}) where {td}
    nothing
end

function __check_all_set(ocp::OptimalControlModel)
    __check_state_set(ocp)
    __check_control_set(ocp)
    __check___is_time_set(ocp)
    __check_variable_set(ocp)
end

macro __check(s::Symbol)
    s == :time_dependence && return esc(quote __check_time_dependence($s) end)
    s == :variable_dependence && return esc(quote __check_variable_dependence($s) end)
    s == :criterion && return esc(quote __check_criterion($s) end)
    s == :ocp && return esc(quote __check_all_set($s) end)
    error("s must be either :time_dependence, :variable_dependence or :criterion")
end