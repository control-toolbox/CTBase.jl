function __check_dependencies(dependencies::Tuple{Vararg{DataType}})
    size(filter(p->p<:VariableDependence,dependencies),1) > 1 && throw(IncorrectArgument("the number of arguments about variable dependence must be equal at most to 1"))
    size(filter(p->p<:TimeDependence,dependencies),1) > 1 && throw(IncorrectArgument("the number of arguments about time dependence must be equal at most to 1"))
    size(dependencies,1) > 2 && throw(IncorrectArgument("the number of arguments about dependencies must be equal at most to 2"))
    size(filter(p->!(p<:Union{TimeDependence,VariableDependence}),dependencies),1) > 0 && throw(IncorrectArgument("the wrong of arguments, possible arguments are : NonAutonomous, Autonomous, Fixed, NonFixed"))
end

function __check_state_set(ocp::OptimalControlModel)
    __is_state_not_set(ocp) && throw(UnauthorizedCall("the state dimension has to be set before. Use state!."))
end

function __check_control_set(ocp::OptimalControlModel)
    __is_control_not_set(ocp) && throw(UnauthorizedCall("the control dimension has to be set before. Use control!."))
end

function __check_is_time_set(ocp::OptimalControlModel)
    __is_time_not_set(ocp) && throw(UnauthorizedCall("the time dimension has to be set before. Use time!."))
end

function __check_variable_set(ocp::OptimalControlModel{<:TimeDependence, NonFixed})
    __is_variable_not_set(ocp) && throw(UnauthorizedCall("the variable dimension has to be set before. Use variable!."))
end

function __check_variable_set(ocp::OptimalControlModel{<:TimeDependence, Fixed})
    nothing
end

function __check_all_set(ocp::OptimalControlModel)
    __check_state_set(ocp)
    __check_control_set(ocp)
    __check_is_time_set(ocp)
    __check_variable_set(ocp)
end